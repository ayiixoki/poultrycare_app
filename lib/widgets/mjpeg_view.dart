import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum MjpegState { connecting, live, error }

class MjpegView extends StatefulWidget {
  const MjpegView({
    super.key,
    required this.urls,
    this.running = true,
    this.onStateChanged,
  });

  final List<String> urls;
  final bool running;
  final void Function(MjpegState state, String url)? onStateChanged;

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  static const _stallTimeout = Duration(seconds: 8);
  static const _retryDelay = Duration(seconds: 3);
  static const _maxBuffer = 2 * 1024 * 1024;

  HttpClient? _client;
  StreamSubscription<List<int>>? _sub;
  Timer? _watchdog;
  Timer? _retry;
  final List<int> _buf = <int>[];
  Uint8List? _frame;
  MjpegState _state = MjpegState.connecting;
  int _urlIndex = 0;
  bool _gotFrame = false;
  bool _disposed = false;
  DateTime _lastFrame = DateTime.now();

  String get _currentUrl =>
      widget.urls.isEmpty ? '' : widget.urls[_urlIndex % widget.urls.length];

  @override
  void initState() {
    super.initState();
    if (widget.running) _connect();
  }

  @override
  void didUpdateWidget(MjpegView old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.urls, widget.urls)) {
      _urlIndex = 0;
      widget.running ? _connect() : _teardown();
    } else if (old.running != widget.running) {
      widget.running ? _connect() : _teardown();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _teardown();
    super.dispose();
  }

  void _setState(MjpegState s) {
    if (_state == s || _disposed) return;
    _state = s;
    if (mounted) setState(() {});
    final url = _currentUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) widget.onStateChanged?.call(s, url);
    });
  }

  void _teardown() {
    _retry?.cancel();
    _retry = null;
    _watchdog?.cancel();
    _watchdog = null;
    _sub?.cancel();
    _sub = null;
    _client?.close(force: true);
    _client = null;
  }

  Future<void> _connect() async {
    _teardown();
    final url = _currentUrl;
    if (!widget.running || url.isEmpty) return;
    _gotFrame = false;
    _setState(MjpegState.connecting);

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    _client = client;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (_disposed || _client != client) return;
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      _buf.clear();
      _lastFrame = DateTime.now();
      _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
        if (DateTime.now().difference(_lastFrame) > _stallTimeout) _fail(client);
      });
      _sub = response.listen(
        _onData,
        onError: (_) => _fail(client),
        onDone: () => _fail(client),
        cancelOnError: true,
      );
    } catch (_) {
      _fail(client);
    }
  }

  void _fail(HttpClient client) {
    if (_disposed || _client != client) return;
    _teardown();
    if (!_gotFrame) _urlIndex++;
    _setState(MjpegState.error);
    _retry = Timer(_retryDelay, _connect);
  }

  void _onData(List<int> chunk) {
    if (!mounted) return;
    _buf.addAll(chunk);
    Uint8List? latest;
    while (true) {
      final start = _find(0xD8, 0);
      if (start < 0) {
        if (_buf.length > 1) _buf.removeRange(0, _buf.length - 1);
        break;
      }
      final end = _find(0xD9, start + 2);
      if (end < 0) {
        if (start > 0) _buf.removeRange(0, start);
        break;
      }
      latest = Uint8List.fromList(_buf.sublist(start, end + 2));
      _buf.removeRange(0, end + 2);
    }
    if (_buf.length > _maxBuffer) _buf.clear();

    final frame = latest;
    if (frame != null) {
      _lastFrame = DateTime.now();
      _gotFrame = true;
      setState(() => _frame = frame);
      _setState(MjpegState.live);
    }
  }

  int _find(int second, int from) {
    for (var i = from; i < _buf.length - 1; i++) {
      if (_buf[i] == 0xFF && _buf[i + 1] == second) return i;
    }
    return -1;
  }

  Widget _overlay(IconData icon, String text) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_frame != null)
          Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain),
        if (!widget.running)
          _overlay(Icons.pause_circle_outline, 'Paused')
        else if (_state == MjpegState.connecting)
          const Center(child: CircularProgressIndicator())
        else if (_state == MjpegState.error)
          _overlay(Icons.videocam_off, 'Camera unreachable.\nRetrying…'),
      ],
    );
  }
}
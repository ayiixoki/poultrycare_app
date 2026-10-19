import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/mjpeg_view.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://poultrycare-f816d-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  late final Stream<DatabaseEvent> _cameraStream = _db.ref('camera').onValue;

  bool _running = true;
  MjpegState _state = MjpegState.connecting;
  String _activeUrl = '';

  String _statusLabel() {
    if (!_running) return 'Paused';
    switch (_state) {
      case MjpegState.live:
        return 'Live';
      case MjpegState.connecting:
        return 'Connecting…';
      case MjpegState.error:
        return 'Camera offline';
    }
  }

  Color _statusColor() {
    if (!_running) return Colors.grey;
    switch (_state) {
      case MjpegState.live:
        return Colors.green;
      case MjpegState.connecting:
        return Colors.orange;
      case MjpegState.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Camera')),
      body: StreamBuilder<DatabaseEvent>(
        stream: _cameraStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data?.snapshot.value;
          final data = raw is Map
              ? Map<String, dynamic>.from(raw)
              : <String, dynamic>{};
          final lan = (data['lan_url'] ?? '').toString();
          final remote = (data['remote_url'] ?? '').toString();
          final urls = [
            if (lan.isNotEmpty) lan,
            if (remote.isNotEmpty) remote,
          ];

          if (urls.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The camera is not available yet.\n'
                  'Make sure the poultry system is turned on and connected to Wi-Fi.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final onRemote = _activeUrl.isNotEmpty && _activeUrl == remote;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: MjpegView(
                    urls: urls,
                    running: _running,
                    onStateChanged: (state, url) {
                      if (!mounted) return;
                      setState(() {
                        _state = state;
                        _activeUrl = url;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    avatar: Icon(Icons.circle, size: 12, color: _statusColor()),
                    label: Text(_statusLabel()),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => setState(() => _running = !_running),
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? 'Pause video' : 'Resume video'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_running && _state == MjpegState.live)
                Text(
                  onRemote
                      ? 'Connected through the internet'
                      : 'Connected through the farm Wi-Fi',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (_running && _state == MjpegState.error)
                Text(
                  'Cannot reach the camera. Make sure the poultry system is turned on.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Text(
                'The camera turns on only while this screen is open.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
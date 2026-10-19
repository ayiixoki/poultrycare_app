// ============================================================
// lib/screens/progress_report_screen.dart
// ============================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

typedef _Rec = MapEntry<String, Map<String, dynamic>>;

const Color _gold = Color(0xFFD4C84E);
const Color _green = Color(0xFF28A745);
const Color _red = Color(0xFFDC3545);
const Color _amber = Color(0xFFB26A00);

// The flock is weighed and measured every 5 days.
const int _intervalDays = 5;

class _Ck {
  final double size;
  final double weight;
  const _Ck(this.size, this.weight);
}

// ── Helpers ───────────────────────────────────────────────────
DateTime _date(Map<String, dynamic> m) =>
    DateTime.fromMillisecondsSinceEpoch((m['date'] as num?)?.toInt() ?? 0);

String _fmtDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);
String _short(DateTime d) => DateFormat('MMM d').format(d);
String _g(double v) => '${NumberFormat('#,##0').format(v.round())} g';
String _cm(double v) => '${v.toStringAsFixed(1)} cm';
String _sg(double v) =>
    '${v >= 0 ? '+' : '-'}${NumberFormat('#,##0').format(v.abs().round())} g';
String _scm(double v) =>
    '${v >= 0 ? '+' : '-'}${v.abs().toStringAsFixed(1)} cm';
String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

Map<String, _Ck> _chickens(Map<String, dynamic> m) {
  final out = <String, _Ck>{};
  final raw = m['chickens'];
  if (raw is Map) {
    raw.forEach((k, v) {
      if (v is Map) {
        out[k.toString()] = _Ck(
          (v['sizeCm'] as num?)?.toDouble() ?? 0,
          (v['weightG'] as num?)?.toDouble() ?? 0,
        );
      }
    });
  }
  return out;
}

double _avgW(Map<String, _Ck> c) => c.isEmpty
    ? 0
    : c.values.map((e) => e.weight).reduce((a, b) => a + b) / c.length;
double _avgS(Map<String, _Ck> c) => c.isEmpty
    ? 0
    : c.values.map((e) => e.size).reduce((a, b) => a + b) / c.length;

Color _tagColor(String tag) {
  switch (tag.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'orange':
      return Colors.orange;
    case 'yellow':
      return Colors.amber;
    case 'green':
      return Colors.green;
    case 'blue':
      return Colors.blue;
    case 'purple':
      return Colors.purple;
    case 'brown':
      return Colors.brown;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.grey.shade400;
    case 'pink':
      return Colors.pink;
    default:
      return Colors.grey;
  }
}

// ── Next measurement (every 5 days) ───────────────────────────
DateTime _nextDue(List<_Rec> r) =>
    _date(r.last.value).add(const Duration(days: _intervalDays));

int _daysUntilDue(List<_Rec> r) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = _nextDue(r);
  return DateTime(due.year, due.month, due.day).difference(today).inDays;
}

String _dueText(List<_Rec> r) {
  final d = _daysUntilDue(r);
  final when = _fmtDate(_nextDue(r));
  if (d > 1) return '$when (in $d days)';
  if (d == 1) return '$when (tomorrow)';
  if (d == 0) return '$when (today)';
  return '$when (overdue by ${-d} day${-d > 1 ? 's' : ''})';
}

Color _dueColor(List<_Rec> r) {
  final d = _daysUntilDue(r);
  if (d < 0) return _red;
  if (d == 0) return _amber;
  return Colors.black;
}

// ── Parser: pastes like "OCT 2 / with system / purple 27 654" ──
const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

Map<DateTime, Map<String, _Ck>> _parse(String text) {
  final result = <DateTime, Map<String, _Ck>>{};
  final dateRe =
      RegExp(r'^([A-Za-z]{3,9})\.?\s+(\d{1,2})(?:\s*,?\s*(\d{4}))?$');
  final rowRe = RegExp(r'^([A-Za-z]+)\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)$');

  DateTime? current;
  bool include = false;
  final now = DateTime.now();

  for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();

    // Section line: with system / w system / w/out system
    if (lower.contains('system')) {
      final without = lower.contains('w/out') ||
          lower.contains('without') ||
          lower.contains('w/o') ||
          lower.contains('no system');
      include = !without;
      continue;
    }

    // Date line
    final dm = dateRe.firstMatch(line);
    if (dm != null) {
      final mon = _months[dm.group(1)!.toLowerCase().substring(0, 3)];
      if (mon != null) {
        final day = int.parse(dm.group(2)!);
        var year = dm.group(3) != null ? int.parse(dm.group(3)!) : now.year;
        var d = DateTime(year, mon, day);
        if (dm.group(3) == null &&
            d.isAfter(now.add(const Duration(days: 1)))) {
          d = DateTime(year - 1, mon, day);
        }
        current = d;
        include = false; // wait for a "with system" line
        continue;
      }
    }

    // Chicken row
    final rm = rowRe.firstMatch(line);
    if (rm != null && include && current != null) {
      final tag = rm.group(1)!.toLowerCase();
      final size = double.parse(rm.group(2)!);
      final weight = double.parse(rm.group(3)!);
      result.putIfAbsent(current, () => <String, _Ck>{})[tag] =
          _Ck(size, weight);
    }
  }
  return result;
}

// ── Remarks + copy text ───────────────────────────────────────
class _Gain {
  final String tag;
  final double gain;
  final double perDay;
  _Gain(this.tag, this.gain, this.perDay);
  double get per5 => perDay * _intervalDays;
}

List<_Gain> _gains(List<_Rec> r) {
  if (r.length < 2) return [];
  final first = _chickens(r.first.value);
  final last = _chickens(r.last.value);
  final days = _date(r.last.value).difference(_date(r.first.value)).inDays;
  final out = <_Gain>[];
  last.forEach((tag, ck) {
    final f = first[tag];
    if (f != null) {
      final g = ck.weight - f.weight;
      out.add(_Gain(tag, g, days > 0 ? g / days : 0));
    }
  });
  out.sort((a, b) => b.gain.compareTo(a.gain));
  return out;
}

List<String> _remarks(List<_Rec> r) {
  if (r.length < 2) {
    return [
      'Only one measurement date is recorded. Measure again in $_intervalDays days (${_dueText(r)}) to see how fast the chickens are growing.'
    ];
  }
  final out = <String>[];
  final f = _chickens(r.first.value);
  final l = _chickens(r.last.value);
  final days = _date(r.last.value).difference(_date(r.first.value)).inDays;
  final wg = _avgW(l) - _avgW(f);
  final perDay = days > 0 ? wg / days : 0.0;

  out.add(
      'On average, each chicken gained ${_g(wg)} in $days day(s). That is about ${_g(perDay * _intervalDays)} every $_intervalDays days (${perDay.toStringAsFixed(1)} g per day).');
  out.add(
      'The average size grew by ${_cm(_avgS(l) - _avgS(f))}, from ${_cm(_avgS(f))} to ${_cm(_avgS(l))}.');

  final gains = _gains(r);
  if (gains.length >= 2) {
    final best = gains.first;
    final worst = gains.last;
    out.add(
        'Best grower: ${_cap(best.tag)} tag (${_sg(best.gain)}). Slowest grower: ${_cap(worst.tag)} tag (${_sg(worst.gain)}).');
  }

  // Any chicken that lost weight between two measurements
  final drops = <String>[];
  for (int i = 1; i < r.length; i++) {
    final a = _chickens(r[i - 1].value);
    final b = _chickens(r[i].value);
    b.forEach((tag, ck) {
      final p = a[tag];
      if (p != null && ck.weight < p.weight) {
        drops.add('${_cap(tag)} (${_short(_date(r[i].value))})');
      }
    });
  }
  if (drops.isNotEmpty) {
    out.add(
        'Weight went down for: ${drops.join(', ')}. Please check these chickens for feed, water and health.');
  } else {
    out.add('No chicken lost weight between measurements.');
  }

  // Gaps that are not 5 days
  final odd = <String>[];
  for (int i = 1; i < r.length; i++) {
    final gap =
        _date(r[i].value).difference(_date(r[i - 1].value)).inDays;
    if (gap != _intervalDays) {
      odd.add(
          '${_short(_date(r[i - 1].value))} to ${_short(_date(r[i].value))} ($gap days)');
    }
  }
  if (odd.isNotEmpty) {
    out.add(
        'Measurements are planned every $_intervalDays days, but these were different: ${odd.join(', ')}. Gain numbers for those periods are not the same length.');
  }

  out.add('Next measurement: ${_dueText(r)}.');
  return out;
}

String _reportText(List<_Rec> r, String preparedFor) {
  final b = StringBuffer();
  final l = _chickens(r.last.value);
  b.writeln('FLOCK GROWTH PROGRESS REPORT');
  b.writeln('PoultryCare - Chickens raised with the system');
  b.writeln('Prepared for: $preparedFor');
  b.writeln('Report date: ${_fmtDate(DateTime.now())}');
  b.writeln(
      'Reporting period: ${_fmtDate(_date(r.first.value))} to ${_fmtDate(_date(r.last.value))}');
  b.writeln('Measured every: $_intervalDays days');
  b.writeln('Next measurement: ${_dueText(r)}');
  b.writeln('Chickens tracked: ${l.length}');
  b.writeln();
  b.writeln('1. FLOCK AVERAGE PER DATE');
  for (final e in r) {
    final c = _chickens(e.value);
    b.writeln(
        '${_fmtDate(_date(e.value))}: avg size ${_cm(_avgS(c))}, avg weight ${_g(_avgW(c))}');
  }
  b.writeln();
  b.writeln('2. INDIVIDUAL CHICKENS (weight in grams)');
  final tags = l.keys.toList()..sort();
  for (final t in tags) {
    final row = r.map((e) {
      final ck = _chickens(e.value)[t];
      return ck == null ? '--' : ck.weight.round().toString();
    }).join(' -> ');
    b.writeln('${_cap(t)}: $row');
  }
  b.writeln();
  b.writeln('3. REMARKS');
  for (final line in _remarks(r)) {
    b.writeln('- $line');
  }
  return b.toString();
}

// ── Screen ────────────────────────────────────────────────────
class ProgressReportScreen extends StatelessWidget {
  const ProgressReportScreen({super.key});

  String get _preparedFor {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    final email = user?.email ?? 'Farmer';
    return email.split('@').first;
  }

  Future<void> _import(BuildContext context, List<_Rec> existing) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteDialog(),
    );
    if (text == null || text.trim().isEmpty) return;

    final parsed = _parse(text);
    if (parsed.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No "with system" data found. Check the date lines (like OCT 2) and the rows (like purple 27 654).')),
        );
      }
      return;
    }

    try {
      final svc = FirebaseService();
      for (final entry in parsed.entries) {
        final ms = DateTime(entry.key.year, entry.key.month, entry.key.day)
            .millisecondsSinceEpoch;
        // replace a record with the same date
        for (final e in existing) {
          if ((e.value['date'] as num?)?.toInt() == ms) {
            await svc.deleteGrowthRecord(e.key);
          }
        }
        await svc.addGrowthRecord({
          'date': ms,
          'chickens': {
            for (final c in entry.value.entries)
              c.key: {'sizeCm': c.value.size, 'weightG': c.value.weight},
          },
        });
      }
      if (context.mounted) {
        final n = parsed.values.fold<int>(0, (s, m) => s + m.length);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Report updated: ${parsed.length} date(s), $n chicken readings.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the data.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_Rec>>(
      stream: FirebaseService().growthRecordsStream(),
      builder: (context, snap) {
        // only records in the new format (with per-chicken data)
        final recs = (snap.data ?? <_Rec>[])
            .where((e) => _chickens(e.value).isNotEmpty)
            .toList();
        final loading =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;

        return Container(
          color: const Color(0xFFF5F5F5),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Progress Report',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        const SizedBox(height: 4),
                        Text('Measured every $_intervalDays days',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _import(context, recs),
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste data'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: _gold)),
                )
              else if (recs.isEmpty)
                _EmptyState(onAdd: () => _import(context, recs))
              else
                _ReportCard(recs: recs, preparedFor: _preparedFor),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.show_chart_rounded, size: 48, color: _gold),
          const SizedBox(height: 12),
          const Text('No data yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Tap "Paste data" and paste your measurements. The report is made for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
                backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('Paste data'),
          ),
        ],
      ),
    );
  }
}

// ── The formal report ─────────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final List<_Rec> recs;
  final String preparedFor;
  const _ReportCard({required this.recs, required this.preparedFor});

  Future<void> _delete(BuildContext context, _Rec rec) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_fmtDate(_date(rec.value))}?'),
        content:
            const Text('All chicken readings for this date will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await FirebaseService().deleteGrowthRecord(rec.key);
  }

  @override
  Widget build(BuildContext context) {
    final first = _chickens(recs.first.value);
    final last = _chickens(recs.last.value);
    final hasTrend = recs.length > 1;
    final days =
        _date(recs.last.value).difference(_date(recs.first.value)).inDays;
    final wGain = _avgW(last) - _avgW(first);
    final sGain = _avgS(last) - _avgS(first);
    final perDay = days > 0 ? wGain / days : null;
    final tags = last.keys.toList()..sort();
    final gains = _gains(recs);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FLOCK GROWTH PROGRESS REPORT',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
                SizedBox(height: 4),
                Text('PoultryCare · Chickens raised with the system',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Prepared for', preparedFor),
                _infoRow('Report date', _fmtDate(DateTime.now())),
                _infoRow('Reporting period',
                    '${_fmtDate(_date(recs.first.value))} - ${_fmtDate(_date(recs.last.value))}'),
                _infoRow('Measured every', '$_intervalDays days'),
                _infoRow('Measurement dates', '${recs.length}'),
                _infoRow('Chickens tracked', '${last.length}'),
                const Divider(height: 28),

                // Next measurement
                _tile('Next measurement due', _dueText(recs),
                    color: _dueColor(recs), small: true),
                const SizedBox(height: 22),

                // 1. Summary
                _section('1. Summary'),
                Row(
                  children: [
                    Expanded(
                        child: _tile('Latest average weight', _g(_avgW(last)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _tile('Latest average size', _cm(_avgS(last)))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _tile('Avg weight gained',
                            hasTrend ? _sg(wGain) : '--',
                            color: hasTrend
                                ? (wGain >= 0 ? _green : _red)
                                : null)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _tile('Avg size growth',
                            hasTrend ? _scm(sGain) : '--',
                            color: hasTrend
                                ? (sGain >= 0 ? _green : _red)
                                : null)),
                  ],
                ),
                if (perDay != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _tile('Gain per $_intervalDays days',
                              _sg(perDay * _intervalDays))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _tile('Gain per day',
                              '${perDay.toStringAsFixed(1)} g')),
                    ],
                  ),
                ],
                const SizedBox(height: 22),

                // 2. Flock average per date
                _section('2. Flock Average Per Date'),
                _avgHeader(),
                for (int i = 0; i < recs.length; i++)
                  _avgRow(context, recs[i], i == 0 ? null : recs[i - 1]),
                const SizedBox(height: 22),

                // 3. Individual chickens
                _section('3. Individual Chickens (weight in grams)'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 36,
                    columnSpacing: 18,
                    horizontalMargin: 8,
                    headingTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54),
                    dataTextStyle:
                        const TextStyle(fontSize: 12, color: Colors.black87),
                    columns: [
                      const DataColumn(label: Text('Tag')),
                      for (final r in recs)
                        DataColumn(
                            label: Text(_short(_date(r.value))), numeric: true),
                      const DataColumn(label: Text('Gain'), numeric: true),
                        const DataColumn(
                          label: Text('Per $_intervalDays d'), numeric: true),
                    ],
                    rows: [
                      for (final t in tags)
                        DataRow(cells: [
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: _tagColor(t),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(_cap(t)),
                            ],
                          )),
                          for (final r in recs)
                            DataCell(Text(_chickens(r.value)[t] == null
                                ? '--'
                                : _chickens(r.value)[t]!
                                    .weight
                                    .round()
                                    .toString())),
                          DataCell(_gainCell(gains, t, true)),
                          DataCell(_gainCell(gains, t, false)),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Remarks
                _section('4. Remarks'),
                for (final line in _remarks(recs))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(line,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: _reportText(recs, preparedFor)));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Report copied. You can paste it in a message or document.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy report'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gainCell(List<_Gain> gains, String tag, bool total) {
    final g = gains.where((e) => e.tag == tag).toList();
    if (g.isEmpty) return const Text('--');
    final v = total ? g.first.gain : g.first.per5;
    final txt = '${v >= 0 ? '+' : '-'}${v.abs().round()}';
    return Text(txt,
        style: TextStyle(
            fontWeight: FontWeight.w700, color: v >= 0 ? _green : _red));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
    );
  }

  Widget _tile(String label, String value, {Color? color, bool small = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: small ? 14 : 18,
                  fontWeight: FontWeight.w800,
                  color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _avgHeader() {
    const style = TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EFE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 28, child: Text('Date', style: style)),
          Expanded(flex: 26, child: Text('Avg weight', style: style)),
          Expanded(flex: 22, child: Text('Avg size', style: style)),
          Expanded(flex: 24, child: Text('Change', style: style)),
          SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _avgRow(BuildContext context, _Rec rec, _Rec? prev) {
    final c = _chickens(rec.value);
    final change =
        prev == null ? null : _avgW(c) - _avgW(_chickens(prev.value));
    const cell = TextStyle(fontSize: 12);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 28,
              child: Text(DateFormat('MMM d, yy').format(_date(rec.value)),
                  style: cell)),
          Expanded(flex: 26, child: Text(_g(_avgW(c)), style: cell)),
          Expanded(flex: 22, child: Text(_cm(_avgS(c)), style: cell)),
          Expanded(
            flex: 24,
            child: Text(
              change == null ? '--' : _sg(change),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: change == null
                    ? Colors.grey
                    : (change >= 0 ? _green : _red),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade500),
              onPressed: () => _delete(context, rec),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paste dialog ──────────────────────────────────────────────
class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) setState(() => _c.text = d!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _parse(_c.text);
    final readings = preview.values.fold<int>(0, (s, m) => s + m.length);

    return AlertDialog(
      title: const Text('Paste your data'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste all dates at once. Only the "with system" rows are used. "w/out system" rows are skipped.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Paste from clipboard'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _c,
                maxLines: 10,
                minLines: 6,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'OCT 2\nwith system\npurple 27 654\n...',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _c.text.trim().isEmpty
                    ? ''
                    : preview.isEmpty
                        ? 'Nothing readable yet.'
                        : 'Found ${preview.length} date(s), $readings chicken readings.',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: preview.isEmpty ? _red : _green),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed:
              preview.isEmpty ? null : () => Navigator.pop(context, _c.text),
          child: const Text('Make report'),
        ),
      ],
    );
  }
}
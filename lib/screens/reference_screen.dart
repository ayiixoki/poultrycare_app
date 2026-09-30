// ============================================================
// lib/screens/reference_screen.dart
//
// Simple, read-only reference guide (Temperature/Humidity + Feed).
// Opened from Settings via a single tap — no image assets required,
// values are rendered natively so they stay crisp on every screen size.
// ============================================================
import 'package:flutter/material.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  static const Color _bg = Color(0xFFEAE7DF);
  static const Color _card = Color(0xFFF7F5F0);
  static const Color _headerGreen = Color(0xFF2F5233);
  static const Color _subtitleGray = Color(0xFF8A8A8A);
  static const Color _altRow = Color(0xFFEDF3EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Reference Guide',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: const [
            Text(
              'Quick lookup values used for PoultryCare\'s climate alerts and feeding schedule.',
              style: TextStyle(fontSize: 13, color: _subtitleGray),
            ),
            SizedBox(height: 20),
            _ReferenceCard(
              icon: Icons.thermostat_rounded,
              iconBg: Color(0xFFD8EAFB),
              iconColor: Color(0xFF3B8FE0),
              title: 'Temperature & Humidity',
              subtitle: 'Optimal ranges by week of age',
              columns: ['Age', 'Temp (°C)', 'Humidity (%)'],
              rows: [
                ['Week 1', '32 – 34', '60 – 70'],
                ['Week 2', '29 – 31', '60 – 70'],
                ['Week 3', '26 – 28', '50 – 60'],
                ['Week 4', '23 – 25', '50 – 60'],
                ['Week 5', '20 – 22', '50 – 60'],
                ['Week 6', '18 – 21', '50 – 60'],
                ['Week 7+', '18 – 20', '50 – 60'],
              ],
            ),
            SizedBox(height: 16),
            _ReferenceCard(
              icon: Icons.grain_rounded,
              iconBg: Color(0xFFFBE7CE),
              iconColor: Color(0xFFD68A2A),
              title: 'Feed Reference',
              subtitle: 'Grams per chicken · reference range',
              columns: ['Age', 'g / chicken / day', 'g / week'],
              rows: [
                ['Week 1', '20 – 24', '142 – 171'],
                ['Week 2', '51 – 66', '358 – 464'],
                ['Week 3', '84 – 115', '588 – 802'],
                ['Week 4', '108 – 144', '753 – 1,007'],
                ['Week 5', '153 – 178', '1,072 – 1,247'],
                ['Week 6', '162 – 213', '1,132 – 1,492'],
              ],
              howToTitle: 'How to compute feed per feeding',
              howTo: [
                '1. Number of chickens × g / chicken / day = grams per day',
                '2. Grams per day ÷ number of feedings = grams per feeding',
                '3. Enter the grams per feeding in Settings → Grams of Feeds',
                'Example: 10 chickens × 84 g = 840 g per day ÷ 2 feedings = 420 g per feeding',
              ],
              footnote:
                  'Reference range only. Actual feed intake can be higher or lower depending on the breed, sex, age, weather, and health of the chickens.\nSources: Aviagen (2022); Kyei et al. (2026).',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<String> columns;
  final List<List<String>> rows;
  final String? footnote;
  final String? howToTitle;
  final List<String>? howTo;

  const _ReferenceCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    this.footnote,
    this.howToTitle,
    this.howTo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReferenceScreen._card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 13,
                          color: ReferenceScreen._subtitleGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  color: ReferenceScreen._headerGreen,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: columns
                        .map(
                          (c) => Expanded(
                            child: Text(
                              c,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                for (int i = 0; i < rows.length; i++)
                  Container(
                    color:
                        i.isEven ? Colors.white : ReferenceScreen._altRow,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: rows[i]
                          .map(
                            (v) => Expanded(
                              child: Text(
                                v,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          if (howTo != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ReferenceScreen._altRow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    howToTitle ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  for (final line in howTo!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 10),
            Text(
              footnote!,
              style: const TextStyle(
                fontSize: 11,
                color: ReferenceScreen._subtitleGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
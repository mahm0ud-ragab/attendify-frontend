// Attendance Statistics Screen – Royal Purple Theme (Lecturer Side)
// Pixel-matched to lecturer_dashboard.dart & qr_generator_screen.dart.
//
// Layout:
//   [Header: back arrow + title]
//   [2×2 summary grid: Enrolled | Sessions | Avg Rate | Best Session]
//   [Bar chart: attendance per session (last 8)]
//   [Expandable session list: tap → student names + scan times]
//   [FAB: "Export CSV" → slides up bottom sheet with 3 export modes]

import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';

class AttendanceStatsScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const AttendanceStatsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AttendanceStatsScreen> createState() => _AttendanceStatsScreenState();
}

class _AttendanceStatsScreenState extends State<AttendanceStatsScreen> {
  final _api = ApiService();

  // ── state ──
  Map<String, dynamic>? _stats;   // full JSON from /stats endpoint
  bool   _isLoading    = true;
  String? _error;
  final Set<int> _expanded = {};  // session IDs currently expanded

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    final r = await _api.getAttendanceStats(courseId: widget.courseId);
    if (!mounted) return;
    if (r['success']) {
      setState(() { _stats = r['stats']; _isLoading = false; });
    } else {
      setState(() { _error = r['message']; _isLoading = false; });
    }
  }

  // ─── tiny helpers ─────────────────────────────────────────────────────────
  static const _months = ['','Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  static String _mon(int m) => _months[m];
  static String _pad(int v)  => v.toString().padLeft(2,'0');

  // ─── accessors ────────────────────────────────────────────────────────────
  int    get _enrolled  => _stats?['total_enrolled']  ?? 0;
  int    get _sessions  => _stats?['total_sessions']  ?? 0;
  double get _rate      => _stats?['overall_rate']    ?? 0.0;
  List   get _sessData  => _stats?['sessions'] as List? ?? [];

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── gradient bg ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.deepPurple.shade800,
                  Colors.purple.shade700,
                ],
              ),
            ),
          ),
          // ── decorative circles (identical painter used everywhere) ──
          Positioned.fill(child: CustomPaint(painter: _CirclePainter())),

          // ── content ──
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: _isLoading ? _loader()
                      : _error   != null ? _errorView()
                      : _body(),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB → opens export bottom sheet ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExportSheet(),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.file_download_rounded),
        label: const Text('Export Excel',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        elevation: 6,
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // back button – same glass-pill style as dashboard settings btn
          Container(
            decoration: BoxDecoration(
              color:  Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Text('Attendance Stats',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),

          const SizedBox(width: 48), // visual balance
        ],
      ),
    );
  }

  // ─── STATES ───────────────────────────────────────────────────────────────
  Widget _loader() => const Center(
      child: CircularProgressIndicator(color: Colors.white));

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _card(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 52, color: Colors.red.shade400),
          const SizedBox(height: 14),
          Text(_error!, style: const TextStyle(color: Color(0xFF757575), fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _fetch,
            style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple.shade700),
            child: const Text('Retry'),
          ),
        ],
      )),
    ),
  );

  // ─── MAIN BODY ────────────────────────────────────────────────────────────
  Widget _body() => RefreshIndicator(
    onRefresh: _fetch,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _summaryGrid(),
          const SizedBox(height: 20),
          if (_sessData.isNotEmpty) _chartCard(),
          if (_sessData.isNotEmpty) const SizedBox(height: 20),
          _sessionListHeader(),
          const SizedBox(height: 12),
          _sessionList(),
          const SizedBox(height: 100), // clear FAB
        ],
      ),
    ),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // 2×2 SUMMARY GRID - FULLY RESPONSIVE
  // ════════════════════════════════════════════════════════════════════════════
  Widget _summaryGrid() {
    final best = _stats?['best_session'] as Map<String, dynamic>?;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal card dimensions based on available width
        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth - 12) / 2; // 12 = gap between cards
        final cardHeight = cardWidth * 0.85; // Maintain good proportions

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: cardWidth / cardHeight,
          children: [
            _statTile(Icons.people_rounded,
                Colors.deepPurple.shade600, Colors.deepPurple.shade50,
                'Enrolled', '$_enrolled', 'students'),

            _statTile(Icons.event_repeat_rounded,
                Colors.teal.shade600,      Colors.teal.shade50,
                'Sessions', '$_sessions', 'held'),

            _statTile(Icons.bar_chart_rounded,
                Colors.orange.shade600,    Colors.orange.shade50,
                'Avg Rate', '${_rate}%',   'overall'),

            _statTile(Icons.star_rounded,
                Colors.pink.shade600,      Colors.pink.shade50,
                'Best',
                best != null ? '${best["attended_count"]} / $_enrolled' : '–',
                'session'),
          ],
        );
      },
    );
  }

  Widget _statTile(IconData icon, Color ic, Color ib,
      String title, String value, String sub) {
    return _card(
      padding: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive sizes based on card width
          final cardWidth = constraints.maxWidth;
          final iconSize = (cardWidth * 0.25).clamp(32.0, 40.0);
          final valueSize = (cardWidth * 0.18).clamp(18.0, 23.0);
          final titleSize = (cardWidth * 0.095).clamp(10.0, 12.0);
          final subSize = (cardWidth * 0.08).clamp(9.0, 10.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // icon badge
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(color: ib, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: ic, size: iconSize * 0.5),
              ),
              const Spacer(),
              // value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1248),
                    letterSpacing: -0.5)),
              ),
              SizedBox(height: cardWidth * 0.015),
              // title
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF757575))),
              // sub
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: subSize,
                      color: const Color(0xFF9E9E9E))),
            ],
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BAR CHART - FULLY RESPONSIVE
  // ════════════════════════════════════════════════════════════════════════════
  Widget _chartCard() {
    // show latest 8 sessions, left → right = oldest → newest
    final display = _sessData.reversed.take(8).toList().reversed.toList();

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header + legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text('Attendance per Session',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1248), letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            Row(children: [
              _legend(Colors.deepPurple.shade500, 'Present'),
              const SizedBox(width: 14),
              _legend(Colors.grey.shade300, 'Enrolled'),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        // the chart itself - fully responsive
        SizedBox(height: 150,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: _BarChartPainter(
                  sessions: display,
                  enrolled: _enrolled,
                  availableWidth: constraints.maxWidth,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ],
    ));
  }

  Widget _legend(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF616161))),
    ],
  );

  // ════════════════════════════════════════════════════════════════════════════
  // SESSION LIST
  // ════════════════════════════════════════════════════════════════════════════
  Widget _sessionListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Session Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1248), letterSpacing: -0.3)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(12)),
          child: Text('${_sessData.length} sessions',
              style: TextStyle(color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _sessionList() {
    if (_sessData.isEmpty) return _card(child: Column(
      children: [
        Icon(Icons.event_busy_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        const Text('No sessions held yet',
            style: TextStyle(fontSize: 16, color: Color(0xFF757575))),
        const SizedBox(height: 4),
        const Text('Start a session from the course details page',
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      ],
    ));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sessData.length,
      itemBuilder: (_, i) => _sessionCard(_sessData[i] as Map<String, dynamic>),
    );
  }

  Widget _sessionCard(Map<String, dynamic> s) {
    final int   sid      = s['session_id'];
    final bool  active   = s['is_active']       ?? false;
    final int   attended = s['attended_count']  ?? 0;
    final double rate    = s['rate']            ?? 0.0;
    final List  students = s['students']        ?? [];
    final bool  expanded = _expanded.contains(sid);

    // ── date display ──
    String dateDisp = '–';
    if (s['date'] != null) {
      try {
        final dt = DateTime.parse(s['date']);
        dateDisp = '${_mon(dt.month)} ${dt.day}, ${dt.year}  •  ${_pad(dt.hour)}:${_pad(dt.minute)}';
      } catch (_) {}
    }

    // ── rate colour band ──
    final Color rc = rate >= 70 ? Colors.green.shade600
        : rate >= 40 ? Colors.orange.shade600
        : Colors.red.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? Colors.green.shade300 : Colors.white.withValues(alpha: 0.5),
            width: active ? 1.5 : 1),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0,2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() { expanded ? _expanded.remove(sid) : _expanded.add(sid); }),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── top row: icon  date  [live badge]  chevron ──
                Row(children: [
                  Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.class_rounded,
                          color: Colors.deepPurple.shade700, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateDisp,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1248)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Session #$sid',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  if (active) _liveBadge(),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF9E9E9E)),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── progress bar ──
                ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: _enrolled > 0 ? attended / _enrolled : 0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(rc),
                        minHeight: 8)),
                const SizedBox(height: 8),

                // ── counts row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('$attended / $_enrolled attended',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF757575), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text('${rate}%',
                        style: TextStyle(fontSize: 14, color: rc, fontWeight: FontWeight.bold)),
                  ],
                ),

                // ── expandable student list ──
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Students Present',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF311B92))),
                      Text('${students.length}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (students.isEmpty)
                    const Text('No students marked attendance',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _studentRow(students[i] as Map<String, dynamic>),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _liveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      const Text('Live', style: TextStyle(
          color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 11)),
    ]),
  );

  Widget _studentRow(Map<String, dynamic> st) {
    String time = '–';
    if (st['scan_time'] != null) {
      try { final dt = DateTime.parse(st['scan_time']); time = '${_pad(dt.hour)}:${_pad(dt.minute)}'; }
      catch (_) {}
    }
    final String name  = st['name']  ?? 'Unknown';
    final String email = st['email'] ?? '';

    return Row(
      children: [
        CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepPurple.shade100,
            child: Text(name[0].toUpperCase(),
                style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(email,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // scan-time pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: Text(time, style: TextStyle(
              fontSize: 11, color: Colors.deepPurple.shade700, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXPORT BOTTOM SHEET
  // ════════════════════════════════════════════════════════════════════════════
  void _openExportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportSheet(
        courseId:    widget.courseId,
        courseTitle: widget.courseTitle,
        sessions:   _sessData,
        api:        _api,
      ),
    );
  }

  // ─── shared glass-card wrapper ────────────────────────────────────────────
  static Widget _card({required Widget child, double padding = 20}) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0,4))],
        ),
        child: child,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORT BOTTOM-SHEET  (private stateful widget – lives inside this file)
// Three modes:  All History  |  Single Session  |  Date Range
// ─────────────────────────────────────────────────────────────────────────────
enum _Mode { all, session, dateRange }

class _ExportSheet extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final List<dynamic> sessions;
  final ApiService api;

  const _ExportSheet({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.sessions,
    required this.api,
  });

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  _Mode _mode = _Mode.all;

  // single-session
  int? _pickedSession;

  // date range
  DateTime? _startDate;
  DateTime? _endDate;

  // async
  bool    _exporting = false;
  String? _err;
  bool    _ok        = false;

  // ── row-count preview (client-side, instant) ──
  int get _previewRows {
    switch (_mode) {
      case _Mode.all:
        return widget.sessions.fold<int>(0, (sum, s) => sum + ((s as Map)['attended_count'] as int? ?? 0));
      case _Mode.session:
        if (_pickedSession == null) return 0;
        final m = widget.sessions.firstWhere(
                (s) => (s as Map)['session_id'] == _pickedSession, orElse: () => null);
        return m != null ? (m as Map)['attended_count'] as int? ?? 0 : 0;
      case _Mode.dateRange:
        int c = 0;
        for (final s in widget.sessions) {
          final sess = s as Map<String, dynamic>;
          if (sess['date'] == null) continue;
          try {
            final dt = DateTime.parse(sess['date']);
            if (_startDate != null && dt.isBefore(_startDate!))         continue;
            if (_endDate   != null && dt.isAfter(_endDate!.add(const Duration(days:1)))) continue;
            c += (sess['attended_count'] as int? ?? 0);
          } catch (_) {}
        }
        return c;
    }
  }

  bool get _valid {
    switch (_mode) {
      case _Mode.all:       return true;
      case _Mode.session:   return _pickedSession != null;
      case _Mode.dateRange: return _startDate != null && _endDate != null && !_endDate!.isBefore(_startDate!);
    }
  }

  String? get _hint {
    switch (_mode) {
      case _Mode.all:       return null;
      case _Mode.session:   return _pickedSession == null ? 'Please select a session' : null;
      case _Mode.dateRange:
        if (_startDate == null || _endDate == null) return 'Set both start and end dates';
        if (_endDate!.isBefore(_startDate!))        return 'End date must be after start date';
        return null;
    }
  }

  // ── export ──
  Future<void> _export() async {
    setState(() { _exporting = true; _err = null; _ok = false; });

    final r = await widget.api.exportAttendanceCsv(
      courseId:   widget.courseId,
      sessionId: _mode == _Mode.session    ? _pickedSession : null,
      startDate: _mode == _Mode.dateRange  ? _startDate     : null,
      endDate:   _mode == _Mode.dateRange  ? _endDate       : null,
    );
    if (!mounted) return;

    if (r['success']) {
      // Parse CSV and convert to Excel
      final csvString = r['csv'] as String;
      final success = await _saveAsExcel(csvString);

      if (success) {
        setState(() { _exporting = false; _ok = true; });
      } else {
        setState(() { _exporting = false; _err = 'Failed to save Excel file'; });
      }
    } else {
      setState(() { _exporting = false; _err = r['message']; });
    }
  }

  Future<bool> _saveAsExcel(String csvData) async {
    try {
      // Parse CSV manually (simple parser for our controlled CSV format)
      final lines = csvData.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return false;

      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Attendance'];

      // Add header row (first line of CSV)
      final headerCols = _parseCsvLine(lines[0]);
      for (int i = 0; i < headerCols.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headerCols[i]);
        cell.cellStyle = CellStyle(
          fontFamily: getFontFamily(FontFamily.Calibri),
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
        );
      }

      // Add data rows
      for (int rowIdx = 1; rowIdx < lines.length; rowIdx++) {
        final cols = _parseCsvLine(lines[rowIdx]);
        for (int colIdx = 0; colIdx < cols.length; colIdx++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx));
          cell.value = TextCellValue(cols[colIdx]);
        }
      }

      // Note: setColWidth is not available in excel 4.0.6
      // Column widths will be auto-sized by Excel when opened

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'Attendance_${widget.courseTitle.replaceAll(' ', '_')}_$timestamp.xlsx';

      // Save file
      final bytes = excel.encode();
      if (bytes == null) return false;

      // Get directory and save
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Attendance Export - ${widget.courseTitle}',
        text: 'Attendance records exported from Attendify',
      );

      return true;
    } catch (e) {
      print('Excel export error: $e');
      return false;
    }
  }

  // Simple CSV line parser (handles quoted fields)
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString().trim());
    return result;
  }

  // ─── tiny helpers ───────────────────────────────────────────────────────
  static const _months = ['','Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  static String _fmtDate(DateTime dt) => '${_months[dt.month]} ${dt.day}, ${dt.year}';

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // make sheet scrollable on small screens
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            // ── drag handle ──
            Align(alignment: Alignment.center, child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // ── title row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Export CSV',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1248))),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 4),
            Text(widget.courseTitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 20),

            // ── mode chips ──
            Row(children: [
              _modeChip(_Mode.all, Icons.history_rounded, 'All History'),
              const SizedBox(width: 8),
              _modeChip(_Mode.session, Icons.event_rounded, 'By Session'),
              const SizedBox(width: 8),
              _modeChip(_Mode.dateRange, Icons.date_range_rounded, 'Date Range'),
            ]),
            const SizedBox(height: 20),

            // ── mode-specific options ──
            _modeOptions(),
            const SizedBox(height: 20),

            // ── preview count ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Records to export',
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.deepPurple.shade200)),
                  child: Text('$_previewRows rows',
                      style: TextStyle(color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Each row = one student attendance mark',
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 16),

            // ── validation hint ──
            if (_hint != null) ...[
              _infoBar(Colors.amber, _hint!),
              const SizedBox(height: 12),
            ],

            // ── error ──
            if (_err != null) ...[
              _infoBar(Colors.red, _err!),
              const SizedBox(height: 12),
            ],

            // ── success ──
            if (_ok) ...[
              _infoBar(Colors.green, 'Excel file exported successfully!', success: true),
              const SizedBox(height: 12),
            ],

            // ── export button ──
            SizedBox(
              height: 52, width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_valid && !_exporting) ? _export : null,
                icon: _exporting
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.file_download_rounded),
                label: Text(_exporting ? 'Generating…' : 'Export Excel',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── mode chip ──────────────────────────────────────────────────────────
  Widget _modeChip(_Mode m, IconData icon, String label) {
    final bool on = _mode == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _mode = m; _err = null; _ok = false; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: on ? Colors.deepPurple.shade600 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            boxShadow: on ? [BoxShadow(
                color: Colors.deepPurple.shade400.withValues(alpha: 0.3),
                blurRadius: 8, offset: const Offset(0,3))] : [],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: on ? Colors.white : Colors.grey[600]),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: on ? Colors.white : Colors.grey[600])),
          ]),
        ),
      ),
    );
  }

  // ─── mode-specific options ──────────────────────────────────────────────
  Widget _modeOptions() {
    switch (_mode) {
    // ── ALL ──
      case _Mode.all:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200)),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Export everything',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
              const Text('All sessions and all student records',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ]),
          ]),
        );

    // ── SINGLE SESSION ──
      case _Mode.session:
        if (widget.sessions.isEmpty) return const Text('No sessions available',
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a session',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF311B92))),
            const SizedBox(height: 10),
            ...widget.sessions.map((raw) {
              final s  = raw as Map<String, dynamic>;
              final id = s['session_id'] as int;
              final sel = _pickedSession == id;

              String dateStr = '–';
              if (s['date'] != null) {
                try { dateStr = _fmtDate(DateTime.parse(s['date'])); } catch (_) {}
              }

              return GestureDetector(
                onTap: () => setState(() { _pickedSession = id; }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: sel ? Colors.deepPurple.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? Colors.deepPurple.shade400 : Colors.grey.shade200,
                          width: sel ? 1.8 : 1)),
                  child: Row(children: [
                    // radio
                    Container(width: 22, height: 22,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: sel ? Colors.deepPurple.shade600 : Colors.grey.shade400,
                                width: 2),
                            color: sel ? Colors.deepPurple.shade600 : null),
                        child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Session #$id',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
                        Text('$dateStr  •  ${s["attended_count"] ?? 0} attended',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                      ],
                    )),
                    if (s['is_active'] == true) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Live',
                            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w600))),
                  ]),
                ),
              );
            }),
          ],
        );

    // ── DATE RANGE ──
      case _Mode.dateRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select date range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF311B92))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _datePicker('Start', _startDate, (d) => setState(() { _startDate = d; }))),
              const SizedBox(width: 8),
              const Text('→', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: _datePicker('End',   _endDate,   (d) => setState(() { _endDate   = d; }))),
            ]),
          ],
        );
    }
  }

  Widget _datePicker(String label, DateTime? val, void Function(DateTime) onSet) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: val ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(
                    primary: Colors.deepPurple.shade600, onPrimary: Colors.white),
                buttonTheme: ButtonThemeData(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            child: child!,
          ),
        );
        if (picked != null) onSet(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: val != null ? Colors.deepPurple.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: val != null ? Colors.deepPurple.shade300 : Colors.grey.shade200,
                width: val != null ? 1.5 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: Colors.deepPurple.shade500),
            const SizedBox(width: 5),
            Text(
                val != null ? _fmtDate(val) : 'Pick date',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: val != null ? Colors.deepPurple.shade800 : Colors.grey[400])),
          ]),
        ]),
      ),
    );
  }

  // ─── info bar (hint / error / success) ────────────────────────────────────
  Widget _infoBar(Color base, String text, {bool success = false}) {
    final Color bg   = success ? Colors.green.shade50  : base == Colors.red ? Colors.red.shade50   : Colors.amber.shade50;
    final Color bdr  = success ? Colors.green.shade300 : base == Colors.red ? Colors.red.shade300   : Colors.amber.shade300;
    final Color txt  = success ? Colors.green.shade700 : base == Colors.red ? Colors.red.shade700   : Colors.amber.shade800;
    final IconData ic = success ? Icons.check_circle_rounded
        : base == Colors.red ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bdr, width: 1)),
      child: Row(children: [
        Icon(ic, size: 18, color: txt),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: txt, fontSize: 13,
            fontWeight: success ? FontWeight.w600 : FontWeight.normal))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bar Chart – custom painter (FULLY RESPONSIVE)
// ─────────────────────────────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<dynamic> sessions;
  final int enrolled;
  final double availableWidth;

  const _BarChartPainter({
    required this.sessions,
    required this.enrolled,
    required this.availableWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty || enrolled == 0) return;

    final n       = sessions.length;
    // Calculate responsive spacing and sizes
    final leftPad = availableWidth * 0.08; // 8% of width
    final botPad  = 24.0;
    final spacing = (n > 4 ? 6.0 : 8.0); // Tighter spacing for more bars
    final barW    = (size.width - leftPad - (n - 1) * spacing) / n;
    final maxH    = size.height - botPad - 14;

    final enrolledPaint = Paint()..color = Colors.grey.shade300;
    final presentPaint  = Paint()..color = Colors.deepPurple.shade500;

    for (int i = 0; i < n; i++) {
      final s   = sessions[i] as Map<String, dynamic>;
      final att = (s['attended_count'] ?? 0) as int;
      final x   = leftPad + i * (barW + spacing);
      final bot = size.height - botPad;

      // enrolled bar (bg)
      canvas.drawRRect(
          RRect.fromLTRBR(x, bot - maxH, x + barW, bot, const Radius.circular(5)),
          enrolledPaint);

      // present bar (fg)
      final h = enrolled > 0 ? (att / enrolled) * maxH : 0.0;
      if (h > 0) canvas.drawRRect(
          RRect.fromLTRBR(x, bot - h, x + barW, bot, const Radius.circular(5)),
          presentPaint);

      // ── label: short date ──
      String lbl = '#${s['session_id']}';
      if (s['date'] != null) {
        try { final dt = DateTime.parse(s['date']); lbl = '${dt.day}/${dt.month}'; }
        catch (_) {}
      }
      // Responsive font size for labels
      final labelSize = (barW * 0.35).clamp(9.0, 12.0);
      _paintText(canvas,
          Offset(x + barW / 2, size.height - botPad + 5), lbl,
          labelSize, Colors.grey.shade500, TextAlign.center);

      // ── value on top of present bar ──
      if (att > 0) {
        final valueSize = (barW * 0.35).clamp(10.0, 12.0);
        _paintText(canvas,
            Offset(x + barW / 2, bot - h - 16), '$att',
            valueSize, Colors.deepPurple.shade800, TextAlign.center);
      }
    }
  }

  void _paintText(Canvas c, Offset pos, String text,
      double sz, Color col, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: sz, color: col, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.sessions != sessions || old.enrolled != enrolled || old.availableWidth != availableWidth;
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle / wave background painter – identical to lecturer_dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.9,  size.height * 0.2),  60, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8),  45, paint);
    canvas.drawCircle(Offset(size.width * 1.05, size.height * 0.85), 80, paint);

    final wp = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(i, size.height * 0.4 + math.sin((i / size.width) * 2 * math.pi) * 20);
    }
    canvas.drawPath(path, wp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
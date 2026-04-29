import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../services/database_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService _db = DatabaseService();
  Map<String, List<AttendanceRecord>> _history = {};
  bool _isLoading = true;
  String _expandedSession = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _db.getHistoryGroupedBySession();
      setState(() {
        _history = history;
        _isLoading = false;
        // Ouvrir automatiquement la dernière session
        if (history.isNotEmpty) {
          _expandedSession = history.keys.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Historique des présences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? _buildEmptyState()
          : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lancez une séance de présence pour commencer',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final sessions = _history.entries.toList();

    return Column(
      children: [
        _buildSummaryHeader(sessions),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (ctx, index) {
              final entry = sessions[index];
              return _buildSessionCard(entry.key, entry.value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(List<MapEntry<String, List<AttendanceRecord>>> sessions) {
    final totalSessions = sessions.length;
    final totalRecords = sessions.fold<int>(0, (sum, e) => sum + e.value.length);
    final totalPresent = sessions.fold<int>(
      0,
          (sum, e) => sum + e.value.where((r) => r.isPresent).length,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat('Séances', totalSessions.toString(), Icons.event),
          _buildDivider(),
          _buildHeaderStat('Enregistrements', totalRecords.toString(), Icons.list),
          _buildDivider(),
          _buildHeaderStat(
            'Taux présence',
            totalRecords > 0
                ? '${(totalPresent / totalRecords * 100).toStringAsFixed(0)}%'
                : '-',
            Icons.percent,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSessionCard(String sessionKey, List<AttendanceRecord> records) {
    final isExpanded = _expandedSession == sessionKey;
    final presentCount = records.where((r) => r.isPresent).length;
    final total = records.length;
    final rate = total > 0 ? (presentCount / total * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // En-tête de session (cliquable)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expandedSession = isExpanded ? '' : sessionKey;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      color: Color(0xFF1565C0),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '$total étudiants',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Taux de présence
                  Column(
                    children: [
                      _buildRateIndicator(rate),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Liste des étudiants (expandable)
          if (isExpanded) ...[
            const Divider(height: 1),
            // Résumé de la session
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildMiniStat('Présents', presentCount, const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _buildMiniStat('Absents', total - presentCount, Colors.red.shade700),
                ],
              ),
            ),
            const Divider(height: 1),
            // Liste des étudiants
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (ctx, index) {
                final record = records[index];
                return _buildRecordTile(record);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateIndicator(int rate) {
    final color = rate >= 75
        ? const Color(0xFF2E7D32)
        : rate >= 50
        ? Colors.orange
        : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$rate%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(AttendanceRecord record) {
    final isPresent = record.isPresent;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor:
        isPresent ? const Color(0xFF2E7D32).withOpacity(0.15) : Colors.red.shade50,
        child: Icon(
          isPresent ? Icons.check : Icons.close,
          size: 14,
          color: isPresent ? const Color(0xFF2E7D32) : Colors.red.shade700,
        ),
      ),
      title: Text(
        record.studentName,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${record.classe} • ${record.groupe}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isPresent
              ? const Color(0xFF2E7D32).withOpacity(0.1)
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isPresent ? 'Présent' : 'Absent',
          style: TextStyle(
            color: isPresent ? const Color(0xFF2E7D32) : Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
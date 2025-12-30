import 'package:flutter/material.dart';
import '../models/exercise_summary.dart';
import 'package:intl/intl.dart';
import '../models/exercise_type.dart';

class ExerciseHistoryPage extends StatefulWidget {
  final String currentUser;

  const ExerciseHistoryPage({super.key, required this.currentUser});

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  List<ExerciseSummary> _allSummaries = [];

  String _searchQuery = '';

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return timestamp;
    }
  }

  void _loadSummaries() async {
    final summaries =
        await ExerciseSummaryDatabase.instance.getAllSummaries();
    setState(() {
      _allSummaries = summaries
          .where((s) => s.username == widget.currentUser)
          .toList();
    });
  }

  void _confirmDeleteSummary(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are You Sure You Want to Delete This Summary?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.greenAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ExerciseSummaryDatabase.instance.deleteSummary(id);
      _loadSummaries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary Deleted Successfully!'),
          backgroundColor: Color.fromARGB(255, 114, 186, 116),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSummaries();
  }

  @override
  Widget build(BuildContext context) {
    List<ExerciseSummary> filteredList = _allSummaries
        .where((s) =>
            s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.exerciseType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.timestamp.contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('View Exercise History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00BCD4),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              final query = await showSearch<String>(
                context: context,
                delegate: _SummarySearchDelegate(_allSummaries, _formatTimestamp),
              );
              if (query != null) {
                setState(() {
                  _searchQuery = query;
                });
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.green[800],
        onRefresh: () async {
          _loadSummaries();
        },
        child: filteredList.isEmpty
            ? const Center(
                child: Text(
                  'No Exercise Session History Found.',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final s = filteredList[index];
                  return _HistoryCard(
                    summary: s,
                    formatTimestamp: _formatTimestamp,
                    onDelete: () => _confirmDeleteSummary(s.id!),
                  );
                },
              ),
      ),
    );
  }
}

class _SummarySearchDelegate extends SearchDelegate<String> {
  final List<ExerciseSummary> summaries;
  final String Function(String) formatTimestamp;

  _SummarySearchDelegate(this.summaries, this.formatTimestamp);

  @override
  String? get searchFieldLabel => 'Search by Exercise Session Name, Exercise Type, or Date';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(color: Colors.white70);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white70),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = summaries
        .where((s) =>
            s.name.toLowerCase().contains(query.toLowerCase()) ||
            s.exerciseType.toLowerCase().contains(query.toLowerCase()) ||
            formatTimestamp(s.timestamp).contains(query))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final s = suggestions[index];
        return ListTile(
          title: Text(s.name, style: const TextStyle(color: Colors.black)),
          subtitle: Text(
              '${formatTimestamp(s.timestamp)} • Type: ${s.exerciseType} • Focus: ${(s.focusPercent * 100).toStringAsFixed(1)}% • User: ${s.username}',
              style: const TextStyle(color: Colors.black54)),
          onTap: () => close(context, query),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ExerciseSummary summary;
  final VoidCallback onDelete;
  final String Function(String) formatTimestamp;

  const _HistoryCard({
    required this.summary,
    required this.onDelete,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;

    return Card(
      elevation: 6,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Exercise Type: ${ExerciseType.values.firstWhere((e) => e.name == s.exerciseType).displayName}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Total Duration: ${s.totalSeconds}s', style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 4),
            Text(formatTimestamp(s.timestamp), style: const TextStyle(color: Colors.black)),
            const SizedBox(height: 8),
            Text(
              'Focus Pose: ${s.focusSeconds}s (${(s.focusPercent * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(color: Color(0xFF006400)),
            ),
            const SizedBox(height: 4),
            Text(
              'Unfocus Pose: ${s.unfocusSeconds}s (${(s.unfocusPercent * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(color: Color(0xFF8B0000)),
            ),
          ],
        ),
      ),
    );
  }
}
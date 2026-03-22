import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/models/fgs_result.dart';
import 'package:cat_pain_detector/services/database_service.dart';
import 'package:cat_pain_detector/history/history_item.dart';
import 'package:cat_pain_detector/history/saved_result_page.dart';

enum SortOption {
  dateDesc('Date ↓'),
  dateAsc('Date ↑'),
  nameDesc('Name ↓'),
  nameAsc('Name ↑'),
  scoreDesc('Score ↓'),
  scoreAsc('Score ↑');

  const SortOption(this.label);
  final String label;
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<FGSResult> _allResults = [];
  List<FGSResult> _filteredResults = [];
  SortOption _currentSort = SortOption.dateDesc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);

    try {
      _allResults = await _dbService.getResultsSorted(
        _getSortField(_currentSort),
        _getSortDirection(_currentSort),
      );
      _applySearchFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading results: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSortField(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
      case SortOption.dateAsc:
        return 'date';
      case SortOption.nameDesc:
      case SortOption.nameAsc:
        return 'name';
      case SortOption.scoreDesc:
      case SortOption.scoreAsc:
        return 'score';
    }
  }

  bool _getSortDirection(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
      case SortOption.nameDesc:
      case SortOption.scoreDesc:
        return false; // descending
      case SortOption.dateAsc:
      case SortOption.nameAsc:
      case SortOption.scoreAsc:
        return true; // ascending
    }
  }

  void _onSearchChanged() {
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredResults = List.from(_allResults);
    } else {
      _filteredResults = _allResults
          .where((result) => result.catName.toLowerCase().contains(query))
          .toList();
    }
    setState(() {});
  }

  Future<void> _showSortOptions() async {
    final SortOption? selected = await showDialog<SortOption>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sort by'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: SortOption.values.map((option) {
              return RadioListTile<SortOption>(
                title: Text(option.label),
                value: option,
                groupValue: _currentSort,
                onChanged: (SortOption? value) {
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null && selected != _currentSort) {
      setState(() => _currentSort = selected);
      await _loadResults();
    }
  }

  void _onResultTap(FGSResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedResultPage(
          result: result,
          onResultDeleted: _loadResults, // Refresh list after deletion
          onResultUpdated: _loadResults, // Refresh list after update
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        children: [
          // Search and Sort Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Search bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by cat name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: lightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: lightBlue.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: lightBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Sort button
                TextButton.icon(
                  onPressed: _showSortOptions,
                  icon: const Icon(Icons.sort),
                  label: Text(_currentSort.label),
                  style: TextButton.styleFrom(
                    foregroundColor: darkBlue,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = _filteredResults[index];
                          return HistoryItem(
                            result: result,
                            onTap: () => _onResultTap(result),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No FGS results saved yet'
                : 'No results found for "${_searchController.text}"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Save your first result to see it here'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

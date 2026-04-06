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
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};

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
    if (_isSelectionMode) {
      _toggleSelection(result.id!);
    } else {
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
  }

  void _onItemLongPress(FGSResult result) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.add(result.id!);
      });
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds =
          _filteredResults.where((r) => r.id != null).map((r) => r.id!).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  bool get _allSelected {
    final idsWithData =
        _filteredResults.where((r) => r.id != null).map((r) => r.id!).toSet();
    return _filteredResults.isNotEmpty &&
        _selectedIds.length == idsWithData.length;
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Results'),
          content: Text(
            'Are you sure you want to delete ${_selectedIds.length} result${_selectedIds.length > 1 ? 's' : ''}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteResults(_selectedIds.toList());
        _exitSelectionMode();
        await _loadResults();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${_selectedIds.length} result${_selectedIds.length > 1 ? 's' : ''} deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting results: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelectionMode && _searchController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isSelectionMode) {
            _exitSelectionMode();
          } else if (_searchController.text.isNotEmpty) {
            _searchController.clear();
            _applySearchFilter();
          }
        }
      },
      child: Scaffold(
        backgroundColor: whiteColor,
        body: Column(
          children: [
            // Search and Sort Header (hide if selection is on)
            if (!_isSelectionMode)
              Container(
                height: 70,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          return TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by cat name...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: value.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _searchController.clear();
                                        _applySearchFilter();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: lightBlue),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: lightBlue.withValues(alpha: 0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: lightBlue),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          );
                        },
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

            // Selection Controls Row (show if selection is on)
            if (_isSelectionMode)
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: lightBlue.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _exitSelectionMode,
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancel Selection',
                    ),
                    Text(
                      '${_selectedIds.length} selected',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _allSelected ? _deselectAll : _selectAll,
                      icon: Icon(
                        _allSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: darkBlue,
                      ),
                      tooltip: _allSelected ? 'Deselect All' : 'Select All',
                    ),
                    IconButton(
                      onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                      icon: Icon(
                        Icons.delete,
                        color: _selectedIds.isEmpty
                            ? Colors.grey[400]
                            : Colors.red,
                      ),
                      tooltip: 'Delete',
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
                              onLongPress: () => _onItemLongPress(result),
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(result.id),
                              onSelectionChanged: (selected) {
                                if (result.id != null) {
                                  _toggleSelection(result.id!);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
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

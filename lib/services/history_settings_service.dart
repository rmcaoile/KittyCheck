import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_pain_detector/history/history.dart';

class HistorySettingsService {
  static const String _sortOptionKey = 'history_sort_option';

  Future<SortOption> getSortOption() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_sortOptionKey) ?? 0;
    if (index >= 0 && index < SortOption.values.length) {
      return SortOption.values[index];
    }
    return SortOption.dateDesc;
  }

  Future<void> setSortOption(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortOptionKey, option.index);
  }
}

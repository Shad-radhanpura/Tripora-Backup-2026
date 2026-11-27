import '../models/checklist_item.dart';

/// Progress of a trip's checklist, calculated only from the stored items.
class ChecklistProgress {
  ChecklistProgress._();

  static int completed(List<ChecklistItem> items) =>
      items.where((item) => item.done).length;

  /// Share of items completed, from 0 to 1. Zero when there are no items.
  static double fraction(List<ChecklistItem> items) =>
      items.isEmpty ? 0 : completed(items) / items.length;

  /// For example "7 of 10 tasks completed".
  static String summary(List<ChecklistItem> items) =>
      '${completed(items)} of ${items.length} '
      '${items.length == 1 ? 'task' : 'tasks'} completed';
}

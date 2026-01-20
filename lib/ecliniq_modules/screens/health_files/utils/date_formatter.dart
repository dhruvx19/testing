/// Utility class for formatting dates in health files
class HealthFileDateFormatter {
  /// Format date and time in the format: "08/08/2025 | 9:30pm"
  /// 
  /// [date] - The DateTime to format
  /// Returns formatted string like "08/08/2025 | 9:30pm"
  static String formatDateTime(DateTime date) {
    // Format date as DD/MM/YYYY
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    
    // Format time as h:mma (e.g., 9:30pm, 10:15am)
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final hour12 = hour == 0 
        ? 12 
        : hour > 12 
            ? hour - 12 
            : hour;
    final period = hour < 12 ? 'am' : 'pm';
    
    return '$day/$month/$year | $hour12:$minute$period';
  }
  
  /// Format date only in the format: "08/08/2025"
  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
  
  /// Format time only in the format: "9:30pm"
  static String formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final hour12 = hour == 0 
        ? 12 
        : hour > 12 
            ? hour - 12 
            : hour;
    final period = hour < 12 ? 'am' : 'pm';
    
    return '$hour12:$minute$period';
  }
}







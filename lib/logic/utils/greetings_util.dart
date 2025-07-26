class GreetingUtils {
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      return '🌞 Buenos días';
    } else if (hour >= 12 && hour < 20) {
      return '🌤️ Buenas tardes';
    } else {
      return '🌙 Buenas noches';
    }
  }
}

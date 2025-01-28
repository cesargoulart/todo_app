import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://vggdloymkuntqiisrivy.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZ2Rsb3lta3VudHFpaXNyaXZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc4OTQxNTUsImV4cCI6MjA1MzQ3MDE1NX0.X1-dH3eRMcwQZ3fqkvHJ0gbweWM0UfO76Nqh8NV1gCo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }
}

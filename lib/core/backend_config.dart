class BackendConfig {
  const BackendConfig._();

  static const clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY'),
  );
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL'),
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
    ),
  );
  static const supabaseJwtTemplate = String.fromEnvironment(
    'SUPABASE_JWT_TEMPLATE',
    defaultValue: 'supabase',
  );

  static bool get hasClerk => clerkPublishableKey.isNotEmpty;
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}

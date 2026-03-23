import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/pages/auth_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/organization/presentation/pages/organization_choice_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart' as onboarding;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bubhfsnvulfdmtbocgjq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1Ymhmc252dWxmZG10Ym9jZ2pxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4ODEwNDEsImV4cCI6MjA4ODQ1NzA0MX0.Za-V68_qJo9QxVgTyeWJADR8CZQOq__7XwEux90xMa8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrgaFlow',
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
      routes: {
        '/organization': (context) => const OrganizationChoicePage(),
        '/onboarding': (context) => const onboarding.OnboardingPage(),
        '/dashboard': (context) => const ProfilePage(),
      },
    );
  }
}
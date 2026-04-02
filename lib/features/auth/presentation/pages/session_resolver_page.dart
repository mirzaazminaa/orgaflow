import 'package:flutter/material.dart';

import '../../../../core/session/session_context.dart';
import '../../../../core/utils/message_helper.dart';
import '../presenters/session_resolver_presenter.dart';

class SessionResolverPage extends StatefulWidget {
  const SessionResolverPage({super.key});

  @override
  State<SessionResolverPage> createState() => _SessionResolverPageState();
}

class _SessionResolverPageState extends State<SessionResolverPage> {
  SessionResolverPresenter? _presenter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolve();
    });
  }

  Future<void> _resolve() async {
    // Check URL for password recovery code
    final uri = Uri.base;
    
    // Check for error in URL (expired link)
    if (uri.queryParameters['error_code'] == 'otp_expired') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link reset password sudah kadaluarsa. Silakan request ulang.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      });
      return;
    }
    
    // Check if URL has recovery code (type=recovery or just code parameter)
    if (uri.queryParameters.containsKey('code') || 
        uri.queryParameters['type'] == 'recovery') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/reset-password');
      return;
    }

    // Normal flow
    final result = await (_presenter ??= SessionResolverPresenter())
        .resolve(refresh: true);

    if (!mounted) {
      return;
    }

    final target = result.isSuccess ? result.data! : AppRouteTarget.auth;
    if (result.isFailure) {
      MessageHelper.showSnackBar(context, result.error!.message);
    }

    Navigator.pushReplacementNamed(context, target.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

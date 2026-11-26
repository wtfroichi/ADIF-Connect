import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_container.dart';
import '../../services/auth_sync_service.dart';

class AccountAuthSheet extends StatefulWidget {
  final AuthSyncService authSyncService;

  const AccountAuthSheet({
    super.key,
    required this.authSyncService,
  });

  @override
  State<AccountAuthSheet> createState() => _AccountAuthSheetState();
}

class _AccountAuthSheetState extends State<AccountAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _useCode = false;
  bool _isCreatingAccount = false;
  bool _awaitingCode = false;
  bool _isBusy = false;
  bool _isClosing = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    widget.authSyncService.addListener(_closeAfterMagicLink);
  }

  @override
  void dispose() {
    widget.authSyncService.removeListener(_closeAfterMagicLink);
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _closeAfterMagicLink() {
    if (!mounted ||
        _isBusy ||
        _isClosing ||
        !widget.authSyncService.isSignedIn) {
      return;
    }
    _isClosing = true;
    Navigator.of(context).pop();
  }

  bool get _hasValidEmail => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
      .hasMatch(_emailController.text.trim());

  Future<void> _submit() async {
    if (!_hasValidEmail) {
      setState(() {
        _message = AppStrings.accountEmailRequired;
        _messageIsError = true;
      });
      return;
    }
    if (_useCode &&
        _awaitingCode &&
        !RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim())) {
      setState(() {
        _message = AppStrings.accountCodeRequired;
        _messageIsError = true;
      });
      return;
    }
    if (!_useCode && _passwordController.text.isEmpty) {
      setState(() {
        _message = AppStrings.accountPasswordRequired;
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      if (_useCode) {
        if (!_awaitingCode) {
          await widget.authSyncService.sendEmailOtp(_emailController.text);
          if (!mounted) return;
          setState(() {
            _awaitingCode = true;
            _message = AppStrings.accountCodeSent;
            _messageIsError = false;
          });
        } else {
          await widget.authSyncService.verifyEmailOtp(
            _emailController.text,
            _codeController.text,
          );
          if (mounted) Navigator.of(context).pop();
        }
      } else if (_isCreatingAccount) {
        final signedIn = await widget.authSyncService.signUpWithPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (!mounted) return;
        if (signedIn) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _message = AppStrings.accountCheckEmail;
            _messageIsError = false;
          });
        }
      } else {
        await widget.authSyncService.signInWithPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } on AuthSyncException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, inset + 16),
        child: GlassContainer(
          borderRadius: 26,
          padding: const EdgeInsets.all(22),
          backgroundColor: AppTheme.getSurfaceColor(context)
              .withValues(alpha: AppTheme.isDark(context) ? 0.94 : 0.97),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.accountAuthTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.ticketClose,
                    onPressed: _isBusy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                enabled: !_isBusy && !_awaitingCode,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: AppStrings.accountEmail,
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              if (_useCode && _awaitingCode) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: AppStrings.accountCode,
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
              ] else if (!_useCode) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  enabled: !_isBusy,
                  obscureText: true,
                  autofillHints: [
                    _isCreatingAccount
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: AppStrings.accountPassword,
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError
                        ? theme.colorScheme.error
                        : AppTheme.adifTeal,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isBusy ? null : _submit,
                child: _isBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_primaryAction),
              ),
              if (!_useCode && !_awaitingCode)
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => setState(
                            () => _isCreatingAccount = !_isCreatingAccount,
                          ),
                  child: Text(
                    _isCreatingAccount
                        ? AppStrings.accountHaveAccount
                        : AppStrings.accountNeedAccount,
                  ),
                ),
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () => setState(() {
                          _useCode = !_useCode;
                          _awaitingCode = false;
                          _message = null;
                        }),
                child: Text(
                  _useCode
                      ? AppStrings.accountUsePassword
                      : AppStrings.accountUseCode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _primaryAction {
    if (_useCode) {
      return _awaitingCode
          ? AppStrings.accountVerifyCode
          : AppStrings.accountSendCode;
    }
    return _isCreatingAccount
        ? AppStrings.accountSignUp
        : AppStrings.accountSignIn;
  }
}

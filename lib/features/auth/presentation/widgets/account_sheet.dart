import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AccountSheet extends StatefulWidget {
  const AccountSheet({
    super.key,
    required this.user,
    required this.authRepository,
    required this.expenseRepository,
    required this.settingsController,
  });

  final AuthUser user;
  final AuthRepository authRepository;
  final ExpenseRepository expenseRepository;
  final AppSettingsController settingsController;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  Future<void> _resetExpenses(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete_history_title')),
        content: Text(l10n.t('delete_history_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('delete_everything')),
          ),
        ],
      ),
    );

    if (shouldReset != true || !context.mounted) return;

    try {
      await widget.expenseRepository.deleteAllExpenses();
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('reset_failed'))));
      }
    }
  }

  Future<void> _changePassword() async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );

    if (newPassword == null || !mounted) return;

    try {
      await widget.authRepository.changePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('password_updated')),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final message = widget.user.isGoogleUser
            ? AppLocalizations.of(context).t('google_no_password')
            : AppLocalizations.of(context).t('password_failed');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await widget.authRepository.signOut();
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).t('sign_out_failed')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            Text(
              l10n.t('account_settings'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.person_outline_rounded),
              ),
              title: Text(l10n.t('signed_in_as')),
              subtitle: Text(widget.user.email),
            ),
            const Divider(height: 28),
            DropdownButtonFormField<AppCurrency>(
              initialValue: widget.settingsController.currency,
              decoration: InputDecoration(
                labelText: l10n.t('currency'),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              items: AppCurrency.values
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency.label),
                    ),
                  )
                  .toList(),
              onChanged: (currency) {
                if (currency != null) {
                  widget.settingsController.setCurrency(currency);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AppLanguage>(
              initialValue: widget.settingsController.language,
              decoration: InputDecoration(
                labelText: l10n.t('language'),
                prefixIcon: Icon(Icons.language_rounded),
              ),
              items: AppLanguage.values
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(language.label),
                    ),
                  )
                  .toList(),
              onChanged: (language) {
                if (language != null) {
                  widget.settingsController.setLanguage(language);
                }
              },
            ),
            const SizedBox(height: 14),
            if (!widget.user.isGoogleUser)
              OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_reset_outlined),
                label: Text(l10n.t('change_password')),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _resetExpenses(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(l10n.t('reset_history')),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l10n.t('sign_out')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.t('change_password_title')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.t('new_password')),
              validator: (value) => value == null || value.length < 6
                  ? l10n.t('min_password')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.t('confirm_password'),
              ),
              validator: (value) => value != _passwordController.text
                  ? l10n.t('passwords_match')
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_passwordController.text);
            }
          },
          child: Text(l10n.t('update_password')),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_components.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_localizations.dart';

class SecurityTab extends StatelessWidget {
  const SecurityTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      child: Padding(
        padding: getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSpacing.item(),

            // Warning: Encryption not yet functional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'security_settings.not_functional_title'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'security_settings.not_functional_description'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SettingsSpacing.section(),

            // Encryption Section
            SettingsSectionTitle(text: 'encryption'.tr()),

            SettingsSwitchRow(
              title: 'security_settings.encrypt_entries'.tr(),
              value: settings.encryptionEnabled,
              onChanged: (value) async {
                if (value) {
                  // Show setup dialog when enabling
                  await _showEncryptionSetupDialog(context);
                } else {
                  // Show confirmation when disabling
                  await _showDisableEncryptionDialog(context);
                }
              },
            ),

            if (settings.encryptionEnabled) ...[
              SettingsSpacing.item(),

              // Info box about encryption
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'security_settings.encryption_info'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SettingsSpacing.section(),

            // Passphrase Storage Section (only visible when encryption is enabled)
            if (settings.encryptionEnabled) ...[
              SettingsSectionTitle(
                text: 'security_settings.passphrase_storage'.tr(),
              ),

              SettingsHelperText(
                text: 'security_settings.passphrase_storage_description'.tr(),
              ),

              SettingsSpacing.item(),

              SettingsSwitchRow(
                title: 'security_settings.save_passphrase_for_biometric'.tr(),
                value: settings.biometricUnlockEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Enable biometric unlock
                    await _showEnableBiometricDialog(context);
                  } else {
                    // Disable biometric unlock
                    await _showDisableBiometricDialog(context);
                  }
                },
              ),

              SettingsSpacing.section(),

              // Manage Encryption Section
              SettingsSectionTitle(
                text: 'security_settings.manage_encryption'.tr(),
              ),

              SettingsSpacing.item(),

              // Change Passphrase Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePassphraseDialog(context),
                  icon: const Icon(Icons.key),
                  label: Text('security_settings.change_passphrase'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              SettingsSpacing.item(),

              // Encrypt All Entries Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showEncryptAllEntriesDialog(context),
                  icon: const Icon(Icons.lock),
                  label: Text('security_settings.encrypt_all_entries'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              SettingsSpacing.item(),

              // Export Key Backup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showExportKeyDialog(context),
                  icon: const Icon(Icons.download),
                  label: Text('security_settings.export_key_backup'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              SettingsSpacing.item(),

              // Import Key Backup Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showImportKeyDialog(context),
                  icon: const Icon(Icons.upload),
                  label: Text('security_settings.import_key_backup'.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              SettingsSpacing.section(),
            ],
          ],
        ),
      ),
    );
  }

  // Placeholder dialog methods - to be implemented later
  Future<void> _showEncryptionSetupDialog(BuildContext context) async {
    // TODO: Implement encryption setup dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.setup_encryption'.tr()),
        content: const Text('Encryption setup dialog - To be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisableEncryptionDialog(BuildContext context) async {
    // TODO: Implement disable encryption confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.disable_encryption'.tr()),
        content: const Text(
          'Disable encryption confirmation - To be implemented',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('disable'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showEnableBiometricDialog(BuildContext context) async {
    // TODO: Implement enable biometric dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.enable_biometric'.tr()),
        content: const Text('Enable biometric dialog - To be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisableBiometricDialog(BuildContext context) async {
    // TODO: Implement disable biometric confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.disable_biometric'.tr()),
        content: const Text(
          'Disable biometric confirmation - To be implemented',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('disable'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePassphraseDialog(BuildContext context) async {
    // TODO: Implement change passphrase dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.change_passphrase'.tr()),
        content: const Text('Change passphrase dialog - To be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showEncryptAllEntriesDialog(BuildContext context) async {
    // TODO: Implement encrypt all entries confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.encrypt_all_entries'.tr()),
        content: const Text(
          'Encrypt all entries confirmation - To be implemented',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportKeyDialog(BuildContext context) async {
    // TODO: Implement export key dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.export_key_backup'.tr()),
        content: const Text('Export key dialog - To be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportKeyDialog(BuildContext context) async {
    // TODO: Implement import key dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('security_settings.import_key_backup'.tr()),
        content: const Text('Import key dialog - To be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }
}

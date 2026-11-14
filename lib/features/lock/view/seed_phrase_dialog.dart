import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/shared/overlays/snack_bar_manager.dart';

import '../lock_manger/lock_manager.dart';
import 'widgets/lock_dialog_shell.dart';

/// Modal dialog displaying the generated 12-word BIP39 recovery seed phrase right after setup.
class SeedPhraseDisplayDialog extends ConsumerWidget {
  final String phrase;

  const SeedPhraseDisplayDialog({
    super.key,
    required this.phrase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final words = phrase.split(' ').where((w) => w.isNotEmpty).toList();

    return LockDialogShell(
      width: 400,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key_rounded, size: 36, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            "Save Your Recovery Phrase",
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Write down these 12 words in order. You will need them if you ever forget your master password.",
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // 12-Word Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(words.length, (index) {
                return Chip(
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  label: Text(
                    words[index],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phrase));
                    SnackBarManager.show(
                      msg: 'Recovery phrase copied to clipboard!',
                      type: SnackBarMessageType.acknowledgment,
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ref.read(lockManagerProvider.notifier).clearActiveRecoveryPhrase();
                    Navigator.pop(context);
                  },
                  child: const Text('I Have Saved It'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

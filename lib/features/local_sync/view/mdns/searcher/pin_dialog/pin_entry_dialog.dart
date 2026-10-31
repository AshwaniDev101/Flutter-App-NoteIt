import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../shared/overlays/app_scaffold.dart';
import '../../../../../../shared/overlays/snack_bar_manager.dart';
import 'package:noteit/features/home/view/desktop/content_panel/core/navigator.dart';

class PinEntryDialog extends StatefulWidget {
  final String? hostName;
  final String? hostIp;

  const PinEntryDialog({
    super.key,
    this.hostName,
    this.hostIp,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin() {
    final pin = _pinController.text.trim();
    if (pin.length == 4) {
      context.pop(pin);
    } else {
      SnackBarManager.show(
        msg: 'Please enter all 4 digits.',
        type: SnackBarMessageType.suggestion,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold.rightPanel(
      option: RightPanelPageOptions.pin,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lock Icon Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 36, color: Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Enter Pairing PIN',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Compact Host Metadata Card
                  if (widget.hostName != null || widget.hostIp != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.laptop_rounded, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.hostName != null)
                                  Text(
                                    widget.hostName!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (widget.hostIp != null)
                                  Text(
                                    'IP: ${widget.hostIp!}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Text(
                    'Enter the 4-digit PIN displayed on the host device.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4-Digit Input Field
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.trim().length == 4) {
                            _submitPin();
                          }
                        },
                        onSubmitted: (_) => _submitPin(),
                        style: textTheme.displayMedium?.copyWith(
                          fontSize: 32,
                          letterSpacing: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '0000',
                          counterText: '',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitPin,
                    child: Text('Connect', style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
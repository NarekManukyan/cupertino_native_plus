import 'package:cupertino_native_plus/cupertino_native_plus.dart';
import 'package:flutter/cupertino.dart';

class ToastDemoPage extends StatelessWidget {
  const ToastDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Toast')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Toast Styles'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNButton(
                  label: 'Normal',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'This is a normal toast',
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Success',
                  onPressed: () => CNToast.success(
                    context: context,
                    message: 'Profile updated',
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Error',
                  onPressed: () => CNToast.error(
                    context: context,
                    message: 'Failed to save changes',
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Warning',
                  onPressed: () => CNToast.warning(
                    context: context,
                    message: 'Battery is low',
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Info',
                  onPressed: () => CNToast.info(
                    context: context,
                    message: 'New update available',
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Positions'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNButton(
                  label: 'Top',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'Toast at the top',
                    position: CNToastPosition.top,
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Center',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'Toast in the center',
                    position: CNToastPosition.center,
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Bottom',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'Toast at the bottom',
                    position: CNToastPosition.bottom,
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Loading Toast'),
            const SizedBox(height: 12),
            const _LoadingToastButton(),
            const SizedBox(height: 24),
            const Text('Custom'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CNButton(
                  label: 'Custom Background',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'Custom tinted toast',
                    backgroundColor: CupertinoColors.systemPurple.withValues(
                      alpha: 0.9,
                    ),
                    textColor: CupertinoColors.white,
                    useGlassEffect: false,
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
                CNButton(
                  label: 'Custom Icon',
                  onPressed: () => CNToast.show(
                    context: context,
                    message: 'Copied to clipboard',
                    icon: const Icon(
                      CupertinoIcons.doc_on_clipboard_fill,
                      color: CupertinoColors.systemBlue,
                      size: 24,
                    ),
                  ),
                  config: const CNButtonConfig(
                    style: CNButtonStyle.tinted,
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingToastButton extends StatefulWidget {
  const _LoadingToastButton();

  @override
  State<_LoadingToastButton> createState() => _LoadingToastButtonState();
}

class _LoadingToastButtonState extends State<_LoadingToastButton> {
  CNLoadingToastHandle? _handle;

  @override
  void dispose() {
    _handle?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CNButton(
          label: 'Show Loading',
          onPressed: _handle == null
              ? () {
                  final ctx = context;
                  final handle = CNToast.loading(
                    context: ctx,
                    message: 'Processing...',
                  );
                  setState(() => _handle = handle);
                  Future.delayed(const Duration(seconds: 2), () {
                    handle.dismiss();
                    if (mounted) {
                      setState(() => _handle = null);
                      CNToast.success(context: ctx, message: 'Done!');
                    }
                  });
                }
              : null,
          config: const CNButtonConfig(
            style: CNButtonStyle.tinted,
            shrinkWrap: true,
          ),
        ),
      ],
    );
  }
}

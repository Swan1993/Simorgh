import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/diagnostics/debug_bundle.dart';
import '../core/failures/failure_code.dart';
import '../core/logging/log_entry.dart';
import '../core/logging/log_service.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class ConsolePage extends StatefulWidget {
  const ConsolePage({required this.strings, this.logger, super.key});
  final AppStrings strings;
  final LogService? logger;
  @override
  State<ConsolePage> createState() => _ConsolePageState();
}

class _ConsolePageState extends State<ConsolePage> {
  late final LogService _logger;
  late final List<LogEntry> _logs;
  StreamSubscription<LogEntry>? _logSubscription;
  bool _autoScroll = true;
  bool get _isPreview => widget.logger == null;

  @override
  void initState() {
    super.initState();
    _logger = widget.logger ?? LogService(maxEntries: 2000);
    if (_isPreview) {
      _logger.info('scanner', 'CIDR ranges loaded: 2,500 candidates');
      _logger.info('scanner', 'handshake 104.16.132.48 24ms CLEAN');
      _logger.warning('scanner', 'handshake 104.28.14.99 timeout');
      _logger.error(
        'core',
        'TLS_WANT_READ RST injection detected',
        errorCode: FailureCode.tlsHandshakeReset.wireCode,
      );
      _logger.ai('diag', 'candidate failover route selected');
    } else {
      _logSubscription = _logger.stream.listen((_) {
        if (mounted) {
          setState(() => _logs = List<LogEntry>.from(_logger.entries));
        }
      });
    }
    _logs = List<LogEntry>.from(_logger.entries);
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    if (_isPreview) unawaited(_logger.dispose());
    super.dispose();
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final failureCode = _isPreview
        ? FailureCode.tlsHandshakeReset
        : FailureCode.unknown;
    final failure = failureCode.localized(
      FailureLanguage.fromCode(s.locale.languageCode),
    );
    final bundle = DebugBundle(
      version: '0.1.0',
      stage: _isPreview ? 'verifyingConnection' : 'idle',
      failure: failureCode,
      logs: _logs,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Console / Diagnostics',
            subtitle: s.consoleSubtitle,
            action: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _copy(_logs.map((e) => e.toHumanReadable()).join('\n')),
                  icon: const Icon(Icons.copy),
                  label: Text(s.copyAll),
                ),
                FilledButton.icon(
                  onPressed: _logs.isEmpty
                      ? null
                      : () => _copy(bundle.toMarkdown()),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(s.copyIde),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Panel(
            child: _isPreview
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.cyan),
                          const SizedBox(width: 10),
                          Text(
                            s.aiDiagnosis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          const StatusChip(
                            'CONFIDENCE 94%',
                            color: AppColors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        failure.title,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(failure.explanation),
                      const SizedBox(height: 10),
                      Text(
                        failure.fixes.join('  •  '),
                        style: const TextStyle(color: AppColors.green),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _logs.isEmpty
                              ? 'No active diagnostic. Connection events will appear here.'
                              : 'Live diagnostic data is available from the active session.',
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Mono('LIVE TERMINAL', color: AppColors.cyan),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            setState(() => _autoScroll = !_autoScroll),
                        icon: Icon(
                          _autoScroll
                              ? Icons.vertical_align_bottom
                              : Icons.pause_circle_outline,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copy(bundle.toMarkdown()),
                        icon: const Icon(
                          Icons.integration_instructions_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _logs.clear()),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  const Divider(),
                  for (final entry in _logs) _LogRow(entry: entry),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});
  final LogEntry entry;
  @override
  Widget build(BuildContext context) {
    final color = switch (entry.level) {
      LogLevel.error => AppColors.red,
      LogLevel.warning => AppColors.amber,
      LogLevel.ai => AppColors.cyan,
      _ => AppColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Mono(entry.toHumanReadable(), color: color),
    );
  }
}

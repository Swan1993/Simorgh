import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({required this.strings, super.key});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [PageHeader(title: 'Console / Diagnostics', subtitle: strings.consoleSubtitle, action: Wrap(spacing: 8, children: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.copy), label: Text(strings.copyAll)), FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.auto_awesome), label: Text(strings.analyze))])), const SizedBox(height: 18), Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.auto_awesome, color: AppColors.cyan), const SizedBox(width: 10), Text(strings.aiDiagnosis, style: Theme.of(context).textTheme.titleLarge), const Spacer(), const StatusChip('CONFIDENCE 94%', color: AppColors.green)]), const SizedBox(height: 16), const Text('SNI Filtering / Handshake RST detected on Cloudflare CIDR 104.28.0.0/16.'), const SizedBox(height: 10), const Text('Recommendation: switch to a clean subnet and verify TLS 1.3 + ECH mode.', style: TextStyle(color: AppColors.green))])), const SizedBox(height: 14), Panel(child: SelectionArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Mono('LIVE TERMINAL', color: AppColors.cyan), const Spacer(), OutlinedButton(onPressed: () {}, child: Text(strings.copyIde)), IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline))]), const Divider(), for (final line in _logs) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Mono(line, color: line.contains('ERROR') ? AppColors.red : line.contains('WARN') ? AppColors.amber : AppColors.muted))])))]));
}

const _logs = ['[12:42:01] INFO  scanner  CIDR ranges loaded: 2,500 candidates', '[12:42:03] INFO  scanner  handshake 104.16.132.48 24ms CLEAN', '[12:42:04] WARN  scanner  handshake 104.28.14.99 timeout', '[12:42:07] ERROR core     TLS_WANT_READ RST injection detected', '[12:42:08] AI    diag     candidate failover route selected'];

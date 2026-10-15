import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class RelaysPage extends StatelessWidget {
  const RelaysPage({required this.strings, super.key});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [PageHeader(title: 'Network Orchestration', subtitle: strings.relaysSubtitle, action: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: Text(strings.addRelay))), const SizedBox(height: 20), Row(children: [Expanded(child: StatCard(label: 'Egress status', value: 'OPTIMAL', color: AppColors.green)), const SizedBox(width: 12), Expanded(child: StatCard(label: 'Global latency', value: '41.3 ms')), const SizedBox(width: 12), Expanded(child: StatCard(label: 'Aggregated quota', value: '143k / 400k', color: AppColors.amber))]), const SizedBox(height: 20), ..._relays.map((relay) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _RelayCard(relay: relay)))]));
}

const _relays = [('CF-Edge Primary [Frankfurt]', 'gateway.fra.cloudflare-parvaz.net', '22ms', '42,150 / 100,000', AppColors.green), ('CF-Worker Edge [Amsterdam]', 'nl-worker-proxy.edge.workers.dev', '34ms', '89% quota', AppColors.amber), ('CF Enterprise Anycast [London]', 'lon-relay.secure-tunnel.org', '68ms', '1.8% loss', AppColors.amber), ('Backup Tunnel [Helsinki]', 'hel-cf.parvaz-backup.site', 'timeout', 'CF-522', AppColors.red)];

class _RelayCard extends StatelessWidget {
  const _RelayCard({required this.relay});
  final (String, String, String, String, Color) relay;
  @override
  Widget build(BuildContext context) => Panel(child: Row(children: [Icon(Icons.circle, color: relay.$5, size: 11), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(relay.$1, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 5), Mono(relay.$2, color: AppColors.muted)])), Mono(relay.$3, color: relay.$5), const SizedBox(width: 24), Text(relay.$4, style: TextStyle(color: relay.$5)), const SizedBox(width: 18), OutlinedButton(onPressed: () {}, child: const Text('Test')), IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))]));
}

import 'package:flutter/material.dart';

import '../core/relays/relay_models.dart';
import '../core/relays/relay_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class RelaysPage extends StatefulWidget {
  const RelaysPage({required this.strings, this.repository, super.key});
  final AppStrings strings;
  final RelayRepository? repository;

  @override
  State<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends State<RelaysPage> {
  List<RelayConfig> _relays = const <RelayConfig>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = widget.repository;
    if (repository == null) {
      return;
    }
    setState(() => _loading = true);
    final relays = await repository.list();
    if (!mounted) {
      return;
    }
    setState(() {
      _relays = relays;
      _loading = false;
    });
  }

  Future<void> _addRelay() async {
    final repository = widget.repository;
    if (repository == null) {
      return;
    }
    final result = await showDialog<RelayConfig>(
      context: context,
      builder: (context) => const _AddRelayDialog(),
    );
    if (result == null) {
      return;
    }
    await repository.save(result.copyWith(active: _relays.isEmpty));
    if (_relays.isEmpty) {
      await repository.setActive(result.id);
    }
    await _load();
  }

  Future<void> _activate(RelayConfig relay) async {
    await widget.repository?.setActive(relay.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final hasRepository = widget.repository != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Network Orchestration',
            subtitle: s.relaysSubtitle,
            action: FilledButton.icon(
              onPressed: hasRepository ? _addRelay : null,
              icon: const Icon(Icons.add),
              label: Text(s.addRelay),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Egress status',
                  value: hasRepository
                      ? (_relays.isEmpty ? 'EMPTY' : 'CONFIGURED')
                      : 'PREVIEW',
                  color: hasRepository && _relays.isNotEmpty
                      ? AppColors.cyan
                      : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: StatCard(label: 'Global latency', value: '—'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Configured relays',
                  value: hasRepository ? '${_relays.length}' : '—',
                  color: hasRepository && _relays.isNotEmpty
                      ? AppColors.cyan
                      : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (hasRepository && _relays.isEmpty)
            const Panel(
              child: Text(
                'No relay is configured. Add a relay before pressing Connect.',
              ),
            )
          else if (hasRepository)
            ..._relays.map(
              (relay) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RelayCard(
                  relay: relay,
                  onActivate: () => _activate(relay),
                ),
              ),
            )
          else
            ..._mockRelays.map(
              (relay) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MockRelayCard(relay: relay),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddRelayDialog extends StatefulWidget {
  const _AddRelayDialog();
  @override
  State<_AddRelayDialog> createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends State<_AddRelayDialog> {
  final _name = TextEditingController();
  final _host = TextEditingController();
  final _port = TextEditingController(text: '443');
  final _uuid = TextEditingController();
  final _path = TextEditingController(text: '/');

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _uuid.dispose();
    _path.dispose();
    super.dispose();
  }

  void _save() {
    final port = int.tryParse(_port.text.trim());
    if (_name.text.trim().isEmpty ||
        _host.text.trim().isEmpty ||
        _uuid.text.trim().isEmpty ||
        port == null ||
        port < 1 ||
        port > 65535) {
      return;
    }
    Navigator.of(context).pop(
      RelayConfig(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        hostname: _host.text.trim(),
        port: port,
        uuid: _uuid.text.trim(),
        path: _path.text.trim().isEmpty ? '/' : _path.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add relay'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _host,
              decoration: const InputDecoration(labelText: 'Hostname'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _uuid,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'UUID'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _path,
              decoration: const InputDecoration(labelText: 'WebSocket path'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _RelayCard extends StatelessWidget {
  const _RelayCard({required this.relay, required this.onActivate});
  final RelayConfig relay;
  final VoidCallback onActivate;
  @override
  Widget build(BuildContext context) => Panel(
    child: Row(
      children: [
        Icon(
          Icons.circle,
          color: relay.active ? AppColors.green : AppColors.muted,
          size: 11,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(relay.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Mono(
                '${relay.hostname}:${relay.port}${relay.path}',
                color: AppColors.muted,
              ),
            ],
          ),
        ),
        if (relay.active)
          const StatusChip('ACTIVE', color: AppColors.green)
        else
          OutlinedButton(
            onPressed: onActivate,
            child: const Text('Make active'),
          ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      ],
    ),
  );
}

class _MockRelayCard extends StatelessWidget {
  const _MockRelayCard({required this.relay});
  final (String, String, String, String, Color) relay;
  @override
  Widget build(BuildContext context) => Panel(
    child: Row(
      children: [
        Icon(Icons.circle, color: relay.$5, size: 11),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(relay.$1, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Mono(relay.$2, color: AppColors.muted),
            ],
          ),
        ),
        Mono(relay.$3, color: relay.$5),
        const SizedBox(width: 24),
        Text(relay.$4, style: TextStyle(color: relay.$5)),
      ],
    ),
  );
}

const _mockRelays = <(String, String, String, String, Color)>[
  (
    'CF-Edge Primary [Frankfurt]',
    'gateway.fra.cloudflare-parvaz.net',
    '22ms',
    'DEMO',
    AppColors.green,
  ),
  (
    'CF-Worker Edge [Amsterdam]',
    'nl-worker-proxy.edge.workers.dev',
    '34ms',
    'DEMO',
    AppColors.amber,
  ),
];

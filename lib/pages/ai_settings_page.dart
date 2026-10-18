import 'package:flutter/material.dart';

import '../core/diagnostics/ai_client.dart';
import '../core/diagnostics/debug_bundle.dart';
import '../core/failures/failure_code.dart';
import '../core/logging/log_entry.dart';
import '../core/security/secret_store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({required this.strings, this.secrets, super.key});
  final AppStrings strings;
  final SecretStore? secrets;
  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  String _status = 'NOT CONFIGURED';
  bool _busy = false;

  AppStrings get strings => widget.strings;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController(text: 'https://api.openai.com/v1');
    _apiKey = TextEditingController();
    _model = TextEditingController(text: 'gpt-4o-mini');
    _loadKey();
  }

  Future<void> _loadKey() async {
    final value = await widget.secrets?.read(SecretKeys.aiApiKey);
    if (!mounted || value == null) return;
    _apiKey.text = value;
    setState(() => _status = 'CONFIGURED');
  }

  Future<void> _save() async {
    final secrets = widget.secrets;
    if (secrets == null) {
      setState(() => _status = 'PREVIEW ONLY');
      return;
    }
    await secrets.write(SecretKeys.aiApiKey, _apiKey.text.trim());
    if (mounted) {
      setState(
        () =>
            _status = _apiKey.text.trim().isEmpty ? 'NOT CONFIGURED' : 'SAVED',
      );
    }
  }

  Future<void> _testConnection() async {
    final key = _apiKey.text.trim();
    if (key.isEmpty) {
      setState(() => _status = 'NOT CONFIGURED');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'TESTING';
    });
    final client = OpenAiCompatibleClient(
      baseUrl: _baseUrl.text.trim(),
      apiKey: key,
      model: _model.text.trim(),
    );
    try {
      await client.analyze(
        const DebugBundle(
          version: '0.1.0',
          stage: 'ai-connection-test',
          failure: FailureCode.unknown,
          logs: <LogEntry>[],
        ),
      );
      if (mounted) setState(() => _status = 'CONNECTED');
    } on Object {
      if (mounted) setState(() => _status = 'FAILED');
    } finally {
      client.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(title: 'AI Diagnostics', subtitle: strings.aiSubtitle),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inference Provider & Gateway',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: 'OpenAI Compatible',
                decoration: InputDecoration(labelText: strings.provider),
                items: const [
                  DropdownMenuItem(
                    value: 'OpenAI Compatible',
                    child: Text('OpenAI Compatible'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom Proxy',
                    child: Text('Custom Proxy'),
                  ),
                  DropdownMenuItem(
                    value: 'Ollama / vLLM',
                    child: Text('Ollama / vLLM'),
                  ),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _baseUrl,
                decoration: InputDecoration(labelText: strings.baseUrl),
              ),
              const SizedBox(height: 12),
              TextFormField(
                obscureText: true,
                controller: _apiKey,
                decoration: InputDecoration(
                  labelText: strings.apiKey,
                  hintText: '••••••••••••',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _model,
                decoration: InputDecoration(labelText: strings.model),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _testConnection,
                    icon: const Icon(Icons.link),
                    label: Text(strings.testConnection),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(
                    _status,
                    color: _status == 'CONNECTED' || _status == 'SAVED'
                        ? AppColors.green
                        : _status == 'FAILED'
                        ? AppColors.red
                        : AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            children: [
              const ToggleRow(
                title: 'Auto-analyze on connection failure',
                subtitle: 'Run deterministic diagnostics and offer an AI explanation.',
              ),
              ToggleRow(
                title: 'Redact sensitive data before sending',
                subtitle: strings.privacy,
              ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(child: Text(strings.privacy)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(strings.save),
          ),
        ),
      ],
    ),
  );
}

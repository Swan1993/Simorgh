import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class AiSettingsPage extends StatelessWidget {
  const AiSettingsPage({required this.strings, super.key});
  final AppStrings strings;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [PageHeader(title: 'AI Diagnostics', subtitle: strings.aiSubtitle), const SizedBox(height: 20), Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Inference Provider & Gateway', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16), DropdownButtonFormField<String>(value: 'OpenAI Compatible', decoration: InputDecoration(labelText: strings.provider), items: const [DropdownMenuItem(value: 'OpenAI Compatible', child: Text('OpenAI Compatible')), DropdownMenuItem(value: 'Custom Proxy', child: Text('Custom Proxy')), DropdownMenuItem(value: 'Ollama / vLLM', child: Text('Ollama / vLLM'))], onChanged: (_) {}), const SizedBox(height: 12), TextFormField(initialValue: 'https://api.openai.com/v1', decoration: InputDecoration(labelText: strings.baseUrl)), const SizedBox(height: 12), TextFormField(obscureText: true, decoration: InputDecoration(labelText: strings.apiKey, hintText: '••••••••••••')), const SizedBox(height: 12), TextFormField(initialValue: 'gpt-4o-mini', decoration: InputDecoration(labelText: strings.model)), const SizedBox(height: 16), Row(children: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.link), label: Text(strings.testConnection)), const SizedBox(width: 12), const StatusChip('READY', color: AppColors.green)])])), const SizedBox(height: 14), Panel(child: Column(children: [ToggleRow(title: 'Auto-analyze on connection failure', subtitle: 'Run deterministic diagnostics and offer an AI explanation.'), ToggleRow(title: 'Redact sensitive data before sending', subtitle: strings.privacy), const Divider(), Row(children: [const Icon(Icons.lock_outline, color: AppColors.green), const SizedBox(width: 10), Expanded(child: Text(strings.privacy))])])), const SizedBox(height: 14), Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton(onPressed: () {}, child: Text(strings.save)))]));
}

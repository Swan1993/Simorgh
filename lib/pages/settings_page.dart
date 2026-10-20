import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.strings,
    required this.onLocaleChanged,
    super.key,
  });
  final AppStrings strings;
  final ValueChanged<Locale> onLocaleChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: strings.settings,
          subtitle: 'Connection, scanner and desktop preferences',
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.routing,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Material(
                child: RadioGroup<String>(
                  groupValue: 'proxy',
                  onChanged: (_) {},
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        value: 'proxy',
                        title: Text('System Proxy (PAC / HTTP)'),
                        subtitle: Text('Recommended • 127.0.0.1:10809'),
                      ),
                      RadioListTile<String>(
                        value: 'tun',
                        enabled: false,
                        title: Text('TUN Virtual Adapter'),
                        subtitle: Text(
                          'Elevation required',
                          style: TextStyle(color: AppColors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.scanner,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Material(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Parallel probes'),
                  trailing: Mono('64 concurrent'),
                ),
              ),
              Slider(value: 64, min: 8, max: 128, onChanged: (_) {}),
              const Material(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Handshake timeout'),
                  trailing: Mono('450 ms'),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final port in ['443', '8443', '2053', '2083', '2087'])
                    FilterChip(
                      label: Mono(port),
                      selected: port == '443',
                      onSelected: (_) {},
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
              DropdownButtonFormField<String>(
                initialValue: strings.isFa
                    ? 'فارسی'
                    : strings.isHi
                    ? 'हिन्दी'
                    : 'English',
                decoration: InputDecoration(labelText: strings.language),
                items: const [
                  DropdownMenuItem(value: 'فارسی', child: Text('فارسی')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'हिन्दी', child: Text('हिन्दी')),
                ],
                onChanged: (value) {
                  if (value == 'فارسی') {
                    onLocaleChanged(const Locale('fa'));
                  }
                  if (value == 'English') {
                    onLocaleChanged(const Locale('en'));
                  }
                  if (value == 'हिन्दी') {
                    onLocaleChanged(const Locale('hi'));
                  }
                },
              ),
              const ToggleRow(
                title: 'Run at Windows startup',
                subtitle: 'Launch Simorgh when Windows starts.',
                initial: false,
              ),
              const ToggleRow(
                title: 'Minimize to system tray',
                subtitle: 'Keep the tunnel available after closing the window.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

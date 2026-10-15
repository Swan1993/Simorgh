import 'package:flutter/material.dart';

import 'theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      ?action,
    ],
  );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.detail,
    this.color = AppColors.cyan,
    super.key,
  });
  final String label;
  final String value;
  final String? detail;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Mono(value, color: color, size: 18),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
        ],
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {required this.color, super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class ToggleRow extends StatefulWidget {
  const ToggleRow({
    required this.title,
    required this.subtitle,
    this.initial = true,
    super.key,
  });
  final String title;
  final String subtitle;
  final bool initial;
  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  late bool value = widget.initial;
  @override
  Widget build(BuildContext context) => Material(
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: (next) => setState(() => value = next),
      title: Text(widget.title),
      subtitle: Text(
        widget.subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

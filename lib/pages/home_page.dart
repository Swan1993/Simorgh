import 'dart:async';

import 'package:flutter/material.dart';

import '../core/connection/connection_flow.dart';
import '../core/connection/connection_session.dart';
import '../core/failures/failure_code.dart';
import '../core/logging/log_service.dart';
import '../core/scanner/ip_scanner.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../l10n/strings.dart';

enum TunnelState { idle, scanning, connecting, connected, failed }

class HomePage extends StatefulWidget {
  const HomePage({required this.strings, this.connectionSession, super.key});
  final AppStrings strings;
  final ConnectionSession? connectionSession;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TunnelState _state = TunnelState.idle;
  Timer? _timer;
  int _progress = 0;
  int _runId = 0;
  final _defaultRows = <String>[
    '104.16.132.48',
    '104.19.241.93',
    '172.67.12.18',
    '104.28.14.99',
    '162.159.36.1',
  ];
  late List<String> _rows;
  final Map<String, IpProbeResult> _probes = <String, IpProbeResult>{};
  String? _selectedIp;
  FailureCode? _failure;
  String? _sessionMessage;
  ConnectionViewStage _sessionStage = ConnectionViewStage.idle;
  int _testedCount = 0;
  int _totalCount = 0;
  int _cleanCount = 0;
  StreamSubscription<ConnectionViewState>? _sessionSubscription;
  late final LogService _logger;
  late final MockConnectionFlow _flow;
  AppStrings get s => widget.strings;
  bool get _isPreview => widget.connectionSession == null;

  @override
  void initState() {
    super.initState();
    _logger = LogService();
    _flow = MockConnectionFlow(logger: _logger);
    final session = widget.connectionSession;
    _rows = session == null ? List<String>.from(_defaultRows) : <String>[];
    if (session != null) {
      _sessionSubscription = session.states.listen(_onSessionState);
      _onSessionState(session.current);
    }
  }

  void _onSessionState(ConnectionViewState state) {
    if (!mounted) return;
    final nextRows = state.candidates
        .map((item) => item.ip)
        .toSet()
        .toList(growable: false);
    setState(() {
      _sessionStage = state.stage;
      _state = switch (state.stage) {
        ConnectionViewStage.idle => TunnelState.idle,
        ConnectionViewStage.connected => TunnelState.connected,
        ConnectionViewStage.failed => TunnelState.failed,
        ConnectionViewStage.scanning => TunnelState.scanning,
        _ => TunnelState.connecting,
      };
      _progress = state.progress;
      _selectedIp = state.selectedIp;
      _failure = state.failure;
      _sessionMessage = state.message;
      _testedCount = state.testedCount;
      _totalCount = state.totalCount;
      _cleanCount = state.cleanCount;
      _rows = nextRows;
      _probes.clear();
      for (final result in state.candidates) {
        _probes[result.ip] = result;
      }
    });
  }

  void _start() {
    if (_state == TunnelState.scanning || _state == TunnelState.connecting) {
      _cancelConnection();
      return;
    }
    if (_state == TunnelState.connected) {
      _disconnect();
      return;
    }
    final session = widget.connectionSession;
    if (session != null) {
      unawaited(session.connect());
      return;
    }
    _timer?.cancel();
    final runId = ++_runId;
    _flow.transition(ConnectionStage.preparing);
    setState(() {
      _state = TunnelState.scanning;
      _progress = 0;
      _failure = null;
    });
    _flow.transition(ConnectionStage.scanning);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || runId != _runId) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 8;
        if (_progress >= 72 && _progress < 100) {
          _state = TunnelState.connecting;
          _flow.transition(ConnectionStage.startingCore, progress: _progress);
        }
        if (_progress >= 100) {
          _state = TunnelState.connected;
          _flow.transition(ConnectionStage.connected, progress: 100);
          timer.cancel();
        }
      });
    });
  }

  void _cancelConnection() {
    _runId++;
    _timer?.cancel();
    _timer = null;
    final session = widget.connectionSession;
    if (session != null) {
      unawaited(session.disconnect());
    }
    if (!mounted) return;
    _flow.transition(ConnectionStage.idle);
    setState(() {
      _state = TunnelState.idle;
      _progress = 0;
      _failure = null;
    });
  }

  void _disconnect() => _cancelConnection();

  void _fail() {
    _runId++;
    _timer?.cancel();
    _timer = null;
    _flow.fail(
      FailureCode.tlsHandshakeReset,
      'Handshake timed out during the simulated connection.',
    );
    _failure = FailureCode.tlsHandshakeReset;
    setState(() => _state = TunnelState.failed);
  }

  String get _label => switch (_state) {
    TunnelState.idle => s.connect,
    TunnelState.scanning => s.cancel,
    TunnelState.connecting => s.cancel,
    TunnelState.connected => s.disconnect,
    TunnelState.failed => s.failed,
  };
  Color get _color => switch (_state) {
    TunnelState.connected => AppColors.green,
    TunnelState.failed => AppColors.red,
    _ => AppColors.cyan,
  };

  IpProbeResult? get _selectedProbe =>
      _selectedIp == null ? null : _probes[_selectedIp];

  String get _cleanIpValue =>
      _isPreview ? _defaultRows.first : _selectedIp ?? '—';

  String get _latencyValue {
    if (_isPreview) return '24 ms';
    final latency = _selectedProbe?.latencyMs;
    return latency == null ? '—' : '$latency ms';
  }

  String get _latencyDetail => _isPreview ? 'Jitter 1.2ms' : '—';

  String get _connectionSummary {
    if (_state == TunnelState.failed) {
      if (!_isPreview && _sessionMessage != null) return _sessionMessage!;
      return _failure?.messageFor(s.locale.languageCode).title ??
          'Connection failed';
    }
    if (_state == TunnelState.connected) {
      if (_isPreview) return 'Connected to CF Edge • Frankfurt';
      return _selectedIp == null
          ? s.connected
          : '${s.connected} • $_selectedIp';
    }
    return _isPreview ? 'Cloudflare Edge available' : s.standby;
  }

  Color _stageColor(ConnectionViewStage stage) {
    if (_isPreview) return AppColors.green;
    if (_sessionStage == ConnectionViewStage.connected) {
      return AppColors.green;
    }
    if (_sessionStage == stage) return AppColors.cyan;
    if (_sessionStage.index > stage.index &&
        _sessionStage != ConnectionViewStage.failed) {
      return AppColors.green;
    }
    return AppColors.muted;
  }

  @override
  void dispose() {
    _runId++;
    _timer?.cancel();
    _sessionSubscription?.cancel();
    _logger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Column(
            children: [
              if (_isPreview)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final state in TunnelState.values)
                      ChoiceChip(
                        label: Text(state.name.toUpperCase()),
                        selected: state == _state,
                        onSelected: (_) => setState(() => _state = state),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              InkWell(
                key: const ValueKey<String>('connect-orb'),
                onTap: _start,
                borderRadius: BorderRadius.circular(100),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 176,
                  height: 176,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceLow,
                    border: Border.all(color: _color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: .25),
                        blurRadius: 32,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _state == TunnelState.failed
                            ? Icons.warning_rounded
                            : Icons.shield_rounded,
                        color: _color,
                        size: 42,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _label,
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _state == TunnelState.connected
                            ? 'CF-SECURE'
                            : s.standby,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 9, color: _color),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      _connectionSummary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) => GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
                    mainAxisExtent: 132,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  children: [
                    StatCard(
                      label: s.cleanIp,
                      value: _cleanIpValue,
                      detail: _isPreview ? 'v4' : '—',
                      color: _isPreview || _selectedIp != null
                          ? AppColors.cyan
                          : AppColors.muted,
                    ),
                    StatCard(
                      label: s.latency,
                      value: _latencyValue,
                      detail: _latencyDetail,
                      color: _isPreview || _selectedProbe != null
                          ? AppColors.green
                          : AppColors.muted,
                    ),
                    StatCard(
                      label: s.transfer,
                      value: _isPreview ? '48.2 MB/s' : '—',
                      detail: _isPreview ? '↓ 48.2  ↑ 12.4' : '—',
                      color: _isPreview ? AppColors.cyan : AppColors.muted,
                    ),
                    StatCard(
                      label: s.totalPayload,
                      value: _isPreview ? '1.84 GB' : '—',
                      detail: _isPreview ? '/ 420 MB' : '—',
                      color: _isPreview ? AppColors.cyan : AppColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(s.forceRescan),
                  ),
                  if (_isPreview) ...[
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Switch Relay'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _fail,
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Force Fail'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: s.scannerTitle,
                subtitle: s.scannerSubtitle,
                action: OutlinedButton.icon(
                  key: const ValueKey<String>('cancel-scan'),
                  onPressed:
                      _state == TunnelState.scanning ||
                          _state == TunnelState.connecting
                      ? _cancelConnection
                      : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(s.cancel),
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: (_progress.clamp(0, 100) / 100).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Mono(
                    '$_progress%',
                    key: const ValueKey<String>('scan-progress'),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _isPreview
                          ? '1,720 / 2,500 ${s.tested}  •  42 ${s.cleanFound}'
                          : '$_testedCount / $_totalCount ${s.tested}  •  $_cleanCount ${s.cleanFound}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in [
                    (stage: ConnectionViewStage.preparing, label: s.prepare),
                    (stage: ConnectionViewStage.scanning, label: s.scanIps),
                    (
                      stage: ConnectionViewStage.selectingBest,
                      label: s.selectBest,
                    ),
                    (
                      stage: ConnectionViewStage.buildingConfig,
                      label: s.buildConfig,
                    ),
                    (
                      stage: ConnectionViewStage.startingCore,
                      label: s.startCore,
                    ),
                    (
                      stage: ConnectionViewStage.verifyingConnection,
                      label: s.verify,
                    ),
                  ])
                    StatusChip(item.label, color: _stageColor(item.stage)),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _rows.length; i++)
                _IpRow(
                  ip: _rows[i],
                  latency: _isPreview
                      ? '${_probes[_rows[i]]?.latencyMs ?? 24 + i * 7}ms'
                      : _probes[_rows[i]] == null
                      ? '—'
                      : '${_probes[_rows[i]]!.latencyMs}ms',
                  clean: _isPreview
                      ? _probes[_rows[i]]?.isClean ?? i < 3
                      : _probes[_rows[i]]?.isClean ?? false,
                  best: _isPreview
                      ? _selectedIp == null
                            ? i == 0
                            : _selectedIp == _rows[i]
                      : _selectedIp == _rows[i],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IpRow extends StatelessWidget {
  const _IpRow({
    required this.ip,
    required this.latency,
    required this.clean,
    required this.best,
  });
  final String ip;
  final String latency;
  final bool clean;
  final bool best;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
    decoration: BoxDecoration(
      color: best ? AppColors.cyan.withValues(alpha: .08) : Colors.transparent,
      border: const Border(bottom: BorderSide(color: AppColors.outline)),
    ),
    child: Row(
      children: [
        if (best)
          const Icon(Icons.star_rounded, size: 16, color: AppColors.amber)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Expanded(child: Mono(ip, color: best ? AppColors.cyan : null)),
        Mono(latency, color: AppColors.muted),
        const SizedBox(width: 18),
        StatusChip(
          clean ? 'CLEAN' : 'BLOCKED',
          color: clean ? AppColors.green : AppColors.red,
        ),
      ],
    ),
  );
}

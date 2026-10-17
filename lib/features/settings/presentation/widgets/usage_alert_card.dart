import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../services/locale_controller.dart';
import '../../../../services/usage_alert_service.dart';

class UsageAlertCard extends ConsumerStatefulWidget {
  const UsageAlertCard({super.key});

  @override
  ConsumerState<UsageAlertCard> createState() => _UsageAlertCardState();
}

class _UsageAlertCardState extends ConsumerState<UsageAlertCard>
    with WidgetsBindingObserver {
  bool _supported = false;
  bool _enabled = false;
  bool _notificationsAllowed = false;
  bool _usageAccessAllowed = false;
  bool _loading = true;
  bool _busy = false;
  bool _waitingForUsageAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh(fromResume: true);
    }
  }

  Future<void> _refresh({bool fromResume = false}) async {
    final service = ref.read(usageAlertServiceProvider);
    final supported = await service.isSupported;
    if (!supported) {
      if (mounted) {
        setState(() {
          _supported = false;
          _loading = false;
        });
      }
      return;
    }

    final values = await Future.wait<bool>([
      service.isEnabled,
      service.hasNotificationPermission,
      service.hasUsageAccess,
    ]);
    if (!mounted) return;

    final waiting = fromResume && _waitingForUsageAccess;
    setState(() {
      _supported = true;
      _enabled = values[0];
      _notificationsAllowed = values[1];
      _usageAccessAllowed = values[2];
      _loading = false;
      if (waiting) _waitingForUsageAccess = false;
    });

    if (waiting) {
      if (_notificationsAllowed && _usageAccessAllowed) {
        await _activate();
      } else {
        _showMessage(ref.read(stringsProvider).phoneUsageAlertOpenUsageSettings);
      }
    }
  }

  Future<void> _onChanged(bool enable) async {
    final service = ref.read(usageAlertServiceProvider);
    if (!enable) {
      setState(() => _busy = true);
      await service.disable();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _busy = false;
      });
      return;
    }

    setState(() => _busy = true);
    final notificationAllowed =
        await service.requestNotificationPermission();
    if (!mounted) return;
    if (!notificationAllowed) {
      setState(() {
        _notificationsAllowed = false;
        _busy = false;
      });
      final strings = ref.read(stringsProvider);
      _showMessage(
        strings.phoneUsageAlertNotificationDenied,
        action: SnackBarAction(
          label: strings.openAppSettings,
          onPressed: () =>
              unawaited(service.openNotificationSettings()),
        ),
      );
      return;
    }

    final usageAccessAllowed = await service.hasUsageAccess;
    if (!mounted) return;
    setState(() => _notificationsAllowed = true);
    if (!usageAccessAllowed) {
      // Set this before launching Settings so a fast app-resume event cannot
      // race the permission flow.
      setState(() => _waitingForUsageAccess = true);
      final opened = await service.openUsageAccessSettings();
      if (!mounted) return;
      setState(() => _busy = false);
      if (opened) {
        _showMessage(
          ref.read(stringsProvider).phoneUsageAlertOpenUsageSettings,
        );
      } else {
        setState(() => _waitingForUsageAccess = false);
        _showMessage(ref.read(stringsProvider).phoneUsageAlertPermissionError);
      }
      return;
    }
    await _activate();
  }

  Future<void> _activate() async {
    setState(() => _busy = true);
    final enabled =
        await ref.read(usageAlertServiceProvider).enable(thresholdMinutes: 240);
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _busy = false;
      _waitingForUsageAccess = false;
      if (enabled) _usageAccessAllowed = true;
    });
    final strings = ref.read(stringsProvider);
    _showMessage(
      enabled
          ? strings.phoneUsageAlertEnabled
          : strings.phoneUsageAlertPermissionError,
    );
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final statusStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
          height: 1.4,
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.mint,
            ),
            title: Text(strings.phoneUsageAlertTitle),
            subtitle: Text(strings.phoneUsageAlertDescription),
            value: _enabled,
            activeThumbColor: AppColors.mint,
            onChanged:
                _loading || _busy || !_supported ? null : _onChanged,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_loading)
            Text(
              strings.isArabic
                  ? 'جارٍ التحقق من الصلاحيات…'
                  : 'Checking permissions…',
              style: statusStyle,
            )
          else if (!_supported)
            Text(strings.phoneUsageAlertAndroidOnly, style: statusStyle)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.notificationPermissionStatus(
                    _notificationsAllowed,
                  ),
                  style: statusStyle,
                ),
                Text(
                  strings.usageAccessPermissionStatus(_usageAccessAllowed),
                  style: statusStyle,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../services/working_hours_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar_helper.dart';

typedef HorairesScreen = WorkingHoursScreen;
typedef ScheduleScreen = WorkingHoursScreen;

class WorkingHoursScreen extends StatefulWidget {
  final WorkingHoursService? workingHoursService;
  final VoidCallback? onHoursChanged;
  final bool isEmbedded;

  const WorkingHoursScreen({
    super.key,
    this.workingHoursService,
    this.onHoursChanged,
    this.isEmbedded = false,
  });

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  late final WorkingHoursService _workingHoursService;
  bool _hoursLoading = true;
  String? _hoursLoadError;

  @override
  void initState() {
    super.initState();
    _workingHoursService = widget.workingHoursService ?? WorkingHoursService();
    if (_workingHoursService.isLoaded) {
      _hoursLoading = false;
    } else {
      _loadWorkingHours();
    }
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      _hoursLoading = true;
      _hoursLoadError = null;
    });
    try {
      await _workingHoursService.load();
      if (mounted) setState(() => _hoursLoading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _hoursLoading = false;
          _hoursLoadError = error.toString();
        });
      }
    }
  }

  Future<void> _updateWorkingHours(
      int day, DailyWorkingHours updatedHours) async {
    try {
      await _workingHoursService.updateDay(day, updatedHours);
      if (mounted) {
        setState(() {});
        widget.onHoursChanged?.call();
        AppSnackBar.showSuccess(
          context,
          '${WorkingHoursService.weekdays[day - 1]} enregistré.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Impossible d\'enregistrer les horaires : $error',
        );
      }
    }
  }

  Future<void> _selectWorkingTime(int day, {required bool isStart}) async {
    final current = _workingHoursService.hours[day]!;
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? current.start : current.end,
      helpText: isStart ? 'Début du service' : 'Fin du service',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (selected == null || !mounted) return;

    final updated = current.copyWith(
      start: isStart ? selected : null,
      end: isStart ? null : selected,
    );
    final startMinute = updated.start.hour * 60 + updated.start.minute;
    final endMinute = updated.end.hour * 60 + updated.end.minute;
    if (updated.enabled && endMinute <= startMinute) {
      AppSnackBar.showWarning(
        context,
        'L\'heure de fin doit être après l\'heure de début.',
      );
      return;
    }
    await _updateWorkingHours(day, updated);
  }

  Widget _buildDaySchedule(BuildContext context, int day) {
    final hours = _workingHoursService.hours[day]!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: Text(
                  WorkingHoursService.weekdays[day - 1],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                subtitle: Text(
                  hours.enabled ? 'Jour travaillé' : 'Jour de repos',
                  style: TextStyle(
                    color: hours.enabled
                        ? AppColors.primary
                        : colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: hours.enabled,
                onChanged: (enabled) =>
                    _updateWorkingHours(day, hours.copyWith(enabled: enabled)),
              ),
              AnimatedSize(
                duration: AppDurations.medium,
                curve: AppCurves.smooth,
                child: hours.enabled
                    ? Column(
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: ValueKey('start-time-$day'),
                                  onPressed: () =>
                                      _selectWorkingTime(day, isStart: true),
                                  icon: const Icon(Icons.login_rounded,
                                      size: 16),
                                  label: Text(
                                      'Début  ${hours.start.format(context)}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.md),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: ValueKey('end-time-$day'),
                                  onPressed: () =>
                                      _selectWorkingTime(day, isStart: false),
                                  icon: const Icon(Icons.logout_rounded,
                                      size: 16),
                                  label: Text(
                                      'Fin  ${hours.end.format(context)}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.md),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    if (_hoursLoading && !_workingHoursService.isLoaded) {
      body = const Center(
        key: ValueKey('working-hours-loading'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Chargement des horaires…'),
          ],
        ),
      );
    } else if (_hoursLoadError != null) {
      body = Center(
        key: const ValueKey('working-hours-error'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Impossible de charger vos horaires.',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_hoursLoadError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadWorkingHours,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    } else {
      final now = DateTime.now();
      final isWorking = _workingHoursService.isWorkingAt(now);
      final todaysHours = _workingHoursService.hours[now.weekday]!;
      final todayRange = todaysHours.enabled
          ? '${todaysHours.start.format(context)} – ${todaysHours.end.format(context)}'
          : 'Jour de repos';

      body = ListView(
        key: const ValueKey('working-hours-page'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        children: [
          Text(
            'Organisez votre semaine',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces horaires vous aident à décider d\'accepter une commande.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedText,
                ),
          ),
          const SizedBox(height: 16),

          // Statut du jour (carte avec indicateur actif)
          AnimatedContainer(
            duration: AppDurations.medium,
            decoration: BoxDecoration(
              color: isWorking
                  ? AppColors.primarySoft
                  : (isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.surfaceAlt),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isWorking
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.soft(),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isWorking ? AppColors.primary : AppColors.accent)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWorking
                      ? Icons.work_history_rounded
                      : Icons.event_busy_rounded,
                  color: isWorking ? AppColors.primary : AppColors.accent,
                ),
              ),
              title: Text(
                isWorking ? 'En service' : 'Hors de vos horaires',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isWorking ? AppColors.primary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text('Aujourd\'hui : $todayRange'),
            ),
          ),
          const SizedBox(height: 20),

          for (var day = 1; day <= 7; day++) _buildDaySchedule(context, day),

          const SizedBox(height: 12),
          Text(
            'Défaut : lundi–vendredi 9 h–17 h. Enregistré sur cet appareil. '
            'Suggère uniquement – vous gardez le choix.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes horaires'),
      ),
      body: body,
    );
  }
}

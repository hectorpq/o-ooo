import 'package:flutter/material.dart';

typedef TimeChanged = ValueChanged<int>;

class NotificationConfigWidget extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final TimeChanged onTimeChange;
  final int selectedTime;
  final String title;
  final List<int> timeOptions;
  final String? subtitle;

  const NotificationConfigWidget({
    Key? key,
    required this.isActive,
    required this.onToggle,
    required this.onTimeChange,
    required this.selectedTime,
    this.title = 'Configuración de notificaciones',
    this.subtitle,
    this.timeOptions = const [5, 15, 30, 60],
  }) : assert(timeOptions.length > 0),
       super(key: key);

  String _labelForMinutes(int minutes) {
    if (minutes == 60) return '1 hora antes';
    if (minutes == 1) return '1 minuto antes';
    return '$minutes minutos antes';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleTitle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final textStyleSubtitle = theme.textTheme.bodySmall;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  semanticLabel: 'Icono notificaciones',
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: textStyleTitle)),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const SizedBox.shrink(),
                  value: isActive,
                  onChanged: onToggle,
                  secondary: Tooltip(
                    message: isActive ? 'Activado' : 'Desactivado',
                    child: Icon(isActive ? Icons.toggle_on : Icons.toggle_off),
                  ),
                ),
              ],
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: textStyleSubtitle),
            ],

            const SizedBox(height: 12),

            // Animated area that shows time-related controls only when active
            AnimatedCrossFade(
              crossFadeState: isActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 220),
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notificar:', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Semantics(
                    container: true,
                    label: 'Seleccionar cuántos minutos antes notificar',
                    child: DropdownButtonFormField<int>(
                      value: timeOptions.contains(selectedTime)
                          ? selectedTime
                          : timeOptions.first,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      items: timeOptions
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m,
                              child: Text(_labelForMinutes(m)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onTimeChange(value);
                      },
                    ),
                  ),
                ],
              ),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Las notificaciones están desactivadas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

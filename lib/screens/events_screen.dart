// lib/screens/events_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/evento.dart';
import '../providers/event_provider.dart';
import '../providers/theme_provider.dart';

typedef EventoCallback = void Function(Evento evento);
typedef EventoEditCallback = void Function(int index, Evento evento);
typedef EventoDeleteCallback = void Function(int index);

class EventsScreen extends StatefulWidget {
  final List<Evento> eventos;
  final EventoCallback onAddEvento;
  final EventoEditCallback? onEditEvento;
  final EventoDeleteCallback? onDeleteEvento;

  const EventsScreen({
    super.key,
    required this.eventos,
    required this.onAddEvento,
    this.onEditEvento,
    this.onDeleteEvento,
    required Future<void> Function(String eventoId, int minutes)
    onUpdateNotificationTime,
    required Future<void> Function(String eventoId) onToggleNotification,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with TickerProviderStateMixin {
  String _search = '';
  int _filterIndex = 0; // 0 = All, 1 = Upcoming, 2 = Past
  bool _ascending = true;
  final _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fabAnimationController.forward();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  List<Evento> get _filtered {
    final now = DateTime.now();
    Iterable<Evento> list = widget.eventos;

    // search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where(
        (e) =>
            e.titulo.toLowerCase().contains(q) ||
            e.descripcion.toLowerCase().contains(q) ||
            DateFormat('dd/MM/yyyy').format(e.fecha).contains(q),
      );
    }

    // filter
    if (_filterIndex == 1) {
      list = list.where(
        (e) => e.fecha.isAfter(now) || e.fecha.isAtSameMomentAs(now),
      );
    } else if (_filterIndex == 2) {
      list = list.where((e) => e.fecha.isBefore(now));
    }

    // sort
    final sorted = list.toList()
      ..sort(
        (a, b) => _ascending
            ? a.fecha.compareTo(b.fecha)
            : b.fecha.compareTo(a.fecha),
      );
    return sorted;
  }

  Future<void> _showCreateOrEditDialog({
    Evento? initial,
    int? editingIndex,
  }) async {
    final tituloCtrl = TextEditingController(text: initial?.titulo ?? '');
    final descCtrl = TextEditingController(text: initial?.descripcion ?? '');
    DateTime fecha =
        initial?.fecha ?? DateTime.now().add(const Duration(hours: 1));
    TimeOfDay time = TimeOfDay.fromDateTime(fecha);

    bool notificacionActiva = initial?.notificacionActiva ?? true;
    int minutosAntes = initial?.minutosAntes ?? 15;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                String fechaTxt() => DateFormat('dd/MM/yyyy').format(fecha);
                String horaTxt() => time.format(context);
                return TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.7 + (0.3 * value),
                      child: Opacity(
                        opacity: value,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 10,
                          backgroundColor: themeProvider.isDarkMode
                              ? themeProvider.cardBackgroundColor
                              : Colors.white,
                          title: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: themeProvider.isDarkMode
                                  ? LinearGradient(
                                      colors: themeProvider
                                          .backgroundGradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.deepPurple.shade400,
                                        Colors.blue.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                initial == null
                                    ? 'Nuevo evento'
                                    : 'Editar evento',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAnimatedTextField(
                                  controller: tituloCtrl,
                                  label: 'Título',
                                  icon: Icons.title,
                                  delay: 100,
                                  themeProvider: themeProvider,
                                ),
                                const SizedBox(height: 16),
                                _buildAnimatedTextField(
                                  controller: descCtrl,
                                  label: 'Descripción',
                                  icon: Icons.description,
                                  maxLines: 3,
                                  delay: 200,
                                  themeProvider: themeProvider,
                                ),
                                const SizedBox(height: 20),
                                _buildDateTimeSelector(
                                  'Fecha',
                                  fechaTxt(),
                                  Icons.calendar_month,
                                  () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: fecha,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                                themeProvider.isDarkMode
                                                ? ColorScheme.dark(
                                                    primary: const Color(
                                                      0xFF6C757D,
                                                    ),
                                                    onPrimary: Colors.white,
                                                    surface: themeProvider
                                                        .cardBackgroundColor,
                                                    onSurface: Colors.white,
                                                  )
                                                : ColorScheme.light(
                                                    primary: Colors
                                                        .deepPurple
                                                        .shade400,
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(
                                        () => fecha = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          fecha.hour,
                                          fecha.minute,
                                        ),
                                      );
                                    }
                                  },
                                  delay: 300,
                                  themeProvider: themeProvider,
                                ),
                                const SizedBox(height: 12),
                                _buildDateTimeSelector(
                                  'Hora',
                                  horaTxt(),
                                  Icons.access_time,
                                  () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: time,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme:
                                                themeProvider.isDarkMode
                                                ? ColorScheme.dark(
                                                    primary: const Color(
                                                      0xFF6C757D,
                                                    ),
                                                    onPrimary: Colors.white,
                                                    surface: themeProvider
                                                        .cardBackgroundColor,
                                                    onSurface: Colors.white,
                                                  )
                                                : ColorScheme.light(
                                                    primary: Colors
                                                        .deepPurple
                                                        .shade400,
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.black,
                                                  ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        time = picked;
                                        fecha = DateTime(
                                          fecha.year,
                                          fecha.month,
                                          fecha.day,
                                          picked.hour,
                                          picked.minute,
                                        );
                                      });
                                    }
                                  },
                                  delay: 400,
                                  themeProvider: themeProvider,
                                ),
                                const SizedBox(height: 20),
                                _buildNotificationSection(
                                  notificacionActiva: notificacionActiva,
                                  minutosAntes: minutosAntes,
                                  onNotificacionChanged: (value) {
                                    setState(() {
                                      notificacionActiva = value;
                                    });
                                  },
                                  onMinutosChanged: (value) {
                                    setState(() {
                                      minutosAntes = value;
                                    });
                                  },
                                  themeProvider: themeProvider,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.secondaryTextColor
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final t = tituloCtrl.text.trim();
                                  final d = descCtrl.text.trim();
                                  if (t.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(
                                              Icons.warning,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text('El título es obligatorio'),
                                          ],
                                        ),
                                        backgroundColor: Colors.orange.shade600,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final nuevo = Evento(
                                    titulo: t,
                                    descripcion: d,
                                    fecha: fecha,
                                    id: initial?.id ?? '',
                                    uid: initial?.uid ?? '',
                                    notificacionActiva: notificacionActiva,
                                    minutosAntes: minutosAntes,
                                  );
                                  if (initial == null) {
                                    widget.onAddEvento(nuevo);
                                  } else {
                                    if (editingIndex != null &&
                                        widget.onEditEvento != null) {
                                      widget.onEditEvento!(editingIndex, nuevo);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Editar no conectado al padre',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Guardar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationSection({
    required bool notificacionActiva,
    required int minutosAntes,
    required ValueChanged<bool> onNotificacionChanged,
    required ValueChanged<int> onMinutosChanged,
    required ThemeProvider themeProvider,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? null
                    : LinearGradient(
                        colors: [Colors.orange.shade50, Colors.pink.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: themeProvider.isDarkMode
                    ? themeProvider.cardBackgroundColor
                    : null,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: themeProvider.isDarkMode
                      ? themeProvider.cardBorderColor
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF6C757D)
                            : Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? themeProvider.primaryTextColor
                              : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: notificacionActiva,
                        onChanged: onNotificacionChanged,
                        activeColor: themeProvider.isDarkMode
                            ? const Color(0xFF6C757D)
                            : Colors.orange.shade600,
                      ),
                    ],
                  ),
                  if (notificacionActiva) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Recordar evento:',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFFB0BEC5)
                            : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [5, 15, 30, 60].map((minutos) {
                        final isSelected = minutosAntes == minutos;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            minutos < 60
                                ? '$minutos min antes'
                                : '${minutos ~/ 60}h antes',
                            style: TextStyle(
                              color: isSelected
                                  ? (themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.orange.shade700)
                                  : (themeProvider.isDarkMode
                                        ? const Color(0xFFB0BEC5)
                                        : Colors.grey.shade600),
                            ),
                          ),
                          onSelected: (_) => onMinutosChanged(minutos),
                          selectedColor: themeProvider.isDarkMode
                              ? const Color(0xFF6C757D)
                              : Colors.orange.shade100,
                          backgroundColor: themeProvider.isDarkMode
                              ? themeProvider.cardBackgroundColor
                              : Colors.grey.shade100,
                          checkmarkColor: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.orange.shade700,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int delay = 0,
    required ThemeProvider themeProvider,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? themeProvider.cardBorderColor.withOpacity(0.3)
                        : Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? themeProvider.primaryTextColor
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode
                        ? const Color(0xFFB0BEC5)
                        : Colors.grey.shade600,
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: themeProvider.isDarkMode
                        ? const Color(0xFF6C757D)
                        : Colors.deepPurple.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: themeProvider.isDarkMode
                      ? themeProvider.cardBackgroundColor
                      : Colors.grey.shade50,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF6C757D)
                          : Colors.deepPurple.shade400,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateTimeSelector(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap, {
    int delay = 0,
    required ThemeProvider themeProvider,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? null
                    : LinearGradient(
                        colors: [Colors.blue.shade50, Colors.purple.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: themeProvider.isDarkMode
                    ? themeProvider.cardBackgroundColor
                    : null,
                borderRadius: BorderRadius.circular(15),
                border: themeProvider.isDarkMode
                    ? Border.all(color: themeProvider.cardBorderColor)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? themeProvider.cardBorderColor.withOpacity(0.3)
                        : Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF6C757D)
                              : Colors.deepPurple.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? const Color(0xFFB0BEC5)
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.primaryTextColor
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFFB0BEC5)
                              : Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Evento ev, ThemeProvider themeProvider) {
    final idx = widget.eventos.indexOf(ev);
    showDialog(
      context: context,
      builder: (_) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: themeProvider.isDarkMode
                    ? themeProvider.cardBackgroundColor
                    : Colors.white,
                title: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade400, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Eliminar evento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? themeProvider.primaryTextColor
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                content: Text(
                  '¿Seguro que deseas eliminar este evento?',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? themeProvider.primaryTextColor
                        : Colors.black,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? themeProvider.secondaryTextColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (idx != -1) {
                          if (widget.onDeleteEvento != null) {
                            widget.onDeleteEvento!(idx);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Eliminar no conectado al padre'),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(Evento ev, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? themeProvider.cardBackgroundColor
                : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? themeProvider.secondaryTextColor.withOpacity(0.3)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: themeProvider.isDarkMode
                        ? LinearGradient(
                            colors: themeProvider.backgroundGradientColors
                                .take(2)
                                .toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.titulo,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy – HH:mm').format(ev.fecha),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? themeProvider.cardBackgroundColor
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: themeProvider.isDarkMode
                          ? themeProvider.cardBorderColor
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF6C757D)
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode
                                  ? themeProvider.primaryTextColor
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ev.descripcion.isEmpty
                            ? 'Sin descripción'
                            : ev.descripcion,
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.isDarkMode
                              ? themeProvider.primaryTextColor
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ev.notificacionActiva) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.orange.shade900.withOpacity(0.3)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? Colors.orange.shade700
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notificación: ${ev.textoTiempoNotificacion}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode
                                ? Colors.orange.shade400
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final idx = widget.eventos.indexOf(ev);
                            if (idx != -1) {
                              _showCreateOrEditDialog(
                                initial: ev,
                                editingIndex: idx,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(ev, themeProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.isDarkMode
              ? null
              : LinearGradient(
                  colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: themeProvider.isDarkMode
              ? themeProvider.cardBackgroundColor.withOpacity(0.1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode
                                ? themeProvider.cardBorderColor.withOpacity(0.3)
                                : Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? themeProvider.primaryTextColor
                              : Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF6C757D)
                                : Colors.deepPurple.shade400,
                          ),
                          hintText: 'Buscar título, descripción o fecha',
                          hintStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFB0BEC5)
                                : Colors.grey.shade500,
                          ),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: themeProvider.isDarkMode
                                        ? const Color(0xFFB0BEC5)
                                        : Colors.grey.shade500,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _search = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: themeProvider.isDarkMode
                              ? themeProvider.cardBackgroundColor
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: themeProvider.isDarkMode
                          ? LinearGradient(
                              colors: themeProvider.backgroundGradientColors
                                  .take(2)
                                  .toList(),
                            )
                          : LinearGradient(
                              colors: [
                                Colors.deepPurple.shade400,
                                Colors.blue.shade400,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? themeProvider.cardBorderColor.withOpacity(0.3)
                              : Colors.deepPurple.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _ascending = !_ascending),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _ascending
                                ? Icons.sort_by_alpha
                                : Icons.sort_by_alpha_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? themeProvider.cardBackgroundColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.isDarkMode
                              ? themeProvider.cardBorderColor.withOpacity(0.3)
                              : Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(15),
                      selectedBorderColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      fillColor: Colors.transparent,
                      selectedColor: Colors.white,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFFB0BEC5)
                          : Colors.grey.shade600,
                      constraints: const BoxConstraints(
                        minHeight: 45,
                        minWidth: 70,
                      ),
                      isSelected: [
                        _filterIndex == 0,
                        _filterIndex == 1,
                        _filterIndex == 2,
                      ],
                      onPressed: (index) =>
                          setState(() => _filterIndex = index),
                      children: [
                        Container(
                          decoration: _filterIndex == 0
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade600,
                                      Colors.grey.shade700,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: const Text(
                            'Todos',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          decoration: _filterIndex == 1
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: const Text(
                            'Próximos',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          decoration: _filterIndex == 2
                              ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: const Text(
                            'Pasados',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateOrEditDialog(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Nuevo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? themeProvider.cardBackgroundColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.isDarkMode
                                  ? themeProvider.cardBorderColor.withOpacity(
                                      0.3,
                                    )
                                  : Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() {}),
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.refresh,
                                color: themeProvider.isDarkMode
                                    ? const Color(0xFF6C757D)
                                    : Colors.deepPurple.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Evento ev, ThemeProvider themeProvider) {
    final isPast = ev.fecha.isBefore(DateTime.now());
    final day = DateFormat('dd').format(ev.fecha);
    final month = DateFormat('MMM').format(ev.fecha);
    final time = DateFormat('HH:mm').format(ev.fecha);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Dismissible(
              key: ValueKey(ev.hashCode),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, color: Colors.white, size: 32),
                    Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              confirmDismiss: (_) async {
                final idx = widget.eventos.indexOf(ev);
                if (idx != -1) {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (_) => TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Opacity(
                            opacity: value,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: themeProvider.isDarkMode
                                  ? themeProvider.cardBackgroundColor
                                  : Colors.white,
                              title: Text(
                                'Eliminar',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.primaryTextColor
                                      : Colors.black,
                                ),
                              ),
                              content: Text(
                                '¿Deseas eliminar este evento?',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.primaryTextColor
                                      : Colors.black,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? themeProvider.secondaryTextColor
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade400,
                                        Colors.red.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: const Text(
                                      'Sí',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                  if (result ?? false) {
                    if (widget.onDeleteEvento != null) {
                      widget.onDeleteEvento!(idx);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Eliminar no conectado al padre'),
                        ),
                      );
                    }
                    return true;
                  }
                }
                return false;
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? themeProvider.cardBackgroundColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode
                          ? themeProvider.cardBorderColor.withOpacity(0.3)
                          : isPast
                          ? Colors.grey.shade200
                          : Colors.blue.shade100,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDetail(ev, themeProvider),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: isPast
                                  ? LinearGradient(
                                      colors: themeProvider.isDarkMode
                                          ? [
                                              themeProvider.secondaryTextColor,
                                              themeProvider.secondaryTextColor
                                                  .withOpacity(0.7),
                                            ]
                                          : [
                                              Colors.grey.shade300,
                                              Colors.grey.shade400,
                                            ],
                                    )
                                  : themeProvider.isDarkMode
                                  ? LinearGradient(
                                      colors: themeProvider
                                          .backgroundGradientColors
                                          .take(2)
                                          .toList(),
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.purple.shade400,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.cardBorderColor
                                            .withOpacity(0.3)
                                      : isPast
                                      ? Colors.grey.shade200
                                      : Colors.blue.shade200,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  day,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  month.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ev.titulo,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: themeProvider.isDarkMode
                                              ? themeProvider.primaryTextColor
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        ev.notificacionActiva
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: ev.notificacionActiva
                                            ? Colors.orange.shade600
                                            : (themeProvider.isDarkMode
                                                  ? const Color(0xFFB0BEC5)
                                                  : Colors.grey.shade400),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        Provider.of<EventProvider>(
                                          context,
                                          listen: false,
                                        ).toggleNotificacion(ev.id);
                                      },
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ev.descripcion.isEmpty
                                      ? 'Sin descripción'
                                      : ev.descripcion,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode
                                        ? const Color(0xFFB0BEC5)
                                        : Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isPast
                                            ? LinearGradient(
                                                colors: themeProvider.isDarkMode
                                                    ? [
                                                        Colors.grey.shade800,
                                                        Colors.grey.shade700,
                                                      ]
                                                    : [
                                                        Colors.grey.shade100,
                                                        Colors.grey.shade200,
                                                      ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  Colors.green.shade100,
                                                  Colors.green.shade200,
                                                ],
                                              ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPast
                                                ? Icons.history
                                                : Icons.schedule,
                                            size: 16,
                                            color: isPast
                                                ? (themeProvider.isDarkMode
                                                      ? const Color(0xFFB0BEC5)
                                                      : Colors.grey.shade600)
                                                : Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPast ? 'Pasado' : 'Próximo',
                                            style: TextStyle(
                                              color: isPast
                                                  ? (themeProvider.isDarkMode
                                                        ? const Color(
                                                            0xFFB0BEC5,
                                                          )
                                                        : Colors.grey.shade600)
                                                  : Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (ev.notificacionActiva && !isPast) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: themeProvider.isDarkMode
                                              ? Colors.orange.shade900
                                                    .withOpacity(0.3)
                                              : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.notification_add,
                                              size: 12,
                                              color: Colors.orange.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${ev.minutosAntes}min',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? themeProvider.cardBackgroundColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: themeProvider.isDarkMode
                                    ? const Color(0xFFB0BEC5)
                                    : Colors.grey.shade600,
                              ),
                              color: themeProvider.isDarkMode
                                  ? themeProvider.cardBackgroundColor
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              onSelected: (v) {
                                if (v == 'edit') {
                                  final idx = widget.eventos.indexOf(ev);
                                  if (idx != -1) {
                                    _showCreateOrEditDialog(
                                      initial: ev,
                                      editingIndex: idx,
                                    );
                                  }
                                } else if (v == 'delete') {
                                  _confirmDelete(ev, themeProvider);
                                } else if (v == 'notification') {
                                  _showNotificationDialog(ev, themeProvider);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'notification',
                                  child: Row(
                                    children: [
                                      Icon(
                                        ev.notificacionActiva
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: Colors.orange.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Notificación',
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode
                                              ? themeProvider.primaryTextColor
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Editar',
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode
                                              ? themeProvider.primaryTextColor
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode
                                              ? themeProvider.primaryTextColor
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotificationDialog(
    Evento evento,
    ThemeProvider themeProvider,
  ) async {
    int minutosAntes = evento.minutosAntes;
    bool notificacionActiva = evento.notificacionActiva;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: themeProvider.isDarkMode
                          ? themeProvider.cardBackgroundColor
                          : Colors.white,
                      title: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Configurar notificación',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Activar notificación:',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? themeProvider.primaryTextColor
                                      : Colors.black,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: notificacionActiva,
                                onChanged: (value) {
                                  setState(() {
                                    notificacionActiva = value;
                                  });
                                },
                                activeColor: Colors.orange.shade600,
                              ),
                            ],
                          ),
                          if (notificacionActiva) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Tiempo de anticipación:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode
                                    ? themeProvider.primaryTextColor
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [5, 15, 30, 60, 120].map((minutos) {
                                final isSelected = minutosAntes == minutos;
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    minutos < 60
                                        ? '$minutos min'
                                        : '${minutos ~/ 60}h',
                                    style: TextStyle(
                                      color: isSelected
                                          ? (themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.orange.shade700)
                                          : (themeProvider.isDarkMode
                                                ? const Color(0xFFB0BEC5)
                                                : Colors.grey.shade600),
                                    ),
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      minutosAntes = minutos;
                                    });
                                  },
                                  selectedColor: themeProvider.isDarkMode
                                      ? const Color(0xFF6C757D)
                                      : Colors.orange.shade100,
                                  backgroundColor: themeProvider.isDarkMode
                                      ? themeProvider.cardBackgroundColor
                                      : Colors.grey.shade100,
                                  checkmarkColor: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.orange.shade700,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? themeProvider.secondaryTextColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade600,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final eventoActualizado = evento.copyWith(
                                notificacionActiva: notificacionActiva,
                                minutosAntes: minutosAntes,
                              );

                              final eventProvider = Provider.of<EventProvider>(
                                context,
                                listen: false,
                              );
                              await eventProvider.updateEvent(
                                evento.id,
                                eventoActualizado,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        notificacionActiva
                                            ? Icons.notifications_active
                                            : Icons.notifications_off,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        notificacionActiva
                                            ? 'Notificación activada para ${evento.titulo}'
                                            : 'Notificación desactivada para ${evento.titulo}',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: notificacionActiva
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final list = _filtered;
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF121212)
              : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Eventos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? LinearGradient(
                        colors: themeProvider.backgroundGradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.blue.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
            ),
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              _buildHeader(themeProvider),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        gradient: themeProvider.isDarkMode
                                            ? null
                                            : LinearGradient(
                                                colors: [
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade200,
                                                ],
                                              ),
                                        color: themeProvider.isDarkMode
                                            ? themeProvider.cardBackgroundColor
                                                  .withOpacity(0.5)
                                            : null,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.event_busy,
                                        size: 80,
                                        color: themeProvider.isDarkMode
                                            ? themeProvider.secondaryTextColor
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No hay eventos',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Crea tu primer evento con el botón',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? const Color(0xFFB0BEC5)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF6C757D)
                            : Colors.deepPurple.shade400,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100, top: 8),
                          itemCount: list.length,
                          itemBuilder: (context, i) =>
                              _buildEventCard(list[i], themeProvider),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? LinearGradient(
                        colors: themeProvider.backgroundGradientColors
                            .take(2)
                            .toList(),
                      )
                    : LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.blue.shade400,
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? themeProvider.cardBorderColor.withOpacity(0.3)
                        : Colors.deepPurple.shade200,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateOrEditDialog(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                label: const Text(
                  'Crear Evento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

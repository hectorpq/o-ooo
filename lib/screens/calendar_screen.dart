// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/evento.dart';
import '../providers/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  final List<Evento> eventos;
  final void Function(int index, Evento evento) onEditEvento;
  final void Function(Evento evento) onAddEvento;
  final void Function(int index) onDeleteEvento;
  final VoidCallback? onGoToEvents;

  // Nuevos callbacks específicos
  final void Function(Evento evento, int index)? onGoToEventsToEdit;
  final VoidCallback? onGoToEventsToCreate;

  final Future<void> Function(String eventoId, int minutes)?
  onUpdateNotificationTime;
  final Future<void> Function(String eventoId)? onToggleNotification;

  const CalendarScreen({
    super.key,
    required this.eventos,
    required this.onEditEvento,
    required this.onAddEvento,
    required this.onDeleteEvento,
    this.onGoToEvents,
    this.onGoToEventsToEdit,
    this.onGoToEventsToCreate,
    this.onUpdateNotificationTime,
    this.onToggleNotification,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late Map<DateTime, List<Evento>> _eventsMap;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    try {
      await initializeDateFormatting('es_ES', null);
      _updateEventsMap();
      _initializeAnimations();
    } catch (e) {
      debugPrint('Error al inicializar calendario: $e');
    }
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventos.length != widget.eventos.length ||
        !_listEquals(oldWidget.eventos, widget.eventos)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateEventsMap();
        }
      });
    }
  }

  bool _listEquals(List<Evento> a, List<Evento> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].titulo != b[i].titulo) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateEventsMap() {
    if (mounted) {
      setState(() {
        _eventsMap = _groupEvents(widget.eventos);
      });
    }
  }

  Map<DateTime, List<Evento>> _groupEvents(List<Evento> eventos) {
    final map = <DateTime, List<Evento>>{};
    try {
      for (var e in eventos) {
        final day = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
        if (map[day] == null) {
          map[day] = [];
        }
        map[day]!.add(e);
      }
      debugPrint('Eventos agrupados: ${map.length} días con eventos');
    } catch (e) {
      debugPrint('Error al agrupar eventos: $e');
    }
    return map;
  }

  List<Evento> _getEventsForDay(DateTime day) {
    try {
      final key = DateTime(day.year, day.month, day.day);
      final events = _eventsMap[key] ?? [];
      return events;
    } catch (e) {
      debugPrint('Error al obtener eventos del día: $e');
      return [];
    }
  }

  void _showDetail(Evento ev, int eventIndex, ThemeProvider themeProvider) {
    try {
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (_) => _buildEventDetailSheet(ev, eventIndex, themeProvider),
      );
    } catch (e) {
      debugPrint('Error al mostrar detalle: $e');
      _showErrorSnackBar('Error al mostrar detalles del evento');
    }
  }

  Widget _buildEventDetailSheet(
    Evento ev,
    int eventIndex,
    ThemeProvider themeProvider,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 300 * (1 - value)),
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? themeProvider.cardBackgroundColor
                  : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? themeProvider.secondaryTextColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header con icono animado
                  _buildEventHeader(ev, themeProvider),
                  const SizedBox(height: 24),

                  // Descripción
                  _buildEventDescription(ev, themeProvider),
                  const SizedBox(height: 20),

                  // Botones de acción
                  _buildActionButtons(ev, eventIndex, themeProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventHeader(Evento ev, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: themeProvider.isDarkMode
            ? LinearGradient(
                colors: themeProvider.backgroundGradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? themeProvider.cardBorderColor.withOpacity(0.3)
                : Colors.deepPurple.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, rotationValue, child) {
              return Transform.rotate(
                angle: rotationValue * 2 * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event, color: Colors.white, size: 32),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.titulo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy – HH:mm').format(ev.fecha),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescription(Evento ev, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: themeProvider.isDarkMode
            ? null
            : LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
              ),
        color: themeProvider.isDarkMode
            ? themeProvider.cardBackgroundColor
            : null,
        borderRadius: BorderRadius.circular(20),
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
                    : Colors.deepPurple.shade400,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Descripción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? themeProvider.primaryTextColor
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ev.descripcion.isEmpty ? 'Sin descripción' : ev.descripcion,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: themeProvider.isDarkMode
                  ? themeProvider.primaryTextColor
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Evento ev,
    int eventIndex,
    ThemeProvider themeProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    // Usar el nuevo callback específico para editar
                    if (widget.onGoToEventsToEdit != null) {
                      widget.onGoToEventsToEdit!(ev, eventIndex);
                    } else if (widget.onGoToEvents != null) {
                      widget.onGoToEvents!();
                    } else {
                      _showErrorSnackBar('No se puede navegar a eventos');
                    }
                  },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.isDarkMode
                  ? const Color(0xFF6C757D)
                  : Colors.blue.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(
                      eventIndex,
                      ev.titulo,
                      themeProvider,
                    );
                  },
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    int index,
    String titulo,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode
            ? themeProvider.cardBackgroundColor
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar Evento',
          style: TextStyle(
            color: themeProvider.isDarkMode
                ? themeProvider.primaryTextColor
                : Colors.black,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "$titulo"?',
          style: TextStyle(
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
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    Navigator.pop(context);
                    await _safeDeleteEvent(index);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _safeDeleteEvent(int index) async {
    try {
      setState(() => _isLoading = true);
      widget.onDeleteEvento(index);
      _showSuccessSnackBar('Evento eliminado correctamente');
    } catch (e) {
      debugPrint('Error al eliminar evento: $e');
      _showErrorSnackBar('Error al eliminar el evento');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _eventMarker(
    DateTime day,
    List<Evento> events,
    ThemeProvider themeProvider,
  ) {
    if (events.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: events.length > 3 ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: events.length > 3
                  ? LinearGradient(
                      colors: [Colors.red.shade400, Colors.orange.shade400],
                    )
                  : events.length > 1
                  ? LinearGradient(
                      colors: [Colors.orange.shade400, Colors.yellow.shade400],
                    )
                  : themeProvider.isDarkMode
                  ? LinearGradient(
                      colors: themeProvider.backgroundGradientColors
                          .take(2)
                          .toList(),
                    )
                  : LinearGradient(
                      colors: [Colors.green.shade400, Colors.blue.shade400],
                    ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                      ? themeProvider.cardBorderColor.withOpacity(0.3)
                      : (events.length > 3
                            ? Colors.red.shade200
                            : events.length > 1
                            ? Colors.orange.shade200
                            : Colors.blue.shade200),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                events.length > 9 ? '9+' : events.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _getEventIndex(Evento evento) {
    try {
      // Buscar por ID en lugar de por objeto para evitar problemas de referencia
      for (int i = 0; i < widget.eventos.length; i++) {
        if (widget.eventos[i].id == evento.id) {
          return i;
        }
      }
      debugPrint(
        'Evento no encontrado en la lista principal: ${evento.titulo}',
      );
      return -1;
    } catch (e) {
      debugPrint('Error al obtener índice del evento: $e');
      return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final selectedEvents = _selectedDay != null
            ? _getEventsForDay(_selectedDay!)
            : _getEventsForDay(_focusedDay);

        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF121212)
              : Colors.grey.shade50,
          appBar: _buildAppBar(themeProvider),
          body: Column(
            children: [
              _buildHeader(themeProvider),
              _buildCalendar(themeProvider),
              const SizedBox(height: 16),
              _buildEventsList(selectedEvents, themeProvider),
            ],
          ),
          floatingActionButton: _buildFAB(themeProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: const Text(
        'Calendario',
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
                  colors: [Colors.deepPurple.shade400, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
      ),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _isLoading
              ? null
              : () {
                  try {
                    widget.onGoToEvents?.call();
                  } catch (e) {
                    debugPrint('Error al navegar a eventos: $e');
                    _showErrorSnackBar('Error al navegar');
                  }
                },
          icon: const Icon(Icons.list_alt),
          tooltip: 'Ver todos los eventos',
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return SlideTransition(
      position: _slideAnimation,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                child: const Icon(Icons.today, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoy: ${DateFormat('dd MMMM yyyy', 'es_ES').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Text(
                      '${_getEventsForDay(DateTime.now()).length} evento(s) programado(s)',
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFFB0BEC5)
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeProvider themeProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode
              ? themeProvider.cardBackgroundColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? themeProvider.cardBorderColor.withOpacity(0.3)
                  : Colors.grey.shade200,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TableCalendar<Evento>(
          locale: 'es_ES',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.month,
          onDaySelected: (selectedDay, focusedDay) {
            if (mounted) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              return _eventMarker(date, events.cast<Evento>(), themeProvider);
            },
            todayBuilder: (context, date, _) => _buildTodayMarker(date),
            selectedBuilder: (context, date, _) =>
                _buildSelectedMarker(date, themeProvider),
            defaultBuilder: (context, date, _) =>
                _buildDefaultMarker(date, themeProvider),
          ),
          calendarStyle: CalendarStyle(
            weekendTextStyle: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600,
            ),
            defaultTextStyle: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            outsideDaysVisible: themeProvider.isDarkMode,
            outsideTextStyle: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
            ),
            cellMargin: const EdgeInsets.all(4),
            cellPadding: const EdgeInsets.all(0),
            markersMaxCount: 1,
            canMarkersOverflow: false,
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: themeProvider.isDarkMode
                  ? const Color(0xFF6C757D)
                  : Colors.deepPurple.shade400,
              size: 28,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: themeProvider.isDarkMode
                  ? const Color(0xFF6C757D)
                  : Colors.deepPurple.shade400,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMarker(DateTime date) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade400],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              date.day.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedMarker(DateTime date, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            margin: const EdgeInsets.all(6),
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
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                      ? themeProvider.cardBorderColor.withOpacity(0.3)
                      : Colors.deepPurple.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              date.day.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultMarker(DateTime date, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(
        date.day.toString(),
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEventsList(
    List<Evento> selectedEvents,
    ThemeProvider themeProvider,
  ) {
    return Expanded(
      child: selectedEvents.isEmpty
          ? _buildEmptyState(themeProvider)
          : _buildEventListView(selectedEvents, themeProvider),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? null
                    : LinearGradient(
                        colors: [Colors.grey.shade100, Colors.grey.shade200],
                      ),
                color: themeProvider.isDarkMode
                    ? themeProvider.cardBackgroundColor.withOpacity(0.5)
                    : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 64,
                color: themeProvider.isDarkMode
                    ? themeProvider.secondaryTextColor
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay eventos',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.grey.shade600,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'en esta fecha',
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? const Color(0xFFB0BEC5)
                    : Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListView(
    List<Evento> selectedEvents,
    ThemeProvider themeProvider,
  ) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final ev = selectedEvents[index];
        final eventIndex = _getEventIndex(ev);

        if (eventIndex == -1) {
          return const SizedBox.shrink();
        }

        return _buildEventCard(ev, eventIndex, index, themeProvider);
      },
    );
  }

  Widget _buildEventCard(
    Evento ev,
    int eventIndex,
    int listIndex,
    ThemeProvider themeProvider,
  ) {
    final isPast = ev.fecha.isBefore(DateTime.now());

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (listIndex * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDetail(ev, eventIndex, themeProvider),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildEventIcon(isPast, themeProvider),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildEventInfo(ev, isPast, themeProvider),
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

  Widget _buildEventIcon(bool isPast, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isPast
            ? LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [
                        themeProvider.secondaryTextColor,
                        themeProvider.secondaryTextColor.withOpacity(0.7),
                      ]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              )
            : themeProvider.isDarkMode
            ? LinearGradient(
                colors: themeProvider.backgroundGradientColors.take(2).toList(),
              )
            : LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? themeProvider.cardBorderColor.withOpacity(0.3)
                : isPast
                ? Colors.grey.shade200
                : Colors.blue.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        isPast ? Icons.history : Icons.event,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildEventInfo(Evento ev, bool isPast, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ev.titulo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPast
                ? (themeProvider.isDarkMode
                      ? const Color(0xFFB0BEC5)
                      : Colors.grey.shade600)
                : (themeProvider.isDarkMode
                      ? Colors.white
                      : Colors.grey.shade800),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? themeProvider.cardBackgroundColor
                : isPast
                ? Colors.grey.shade100
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: themeProvider.isDarkMode
                ? Border.all(
                    color: themeProvider.cardBorderColor.withOpacity(0.3),
                  )
                : null,
          ),
          child: Text(
            DateFormat('HH:mm').format(ev.fecha),
            style: TextStyle(
              color: isPast
                  ? (themeProvider.isDarkMode
                        ? const Color(0xFFB0BEC5)
                        : Colors.grey.shade600)
                  : (themeProvider.isDarkMode
                        ? const Color(0xFF6C757D)
                        : Colors.blue.shade700),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAB(ThemeProvider themeProvider) {
    return FloatingActionButton(
      heroTag: 'calendar_fab',
      onPressed: _isLoading
          ? null
          : () {
              try {
                debugPrint('FAB presionado - Navegando a eventos para crear');
                // Usar el nuevo callback específico para crear
                if (widget.onGoToEventsToCreate != null) {
                  widget.onGoToEventsToCreate!();
                } else if (widget.onGoToEvents != null) {
                  widget.onGoToEvents!();
                } else {
                  _showErrorSnackBar('No se puede navegar a eventos');
                }
              } catch (e) {
                debugPrint('Error en FAB: $e');
                _showErrorSnackBar('Error al navegar');
              }
            },
      backgroundColor: _isLoading
          ? Colors.grey.shade400
          : themeProvider.isDarkMode
          ? const Color(0xFF6C757D)
          : Colors.deepPurple.shade400,
      tooltip: 'Crear nuevo evento',
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.add, color: Colors.white),
    );
  }
}

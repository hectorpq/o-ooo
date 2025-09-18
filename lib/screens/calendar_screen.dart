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
  final Future<void> Function(String eventoId, int minutes)
  onUpdateNotificationTime;
  final Future<void> Function(String eventoId) onToggleNotification;

  const CalendarScreen({
    super.key,
    required this.eventos,
    required this.onEditEvento,
    required this.onAddEvento,
    required this.onDeleteEvento,
    this.onGoToEvents,
    required this.onUpdateNotificationTime,
    required this.onToggleNotification,
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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) => setState(() {}));
    _updateEventsMap();

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
        oldWidget.eventos != widget.eventos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateEventsMap();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateEventsMap() {
    setState(() {
      _eventsMap = _groupEvents(widget.eventos);
    });
  }

  Map<DateTime, List<Evento>> _groupEvents(List<Evento> eventos) {
    final map = <DateTime, List<Evento>>{};
    for (var e in eventos) {
      final day = DateTime(e.fecha.year, e.fecha.month, e.fecha.day);
      if (map[day] == null) {
        map[day] = [];
      }
      map[day]!.add(e);
    }
    print('Eventos agrupados: $map');
    return map;
  }

  List<Evento> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final events = _eventsMap[key] ?? [];
    print('Eventos para $key: ${events.length}');
    return events;
  }

  void _showDetail(Evento ev, int eventIndex, ThemeProvider themeProvider) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (_) {
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
                              ? themeProvider.secondaryTextColor.withOpacity(
                                  0.3,
                                )
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header con icono animado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: themeProvider.isDarkMode
                              ? LinearGradient(
                                  colors:
                                      themeProvider.backgroundGradientColors,
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
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.isDarkMode
                                  ? themeProvider.cardBorderColor.withOpacity(
                                      0.3,
                                    )
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
                                    child: const Icon(
                                      Icons.event,
                                      color: Colors.white,
                                      size: 32,
                                    ),
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
                                      DateFormat(
                                        'dd/MM/yyyy – HH:mm',
                                      ).format(ev.fecha),
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
                      ),

                      const SizedBox(height: 24),

                      // Descripción
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: themeProvider.isDarkMode
                              ? null
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade50,
                                    Colors.grey.shade100,
                                  ],
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
                              ev.descripcion.isEmpty
                                  ? 'Sin descripción'
                                  : ev.descripcion,
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
                      ),

                      const SizedBox(height: 20),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onEditEvento(eventIndex, ev);
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider.isDarkMode
                                    ? const Color(0xFF6C757D)
                                    : Colors.blue.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
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
              ),
            );
          },
        );
      },
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
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteEvento(index);
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
    return widget.eventos.indexOf(evento);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final selectedEvents = _selectedDay != null
            ? _getEventsForDay(_selectedDay!)
            : _getEventsForDay(_focusedDay);

        print(
          'Construyendo calendario. Total eventos: ${widget.eventos.length}',
        );
        print('Eventos para mostrar: ${selectedEvents.length}');

        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF121212)
              : Colors.grey.shade50,
          appBar: AppBar(
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
            actions: [
              IconButton(
                onPressed: () {
                  if (widget.onGoToEvents != null) {
                    widget.onGoToEvents!();
                  }
                },
                icon: const Icon(Icons.list_alt),
                tooltip: 'Ver todos los eventos',
              ),
            ],
          ),
          body: Column(
            children: [
              // Header decorativo
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: themeProvider.isDarkMode
                        ? null
                        : LinearGradient(
                            colors: [
                              Colors.deepPurple.shade50,
                              Colors.blue.shade50,
                            ],
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
                                    colors: themeProvider
                                        .backgroundGradientColors
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
                                    ? themeProvider.cardBorderColor.withOpacity(
                                        0.3,
                                      )
                                    : Colors.deepPurple.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.today,
                            color: Colors.white,
                            size: 24,
                          ),
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
              ),

              // Calendario
              FadeTransition(
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
                      print('Día seleccionado: $selectedDay');
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      print(
                        'Eventos para el día seleccionado: ${_getEventsForDay(selectedDay).length}',
                      );
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        return _eventMarker(
                          date,
                          events.cast<Evento>(),
                          themeProvider,
                        );
                      },
                      todayBuilder: (context, date, _) {
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
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.teal.shade400,
                                    ],
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
                      },
                      selectedBuilder: (context, date, _) {
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
                                          colors: themeProvider
                                              .backgroundGradientColors
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
                                          ? themeProvider.cardBorderColor
                                                .withOpacity(0.3)
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
                      },
                      defaultBuilder: (context, date, _) {
                        return Container(
                          margin: const EdgeInsets.all(6),
                          alignment: Alignment.center,
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      weekendTextStyle: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                      defaultTextStyle: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      outsideDaysVisible: themeProvider.isDarkMode
                          ? true
                          : false,
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
              ),

              const SizedBox(height: 16),

              // Lista de eventos
              Expanded(
                child: selectedEvents.isEmpty
                    ? FadeTransition(
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
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final ev = selectedEvents[index];
                          final eventIndex = _getEventIndex(ev);
                          final isPast = ev.fecha.isBefore(DateTime.now());

                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
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
                                              ? themeProvider.cardBorderColor
                                                    .withOpacity(0.3)
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
                                        onTap: () => _showDetail(
                                          ev,
                                          eventIndex,
                                          themeProvider,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: isPast
                                                      ? LinearGradient(
                                                          colors:
                                                              themeProvider
                                                                  .isDarkMode
                                                              ? [
                                                                  themeProvider
                                                                      .secondaryTextColor,
                                                                  themeProvider
                                                                      .secondaryTextColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                ]
                                                              : [
                                                                  Colors
                                                                      .grey
                                                                      .shade300,
                                                                  Colors
                                                                      .grey
                                                                      .shade400,
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
                                                            Colors
                                                                .blue
                                                                .shade400,
                                                            Colors
                                                                .purple
                                                                .shade400,
                                                          ],
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          themeProvider
                                                              .isDarkMode
                                                          ? themeProvider
                                                                .cardBorderColor
                                                                .withOpacity(
                                                                  0.3,
                                                                )
                                                          : isPast
                                                          ? Colors.grey.shade200
                                                          : Colors
                                                                .blue
                                                                .shade200,
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  isPast
                                                      ? Icons.history
                                                      : Icons.event,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ev.titulo,
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isPast
                                                            ? (themeProvider
                                                                      .isDarkMode
                                                                  ? const Color(
                                                                      0xFFB0BEC5,
                                                                    )
                                                                  : Colors
                                                                        .grey
                                                                        .shade600)
                                                            : (themeProvider
                                                                      .isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .grey
                                                                        .shade800),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            themeProvider
                                                                .isDarkMode
                                                            ? themeProvider
                                                                  .cardBackgroundColor
                                                            : isPast
                                                            ? Colors
                                                                  .grey
                                                                  .shade100
                                                            : Colors
                                                                  .blue
                                                                  .shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border:
                                                            themeProvider
                                                                .isDarkMode
                                                            ? Border.all(
                                                                color: themeProvider
                                                                    .cardBorderColor
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                              )
                                                            : null,
                                                      ),
                                                      child: Text(
                                                        DateFormat(
                                                          'HH:mm',
                                                        ).format(ev.fecha),
                                                        style: TextStyle(
                                                          color: isPast
                                                              ? (themeProvider
                                                                        .isDarkMode
                                                                    ? const Color(
                                                                        0xFFB0BEC5,
                                                                      )
                                                                    : Colors
                                                                          .grey
                                                                          .shade600)
                                                              : (themeProvider
                                                                        .isDarkMode
                                                                    ? const Color(
                                                                        0xFF6C757D,
                                                                      )
                                                                    : Colors
                                                                          .blue
                                                                          .shade700),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
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
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'calendar_fab',
            onPressed: () {
              print('FAB presionado');
              print('onGoToEvents es null: ${widget.onGoToEvents == null}');
              if (widget.onGoToEvents != null) {
                print('Llamando a onGoToEvents');
                widget.onGoToEvents!();
              } else {
                print('onGoToEvents es null, no se puede navegar');
              }
            },
            backgroundColor: themeProvider.isDarkMode
                ? const Color(0xFF6C757D)
                : Colors.deepPurple.shade400,
            tooltip: 'Ir a eventos',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

package com.example.agenda_ai

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class HorarioWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val CHANNEL = "com.example.appmobilav/widget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Actualizar cada widget
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget agregado por primera vez
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // Último widget removido
        super.onDisabled(context)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            // Crear las vistas del widget
            val views = RemoteViews(context.packageName, R.layout.horario_widget)
            
            // Obtener datos desde SharedPreferences (guardados por Flutter)
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            
            // Datos por defecto
            var displayText = "Sin datos disponibles"
            
            // Intentar obtener datos del widget
            val currentSubject = prefs.getString("currentSubject", "")
            val scheduleStatus = prefs.getString("scheduleStatus", "")
            val currentTime = prefs.getString("currentTime", "")
            val eventsToday = prefs.getInt("eventsToday", 0)
            val nextEventToday = prefs.getString("nextEventToday", "")
            
            // Construir texto para mostrar
            displayText = when {
                !currentSubject.isNullOrEmpty() -> {
                    "En clase: $currentSubject"
                }
                !scheduleStatus.isNullOrEmpty() -> {
                    scheduleStatus
                }
                eventsToday > 0 -> {
                    if (!nextEventToday.isNullOrEmpty()) {
                        "$eventsToday eventos hoy\nPróximo: $nextEventToday"
                    } else {
                        "$eventsToday eventos hoy"
                    }
                }
                !currentTime.isNullOrEmpty() -> {
                    "$currentTime\nSin actividades"
                }
                else -> "Sin datos disponibles"
            }
            
            // Establecer el texto en el widget
            views.setTextViewText(R.id.widget_current_subject, displayText)
            
            // Actualizar el widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
        } catch (e: Exception) {
            // En caso de error, mostrar mensaje de error
            val views = RemoteViews(context.packageName, R.layout.horario_widget)
            views.setTextViewText(R.id.widget_current_subject, "Error: ${e.message}")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    // Método para actualizar widget desde Flutter
    fun updateWidget(context: Context, data: Map<String, Any>) {
        try {
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            
            // Guardar datos
            data.forEach { (key, value) ->
                when (value) {
                    is String -> editor.putString(key, value)
                    is Int -> editor.putInt(key, value)
                    is Boolean -> editor.putBoolean(key, value)
                    is Long -> editor.putLong(key, value)
                }
            }
            
            editor.apply()
            
            // Forzar actualización del widget
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, HorarioWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
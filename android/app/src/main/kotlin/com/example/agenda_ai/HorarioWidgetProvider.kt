package com.example.agenda_ai

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import java.text.SimpleDateFormat
import java.util.*

class HorarioWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val PREFS_NAME = "horario_widget_prefs"
        private const val PREF_EVENTS_TODAY = "events_today"
        private const val PREF_NEXT_EVENT = "next_event"
        private const val PREF_NEXT_EVENT_TIME = "next_event_time"
        private const val PREF_SCHEDULE_STATUS = "schedule_status"
        private const val PREF_CURRENT_SUBJECT = "current_subject"
        private const val PREF_LAST_UPDATE = "last_update"

        // Método estático para actualizar desde Flutter
        fun updateFromFlutter(context: Context, widgetData: Map<String, Any>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()

            // Guardar datos
            editor.putInt(PREF_EVENTS_TODAY, widgetData["eventsToday"] as? Int ?: 0)
            editor.putString(PREF_NEXT_EVENT, widgetData["nextEventToday"] as? String ?: "")
            editor.putString(PREF_NEXT_EVENT_TIME, widgetData["nextEventTodayTime"] as? String ?: "")
            editor.putString(PREF_SCHEDULE_STATUS, widgetData["scheduleStatus"] as? String ?: "Sin clases")
            editor.putString(PREF_CURRENT_SUBJECT, widgetData["currentSubject"] as? String ?: "")
            editor.putLong(PREF_LAST_UPDATE, System.currentTimeMillis())
            editor.apply()

            // Actualizar todos los widgets
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetComponent = android.content.ComponentName(context, HorarioWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)
            
            val provider = HorarioWidgetProvider()
            for (appWidgetId in appWidgetIds) {
                provider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Actualizar todos los widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget habilitado por primera vez
    }

    override fun onDisabled(context: Context) {
        // Último widget deshabilitado
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.horario_widget)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Obtener datos guardados
        val eventsToday = prefs.getInt(PREF_EVENTS_TODAY, 0)
        val nextEvent = prefs.getString(PREF_NEXT_EVENT, "")
        val nextEventTime = prefs.getString(PREF_NEXT_EVENT_TIME, "")
        val scheduleStatus = prefs.getString(PREF_SCHEDULE_STATUS, "Sin clases")
        val currentSubject = prefs.getString(PREF_CURRENT_SUBJECT, "")

        // Formatear fecha y hora actual
        val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        val currentDate = SimpleDateFormat("dd MMM", Locale.getDefault()).format(Date())

        // Actualizar vistas
        views.setTextViewText(R.id.widget_time, currentTime)
        views.setTextViewText(R.id.widget_date, currentDate)
        
        // Estado principal
        if (currentSubject?.isNotEmpty() == true) {
            views.setTextViewText(R.id.widget_status, "En clase: $currentSubject")
        } else if (nextEvent?.isNotEmpty() == true) {
            views.setTextViewText(R.id.widget_status, "Próximo: $nextEvent")
            views.setTextViewText(R.id.widget_next_time, nextEventTime ?: "")
        } else {
            views.setTextViewText(R.id.widget_status, scheduleStatus ?: "Sin clases")
        }

        // Contador de eventos hoy
        if (eventsToday > 0) {
            views.setTextViewText(R.id.widget_events_count, "$eventsToday eventos hoy")
        } else {
            views.setTextViewText(R.id.widget_events_count, "Sin eventos hoy")
        }

        // Configurar click para abrir la app
        val intent = Intent(context, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        // Actualizar el widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
package com.example.agenda_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val WIDGET_CHANNEL = "com.example.appmobilav/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    try {
                        // Inicializar el widget
                        result.success("Widget inicializado")
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", "Error inicializando widget", e.message)
                    }
                }
                
                "updateWidget" -> {
                    try {
                        val widgetData = call.arguments as? Map<String, Any>
                        if (widgetData != null) {
                            HorarioWidgetProvider.updateFromFlutter(this, widgetData)
                            result.success("Widget actualizado")
                        } else {
                            result.error("NO_DATA", "No se recibieron datos", null)
                        }
                    } catch (e: Exception) {
                        result.error("UPDATE_ERROR", "Error actualizando widget", e.message)
                    }
                }
                
                "schedulePeriodicUpdates" -> {
                    try {
                        // Programar actualizaciones periódicas si es necesario
                        result.success("Actualizaciones programadas")
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", "Error programando actualizaciones", e.message)
                    }
                }
                
                "clearWidget" -> {
                    try {
                        // Limpiar datos del widget
                        val emptyData = mapOf<String, Any>(
                            "scheduleStatus" to "Sin datos",
                            "eventsToday" to 0,
                            "nextEventToday" to "",
                            "nextEventTodayTime" to "",
                            "currentSubject" to ""
                        )
                        HorarioWidgetProvider.updateFromFlutter(this, emptyData)
                        result.success("Widget limpiado")
                    } catch (e: Exception) {
                        result.error("CLEAR_ERROR", "Error limpiando widget", e.message)
                    }
                }
                
                "isSupported" -> {
                    result.success(true)
                }
                
                "getWidgetInfo" -> {
                    result.success(mapOf(
                        "available" to true,
                        "name" to "Horario Widget",
                        "version" to "1.0"
                    ))
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
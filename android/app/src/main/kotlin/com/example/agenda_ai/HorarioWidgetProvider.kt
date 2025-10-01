// android/app/src/main/kotlin/com/example/agenda_ai/HorarioWidgetProvider.kt
package com.example.agenda_ai

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import java.text.SimpleDateFormat
import java.util.*

class HorarioWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == "android.appwidget.action.APPWIDGET_UPDATE") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HorarioWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        private val diasSemana = mapOf(
            Calendar.MONDAY to "Lunes",
            Calendar.TUESDAY to "Martes",
            Calendar.WEDNESDAY to "Miércoles",
            Calendar.THURSDAY to "Jueves",
            Calendar.FRIDAY to "Viernes",
            Calendar.SATURDAY to "Sábado",
            Calendar.SUNDAY to "Domingo"
        )

        fun updateFromFlutter(
            context: Context,
            widgetData: Map<String, Any>
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HorarioWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.horario_widget)
            
            val calendar = Calendar.getInstance()
            val diaActual = diasSemana[calendar.get(Calendar.DAY_OF_WEEK)] ?: "Hoy"
            val fechaFormateada = SimpleDateFormat("dd 'de' MMMM", Locale("es", "ES")).format(calendar.time)
            
            views.setTextViewText(R.id.widget_dia, diaActual)
            views.setTextViewText(R.id.widget_fecha, fechaFormateada)
            
            cargarDatosWidget(context, views, diaActual, appWidgetManager, appWidgetId)
        }

        private fun cargarDatosWidget(
            context: Context,
            views: RemoteViews,
            diaActual: String,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val auth = FirebaseAuth.getInstance()
            val firestore = FirebaseFirestore.getInstance()
            val userId = auth.currentUser?.uid

            if (userId == null) {
                views.setTextViewText(R.id.widget_cursos, "Por favor, inicia sesión en la app")
                views.setTextViewText(R.id.widget_eventos, "")
                appWidgetManager.updateAppWidget(appWidgetId, views)
                return
            }

            firestore.collection("horarios")
                .whereEqualTo("userId", userId)
                .whereEqualTo("esActivo", true)
                .limit(1)
                .get()
                .addOnSuccessListener { horarioSnapshot ->
                    if (horarioSnapshot.isEmpty) {
                        views.setTextViewText(R.id.widget_cursos, "Sin clases configuradas")
                        cargarEventos(context, views, userId, appWidgetManager, appWidgetId)
                        return@addOnSuccessListener
                    }

                    val horarioDoc = horarioSnapshot.documents[0]
                    val slots = horarioDoc.get("slots") as? List<Map<String, Any>> ?: emptyList()
                    val materias = horarioDoc.get("materias") as? Map<String, Map<String, Any>> ?: emptyMap()

                    val cursosTexto = obtenerCursosDelDia(slots, materias, diaActual)
                    views.setTextViewText(R.id.widget_cursos, cursosTexto)

                    cargarEventos(context, views, userId, appWidgetManager, appWidgetId)
                }
                .addOnFailureListener {
                    views.setTextViewText(R.id.widget_cursos, "Error al cargar horario")
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
        }

        private fun obtenerCursosDelDia(
            slots: List<Map<String, Any>>,
            materias: Map<String, Map<String, Any>>,
            diaActual: String
        ): String {
            val horaActual = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            
            // Filtrar SOLO clases del día actual que NO han pasado
            val cursosHoy = slots
                .filter { slot -> 
                    val dia = slot["dia"] as? String ?: ""
                    dia == diaActual && slot["materiaId"] != null
                }
                .filter { slot ->
                    val horaCompleta = slot["hora"] as? String ?: ""
                    // Extraer solo la hora de inicio (ej: "7:30 - 8:20 (M1)" -> "7:30")
                    val horaInicio = horaCompleta.split(" - ").firstOrNull()?.trim() ?: ""
                    
                    // Normalizar a formato 24h con ceros (7:30 -> 07:30)
                    val partesHora = horaInicio.split(":")
                    if (partesHora.size == 2) {
                        val hora = partesHora[0].padStart(2, '0')
                        val minuto = partesHora[1].padStart(2, '0')
                        val horaSlotNormalizada = "$hora:$minuto"
                        // Comparar con hora actual
                        horaSlotNormalizada >= horaActual
                    } else {
                        false
                    }
                }
                .sortedBy { slot -> slot["hora"] as? String ?: "" }
                .take(3) // Máximo 3 clases

            if (cursosHoy.isEmpty()) {
                return "✅ No hay más clases por hoy"
            }

            val cursosTexto = StringBuilder()
            for ((index, slot) in cursosHoy.withIndex()) {
                val materiaId = slot["materiaId"] as? String
                val horaCompleta = slot["hora"] as? String ?: ""
                
                // Extraer solo la hora de inicio para mostrar
                val horaInicio = horaCompleta.split(" - ").firstOrNull()?.trim() ?: ""
                
                if (materiaId != null && materias.containsKey(materiaId)) {
                    val materia = materias[materiaId] as Map<String, Any>
                    val nombre = materia["nombre"] as? String ?: "Sin nombre"
                    val aula = materia["aula"] as? String ?: "Sin aula"
                    
                    cursosTexto.append("🕐 $horaInicio\n")
                    cursosTexto.append("$nombre\n")
                    cursosTexto.append("📍 $aula")
                    
                    if (index < cursosHoy.size - 1) {
                        cursosTexto.append("\n\n")
                    }
                }
            }
            
            return cursosTexto.toString()
        }

        private fun cargarEventos(
            context: Context,
            views: RemoteViews,
            userId: String,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val firestore = FirebaseFirestore.getInstance()
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val inicioHoy = calendar.time

            calendar.add(Calendar.DAY_OF_YEAR, 1)
            val finHoy = calendar.time

            firestore.collection("eventos")
                .whereEqualTo("uid", userId)
                .whereGreaterThanOrEqualTo("fecha", inicioHoy)
                .whereLessThan("fecha", finHoy)
                .orderBy("fecha")
                .get()
                .addOnSuccessListener { eventosSnapshot ->
                    if (eventosSnapshot.isEmpty) {
                        views.setTextViewText(R.id.widget_eventos, "Sin eventos hoy")
                    } else {
                        val ahora = Date()
                        val eventosHoy = eventosSnapshot.documents
                        
                        // Filtrar solo eventos futuros
                        val eventosFuturos = eventosHoy.filter { doc ->
                            val fecha = doc.getTimestamp("fecha")?.toDate()
                            fecha?.after(ahora) == true
                        }

                        if (eventosFuturos.isEmpty()) {
                            views.setTextViewText(R.id.widget_eventos, "No hay eventos pendientes hoy")
                        } else {
                            val eventosTexto = StringBuilder()
                            val proximoEvento = eventosFuturos.first()
                            
                            val titulo = proximoEvento.getString("titulo") ?: "Evento"
                            val fecha = proximoEvento.getTimestamp("fecha")?.toDate()
                            val hora = SimpleDateFormat("HH:mm", Locale.getDefault()).format(fecha ?: Date())
                            
                            eventosTexto.append("🔔 Próximo: $titulo\n")
                            eventosTexto.append("   $hora")
                            
                            if (eventosFuturos.size > 1) {
                                eventosTexto.append("\n\n")
                                eventosTexto.append("Eventos pendientes: ${eventosFuturos.size}")
                            }
                            
                            views.setTextViewText(R.id.widget_eventos, eventosTexto.toString().trim())
                        }
                    }
                    
                    val ahora = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
                    views.setTextViewText(R.id.widget_ultima_actualizacion, "Actualizado: $ahora")
                    
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
                .addOnFailureListener {
                    views.setTextViewText(R.id.widget_eventos, "Error al cargar eventos")
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
        }
    }
}
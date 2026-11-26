package es.andenlibre.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class StationDeparturesWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == "es.andenlibre.app/widget-refresh"
        ) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, StationDeparturesWidgetProvider::class.java)
            )
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val stationCode = prefs.getString("flutter.defaultStationCode", "22100") ?: "22100"
            val stationName = prefs.getString("flutter.defaultStationName", "Estación") ?: "Estación"
            val json = prefs.getString("flutter.stationDeparturesJSON.$stationCode", "[]") ?: "[]"
            val departures = try {
                val array = JSONArray(json)
                val result = mutableListOf<RemoteDeparture>()
                val formatter = SimpleDateFormat("HH:mm", Locale.UK)
                val now = formatter.format(Date())
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val time = item.optString("scheduledTime")
                    if (time.matches(Regex("^\\d{2}:\\d{2}$")) && time >= now) {
                        val operator = item.optString("operator", "ADIF")
                        val trainType = item.optString("trainType", "")
                        val service = if (operator.equals("renfe", true) &&
                            trainType.isNotBlank()
                        ) "RENFE $trainType" else operator.uppercase(Locale.ROOT)
                        val trainNumber = item.optString("trainNumber", "")
                        val destination = item.optString("destination", "")
                        val platformRaw = item.optString("platform", "").trim()
                        val platform = if (platformRaw.isBlank() ||
                            platformRaw == "0" ||
                            platformRaw.lowercase(Locale.ROOT) in setOf("por asignar", "-", "—", "null")
                        ) "Vía —" else "Vía $platformRaw"
                        result.add(RemoteDeparture(time, service, trainNumber, destination, platform))
                    }
                }
                result.sortedBy { it.time }.take(3)
            } catch (_: Exception) {
                emptyList()
            }

            val views = RemoteViews(context.packageName, R.layout.widget_station_departures)
            views.setTextViewText(R.id.widget_station_name, stationName)
            val rows = listOf(
                Triple(R.id.widget_row_1_time, R.id.widget_row_1, departures.getOrNull(0)),
                Triple(R.id.widget_row_2_time, R.id.widget_row_2, departures.getOrNull(1)),
                Triple(R.id.widget_row_3_time, R.id.widget_row_3, departures.getOrNull(2)),
            )
            for ((timeId, textId, departure) in rows) {
                if (departure == null) {
                    views.setTextViewText(timeId, "")
                    views.setTextViewText(textId, "")
                } else {
                    views.setTextViewText(timeId, departure.time)
                    views.setTextViewText(
                        textId,
                        "${departure.service} ${departure.trainNumber}\n${departure.destination} · ${departure.platform}"
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private data class RemoteDeparture(
        val time: String,
        val service: String,
        val trainNumber: String,
        val destination: String,
        val platform: String,
    )
}

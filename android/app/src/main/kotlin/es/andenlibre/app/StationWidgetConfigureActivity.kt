package es.andenlibre.app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.appcompat.app.AlertDialog

class StationWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val stations = listOf(
            "22100|Ourense",
            "31400|Santiago de Compostela",
            "31412|A Coruña",
            "22308|Vigo-Urzáiz",
            "22300|Vigo-Guixar",
            "22200|Pontevedra",
            "22204|Vilagarcía de Arousa",
            "17000|Madrid-Chamartín",
            "18000|Madrid-Puerta de Atocha",
            "71801|Barcelona-Sants",
            "03216|Valencia Joaquín Sorolla",
            "51003|Sevilla-Santa Justa",
            "54413|Málaga-María Zambrano",
            "70600|Zaragoza-Delicias",
        )
        val names = stations.map { it.substringAfter('|') }
        val list = ListView(this).apply {
            adapter = ArrayAdapter(this@StationWidgetConfigureActivity,
                android.R.layout.simple_list_item_1, names)
            setOnItemClickListener { _, _, position, _ ->
                val parts = stations[position].split('|', limit = 2)
                saveStation(parts[0], parts[1])
            }
        }

        val title = TextView(this).apply {
            text = "Escoller estación"
            textSize = 20f
            setPadding(32, 32, 32, 16)
        }
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(title)
            addView(list)
        }
        setContentView(layout)
    }

    private fun saveStation(code: String, name: String) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("flutter.defaultStationCode", code)
            .putString("flutter.defaultStationName", name)
            .apply()
        val manager = AppWidgetManager.getInstance(this)
        StationDeparturesWidgetProvider.updateAppWidget(this, manager, appWidgetId)
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))
        finish()
    }
}

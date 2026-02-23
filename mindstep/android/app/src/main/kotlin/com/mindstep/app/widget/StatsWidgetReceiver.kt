package com.mindstep.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.mindstep.app.R

/**
 * Widget "Statistiche" — 2x2
 * Legge i dati scritti da Flutter via home_widget plugin
 */
class StatsWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPlugin", Context.MODE_PRIVATE)

        val streak = prefs.getInt("streak", 0)
        val totalKm = prefs.getString("total_km", "0.0")

        val views = RemoteViews(context.packageName, R.layout.widget_stats_layout)
        views.setTextViewText(R.id.widget_streak, "$streak giorni")
        views.setTextViewText(R.id.widget_total_km, "$totalKm km")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

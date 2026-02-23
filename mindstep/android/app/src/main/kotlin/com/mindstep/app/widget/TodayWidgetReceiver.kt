package com.mindstep.app.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.mindstep.app.R

/**
 * Widget "Oggi al Volo" — aggiornato tramite home_widget Flutter plugin
 * I dati vengono scritti da Flutter via SharedPreferences con il prefisso
 * "HomeWidgetPlugin" (standard del plugin home_widget)
 */
class TodayWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs: SharedPreferences = context.getSharedPreferences(
            "HomeWidgetPlugin",
            Context.MODE_PRIVATE
        )

        val km = prefs.getString("today_km", "0.00")
        val routineText = prefs.getString("today_routine", "0/0")
        val brainCount = prefs.getString("today_brain", "0 note")

        val views = RemoteViews(context.packageName, R.layout.widget_today_layout)
        views.setTextViewText(R.id.widget_km, "$km km")
        views.setTextViewText(R.id.widget_routine, routineText ?: "0/0")
        views.setTextViewText(R.id.widget_brain, brainCount ?: "0 note")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

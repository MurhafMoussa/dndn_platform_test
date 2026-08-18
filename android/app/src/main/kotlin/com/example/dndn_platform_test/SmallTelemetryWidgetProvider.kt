package com.example.dndn_platform_test

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SmallTelemetryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_telemetry_small).apply {
                val distance = widgetData.getString("total_distance_display", "0 m") ?: "0 m"
                val isTracking = widgetData.getBoolean("is_tracking", true)

                setTextViewText(R.id.tv_total_distance, distance)
                setTextViewText(R.id.tv_tracking_status, if (isTracking) "GPS Tracking Active" else "Tracking Paused")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

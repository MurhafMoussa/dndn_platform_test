package com.example.dndn_platform_test

import android.appwidget.AppWidgetManager
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class LargeTelemetryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_telemetry_large).apply {
                val distance = widgetData.getString("total_distance_display", "0 m") ?: "0 m"
                val waypoints = widgetData.getString("waypoints_count", "0 pts") ?: "0 pts"
                val isTracking = widgetData.getBoolean("is_tracking", true)
                val snapshotPath = widgetData.getString("map_snapshot_path", null)

                setTextViewText(R.id.tv_total_distance_large, distance)
                setTextViewText(R.id.tv_waypoints_count, waypoints)
                setTextViewText(R.id.tv_tracking_status_large, if (isTracking) "Live GPS Active" else "Paused")

                if (!snapshotPath.isNullOrEmpty()) {
                    val file = File(snapshotPath)
                    if (file.exists()) {
                        val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                        setImageViewBitmap(R.id.iv_map_snapshot, bitmap)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

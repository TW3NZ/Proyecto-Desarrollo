package com.example.my_daily_routine

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class TareasWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences,
    ) {
        val tasks = parseTasks(widgetData.getString("tareas_json", null))
        val completed = (0 until tasks.length()).count { tasks.optJSONObject(it)?.optBoolean("completada") == true }
        val pending = tasks.length() - completed
        val progress = if (tasks.length() == 0) 0 else completed * 100 / tasks.length()

        appWidgetIds.forEach { widgetId ->
            val serviceIntent = Intent(context, TareasWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            val views = RemoteViews(context.packageName, R.layout.tareas_widget).apply {
                setTextViewText(R.id.widget_pending_count, "$pending pendientes")
                setTextViewText(R.id.widget_completion_percent, "$progress% completado")
                setProgressBar(R.id.widget_progress, 100, progress, false)
                setRemoteAdapter(R.id.widget_task_list, serviceIntent)
                setEmptyView(R.id.widget_task_list, R.id.widget_empty)

                val clickIntent = Intent(context, MainActivity::class.java).apply {
                    action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                }
                val clickTemplate = PendingIntent.getActivity(
                    context,
                    widgetId,
                    clickIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                setPendingIntentTemplate(R.id.widget_task_list, clickTemplate)
            }
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_task_list)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun parseTasks(raw: String?): JSONArray = try {
        JSONArray(raw ?: "[]")
    } catch (_: Exception) {
        JSONArray()
    }
}

internal fun parseWidgetTasks(raw: String?): List<JSONObject> {
    return try {
        val array = JSONArray(raw ?: "[]")
        (0 until array.length()).mapNotNull { array.optJSONObject(it) }
    } catch (_: Exception) {
        emptyList()
    }
}

package com.example.my_daily_routine

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

class TareasWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TareasWidgetFactory(applicationContext, intent)
}

private class TareasWidgetFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val widgetId = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID,
    )
    private var tasks = emptyList<org.json.JSONObject>()

    override fun onCreate() = loadTasks()

    override fun onDataSetChanged() = loadTasks()

    private fun loadTasks() {
        val data = HomeWidgetPlugin.getData(context)
        tasks = parseWidgetTasks(data.getString("tareas_json", null))
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        val task = tasks[position]
        val completed = task.optBoolean("completada")
        val title = task.optString("titulo")
        val priority = task.optString("prioridad", "media")
        val priorityLabel: String
        val priorityColor: Int
        when (priority) {
            "alta" -> {
                priorityLabel = "Alta"
                priorityColor = 0xFFD94848.toInt()
            }
            "baja" -> {
                priorityLabel = "Baja"
                priorityColor = 0xFF32845B.toInt()
            }
            else -> {
                priorityLabel = "Media"
                priorityColor = 0xFFE28A20.toInt()
            }
        }

        return RemoteViews(context.packageName, R.layout.tareas_widget_row).apply {
            setTextViewText(R.id.widget_task_check, if (completed) "✓" else "○")
            setTextColor(R.id.widget_task_check, if (completed) 0xFF1769AA.toInt() else 0xFF8AA3BA.toInt())
            setTextViewText(R.id.widget_task_title, title)
            setTextColor(R.id.widget_task_title, if (completed) 0xFF8999A9.toInt() else 0xFF254565.toInt())
            setTextViewText(R.id.widget_task_priority, priorityLabel)
            setTextColor(R.id.widget_task_priority, priorityColor)
            setInt(R.id.widget_task_priority, "setBackgroundColor", 0xFFF1F5F9.toInt())

            val fillInIntent = Intent().apply {
                data = Uri.parse("dailyroutine://toggle-task?index=$position")
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            setOnClickFillInIntent(R.id.widget_task_row, fillInIntent)
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
    override fun onDestroy() { tasks = emptyList() }
}

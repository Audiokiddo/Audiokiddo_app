package pl.audiokiddo.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/**
 * Home-screen widget: what fits this part of the day, one tap away. The same parts of the
 * day as the Start card in the app (lib/features/home/today.dart, `dayPartOf`).
 */
class DayPartWidget : AppWidgetProvider() {
    private enum class Part(
        val title: Int,
        val subtitle: Int,
        val action: Int,
        val background: Int,
        val url: String,
        val mascot: Int,
        val night: Boolean = false,
    ) {
        MORNING(R.string.widget_morning_title, R.string.widget_morning_subtitle, R.string.widget_play,
            R.drawable.widget_bg_morning, "audiokiddo://open/", R.drawable.szop_rano),
        MIDDAY(R.string.widget_midday_title, R.string.widget_midday_subtitle, R.string.widget_play,
            R.drawable.widget_bg_midday, "audiokiddo://open/", R.drawable.szop_dzien),
        AFTERNOON(R.string.widget_afternoon_title, R.string.widget_afternoon_subtitle, R.string.widget_trip,
            R.drawable.widget_bg_afternoon, "audiokiddo://open/podroz", R.drawable.szop_droga),
        EVENING(R.string.widget_evening_title, R.string.widget_evening_subtitle, R.string.widget_bedtime,
            R.drawable.widget_bg_evening, "audiokiddo://open/dobranoc", R.drawable.szop_wieczor, night = true),
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val part = partOf(Calendar.getInstance())
        for (id in ids) manager.updateAppWidget(id, views(context, part))
        scheduleNextChange(context)
    }

    private fun views(context: Context, part: Part): RemoteViews {
        val ink = if (part.night) Color.WHITE else Color.parseColor("#231A16")
        // The child's week, written by the app (lib/features/home/home_widget_sync.dart).
        val data = HomeWidgetPlugin.getData(context)
        val line = data.getString("line", null).orEmpty()
        val notes = data.getString("notes", null)?.toIntOrNull()
        return RemoteViews(context.packageName, R.layout.day_part_widget).apply {
            setInt(R.id.widget_root, "setBackgroundResource", part.background)
            // Szop’en in his current look for this part of the day.
            setImageViewResource(R.id.widget_golden, part.mascot)
            // The play to start with one tap: the one stopped halfway, else today's from the plan.
            val resume = link(data, "resume")
            val next = link(data, "next")
            val main = resume?.let { Triple(context.getString(R.string.widget_resume), it.first, it) }
                ?: next?.let { Triple(context.getString(R.string.widget_today) + " · " + it.second, it.first, it) }
            // Szop’en's line of the day (written by the app); the built-in one until the app has run.
            val joke = data.getString("joke_${part.name.lowercase()}", null).orEmpty()
                .ifEmpty { context.getString(part.subtitle) }
            if (main != null) {
                setTextViewText(R.id.widget_title, main.second)
                setTextViewText(R.id.widget_subtitle, main.first)
                setTextViewText(R.id.widget_action, "▶ " + context.getString(R.string.widget_play))
                setTextViewText(R.id.widget_shortcut, context.getString(part.action))
                setOnClickPendingIntent(R.id.widget_action, open(context, main.third.third, 10 + part.ordinal))
                setOnClickPendingIntent(R.id.widget_shortcut, open(context, part.url, 20 + part.ordinal))
            } else {
                setTextViewText(R.id.widget_title, context.getString(part.title))
                setTextViewText(R.id.widget_subtitle, "„$joke”")
                setTextViewText(R.id.widget_action, context.getString(part.action))
                val other = if (part.night) "audiokiddo://open/podroz" else "audiokiddo://open/dobranoc"
                setTextViewText(R.id.widget_shortcut, context.getString(if (part.night) R.string.widget_trip else R.string.widget_bedtime))
                setOnClickPendingIntent(R.id.widget_action, open(context, part.url, 10 + part.ordinal))
                setOnClickPendingIntent(R.id.widget_shortcut, open(context, other, 20 + part.ordinal))
            }
            if (notes != null && line.isNotEmpty()) {
                // This week's melody: a filled dot for every note collected.
                setTextViewText(R.id.widget_notes, "●".repeat(notes.coerceIn(0, 7)) + "○".repeat(7 - notes.coerceIn(0, 7)))
                setContentDescription(R.id.widget_notes, context.getString(R.string.widget_notes, notes))
                setViewVisibility(R.id.widget_notes, View.VISIBLE)
                setViewVisibility(R.id.widget_brand, View.GONE)
            } else {
                setViewVisibility(R.id.widget_notes, View.GONE)
                setViewVisibility(R.id.widget_brand, View.VISIBLE)
            }
            for (view in listOf(R.id.widget_brand, R.id.widget_notes, R.id.widget_title, R.id.widget_subtitle, R.id.widget_action, R.id.widget_shortcut)) {
                setTextColor(view, ink)
            }
            setOnClickPendingIntent(R.id.widget_root, open(context, main?.third?.third ?: part.url, part.ordinal))
        }
    }

    /** A play the app wrote: (title, detail, audiokiddo:// url), or null. */
    private fun link(data: android.content.SharedPreferences, key: String): Triple<String, String, String>? {
        val title = data.getString("${key}_title", null).orEmpty()
        val path = data.getString("${key}_path", null).orEmpty()
        if (title.isEmpty() || path.isEmpty()) return null
        return Triple(title, data.getString("${key}_detail", null).orEmpty(), "audiokiddo://open$path")
    }

    private fun open(context: Context, url: String, code: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).setPackage(context.packageName)
        return PendingIntent.getActivity(
            context, code, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /** Refreshes the widget when the next part of the day begins (inexact; no permission needed). */
    private fun scheduleNextChange(context: Context) {
        val next = Calendar.getInstance().apply {
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            val hour = get(Calendar.HOUR_OF_DAY)
            val start = START_HOURS.firstOrNull { it > hour }
            if (start == null) {
                add(Calendar.DAY_OF_MONTH, 1)
                set(Calendar.HOUR_OF_DAY, START_HOURS.first())
            } else {
                set(Calendar.HOUR_OF_DAY, start)
            }
        }
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, DayPartWidget::class.java))
        val update = Intent(context, DayPartWidget::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        val pending = PendingIntent.getBroadcast(
            context, 0, update,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        context.getSystemService(AlarmManager::class.java)?.set(AlarmManager.RTC, next.timeInMillis, pending)
    }

    private companion object {
        val START_HOURS = listOf(5, 11, 15, 19)

        fun partOf(now: Calendar): Part = when (now.get(Calendar.HOUR_OF_DAY)) {
            in 5..10 -> Part.MORNING
            in 11..14 -> Part.MIDDAY
            in 15..18 -> Part.AFTERNOON
            else -> Part.EVENING
        }
    }
}

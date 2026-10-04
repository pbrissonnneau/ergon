package app.ergon.ergon.widget

import android.content.Context
import org.json.JSONObject
import java.util.TimeZone

/** One agenda line as published by the Flutter side. */
data class WidgetItem(
    val id: Int,
    val title: String,
    val epochDay: Long?,
    val time: String?,
    val priority: Int,
    val ongoing: Boolean,
    val missed: Int,
)

/**
 * Persists the agenda snapshot pushed by the app. The widget re-evaluates the
 * snapshot against the *current* day, so it stays correct after midnight even
 * if the app has not run since.
 */
object WidgetStore {
    private const val PREFS = "ergon_widget"
    private const val KEY = "agenda"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
    }

    fun load(context: Context): List<WidgetItem> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return emptyList()
        return try {
            val items = JSONObject(raw).getJSONArray("items")
            (0 until items.length()).map { i ->
                val o = items.getJSONObject(i)
                WidgetItem(
                    id = o.getInt("id"),
                    title = o.getString("t"),
                    epochDay = if (o.has("d")) o.getLong("d") else null,
                    time = if (o.has("m")) o.getString("m") else null,
                    priority = o.optInt("p", 1),
                    ongoing = o.optBoolean("o", false),
                    missed = o.optInt("x", 0),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Current civil day in the device timezone, as days since 1970-01-01. */
    fun today(): Long {
        val now = System.currentTimeMillis()
        return Math.floorDiv(now + TimeZone.getDefault().getOffset(now), 86_400_000L)
    }

    /** Items relevant today: due today, ongoing, then overdue. */
    fun visible(context: Context): List<WidgetItem> {
        val today = today()
        val relevant = load(context).filter { it.epochDay == null || it.epochDay <= today }
        return relevant.sortedBy { if (it.epochDay != null && it.epochDay < today) 1 else 0 }
    }
}

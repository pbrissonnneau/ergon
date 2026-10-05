package app.ergon.ergon.widget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import app.ergon.ergon.MainActivity
import app.ergon.ergon.R

class AgendaWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var items: List<WidgetItem> = emptyList()
        private var today = 0L

        override fun onCreate() {}
        override fun onDestroy() {}

        override fun onDataSetChanged() {
            items = WidgetStore.visible(context)
            today = WidgetStore.today()
        }

        override fun getCount() = items.size
        override fun getViewTypeCount() = 1
        override fun hasStableIds() = true
        override fun getItemId(position: Int) = items.getOrNull(position)?.id?.toLong() ?: position.toLong()
        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_item)
            val item = items.getOrNull(position) ?: return views
            val overdue = item.epochDay != null && item.epochDay < today
            views.setTextViewText(R.id.item_title, item.title)
            views.setTextColor(
                R.id.item_title,
                if (overdue) context.getColor(R.color.widget_overdue) else context.getColor(R.color.widget_text),
            )
            val meta = when {
                overdue -> if (item.missed > 0) "Overdue +${item.missed}" else "Overdue"
                item.time != null -> item.time
                item.ongoing -> "Ongoing"
                else -> ""
            }
            views.setTextViewText(R.id.item_meta, meta)
            // Bar = project colour; tasks without a project fall back to priority.
            views.setInt(R.id.item_bar, "setColorFilter", item.color ?: priorityColor(item.priority))
            views.setOnClickFillInIntent(
                R.id.item_root,
                Intent().putExtra(MainActivity.EXTRA_TASK_ID, item.id),
            )
            return views
        }

        private fun priorityColor(p: Int) = when (p) {
            0 -> Color.parseColor("#868E96")
            2 -> Color.parseColor("#F08C00")
            3 -> Color.parseColor("#E03131")
            else -> Color.parseColor("#4F5BD5")
        }
    }
}

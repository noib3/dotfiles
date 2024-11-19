import { App, Gdk, Gtk } from "astal/gtk3"
import style from "./style.scss"
import Bar from "./widget/Bar"

function main() {
  const bars = new Map<Gdk.Monitor, Gtk.Widget>()

  for (const gdkmonitor of App.get_monitors()) {
    bars.set(gdkmonitor, Bar(gdkmonitor))
  }

  App.connect("monitor-added", (_, gdkmonitor) => {
    bars.set(gdkmonitor, Bar(gdkmonitor))
  })

  App.connect("monitor-removed", (_, gdkmonitor) => {
    bars.get(gdkmonitor)?.destroy()
    bars.delete(gdkmonitor)
  })
}

App.start({
  css: style,
  main
})

import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"

const date = Variable("").poll(1000, "date +'%a %-d %b'")
const time = Variable("").poll(1000, "date +'%-H:%M'")

export default function Bar(gdkmonitor: Gdk.Monitor) {
  return <window
    className="Bar"
    gdkmonitor={gdkmonitor}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={Astal.WindowAnchor.TOP
      | Astal.WindowAnchor.LEFT
      | Astal.WindowAnchor.RIGHT}
    application={App}>
    <centerbox heightRequest={28}>
      <box className="workspaces" />
      <box className="media" />
      <box
        className="clock"
        halign={Gtk.Align.END}
        marginRight={16}
        spacing={8}
      >
        <label className="date" label={date()} />
        <label className="time" label={time()} />
      </box>
    </centerbox>
  </window>
}

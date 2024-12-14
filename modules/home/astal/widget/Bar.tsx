import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, bind } from "astal"
import Hyprland from "gi://AstalHyprland"

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
      <box halign={Gtk.Align.START}>
        <Workspaces />
      </box>
      <box className="media" />
      <box halign={Gtk.Align.END} marginRight={16}>
        <Clock />
      </box>
    </centerbox>
  </window>
}

function Workspaces() {
  const hypr = Hyprland.get_default()
  return <box className="workspaces">
    {bind(hypr, "workspaces").as(workspaces => (
      workspaces
        .sort((w1, w2) => w1.id - w2.id)
        .map(workspace => (
          <button
            className={bind(hypr, "focusedWorkspace").as(focused => (
              workspace === focused ? "focusedWorkspace" : ""
            ))}
            onClicked={() => workspace.focus()}>
            {workspace.id}
          </button>
        ))
    ))}
  </box>
}

function Clock() {
  return <box
    className="clock"
    spacing={8}
  >
    <Date />
    <Time />
  </box>
}

function Date() {
  const date = Variable("").poll(1000, "date +'%a %-d %b'")
  return <label
    className="date"
    label={date()}
  />
}

function Time() {
  const time = Variable("").poll(1000, "date +'%-H:%M'")
  return <label
    className="time"
    label={time()}
  />
}

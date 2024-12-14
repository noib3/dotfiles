import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, bind } from "astal"
import Battery from "gi://AstalBattery"
import Bluetooth from "gi://AstalBluetooth"
import Hyprland from "gi://AstalHyprland"
import Network from "gi://AstalNetwork"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  return <window
    className="Bar"
    gdkmonitor={gdkmonitor}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={Astal.WindowAnchor.TOP
      | Astal.WindowAnchor.LEFT
      | Astal.WindowAnchor.RIGHT}
    application={App}>
    <centerbox heightRequest={32}>
      <box halign={Gtk.Align.START}>
        <Workspaces />
      </box>
      <box className="media" />
      <box halign={Gtk.Align.END} marginRight={16}>
        <BluetoothStatus />
        <Wifi />
        <BatteryStatus />
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

function BluetoothStatus() {
  const bluetooth = Bluetooth.get_default()
  const isPowered = bind(bluetooth, "isPowered")
  const devices = bind(bluetooth, "devices")
  const numDevices = Variable.derive(
    [isPowered, devices],
    (isPowered, devices) => (
      isPowered && devices.filter(device => device.connected).length
    )
  )

  // Can't get mouse and keyboard to auto-connect after idle w/o these.
  bluetooth.adapter.start_discovery()
  bluetooth.adapter.set_discoverable(true)
  bluetooth.adapter.set_pairable(true)

  return <box className="bluetooth">
    <icon
      icon={isPowered.as(isPowered => (
        `bluetooth-${isPowered ? "active" : "disabled" }-symbolic`
      ))}
    />
    <label label={bind(numDevices).as(String)} />
  </box>
}

function Wifi() {
  const { wifi } = Network.get_default()

  return <icon
    className="wifi"
    toolTipText={bind(wifi, "ssid").as(String)}
    icon={bind(wifi, "iconName")}
  />
}

function BatteryStatus() {
  const battery = Battery.get_default()

  return <box
    className="battery"
    visible={bind(battery, "isPresent")}
    marginRight={16}
  >
    <icon icon={bind(battery, "batteryIconName")} />
    <label
      label={bind(battery, "percentage").as(percentage => (
        `${Math.round(percentage * 100)}%`
      ))}
    />
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

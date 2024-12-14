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
      <box halign={Gtk.Align.END}>
        <BluetoothStatus />
        <WiFi />
        <BatteryStatus />
        <Clock />
      </box>
    </centerbox>
  </window>
}

function Workspaces() {
  const hypr = Hyprland.get_default()

  return <box className="Workspaces">
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

  return <box className="BluetoothStatus">
    <icon
      className="bluetoothIcon"
      icon={isPowered.as(isPowered => (
        `bluetooth-${isPowered ? "active" : "disabled" }-symbolic`
      ))}
    />
    <label label={bind(numDevices).as(String)} />
  </box>
}

function WiFi() {
  const { wifi } = Network.get_default()

  return <box className="WiFi">
    <icon
      className="WiFiIcon"
      icon={bind(wifi, "iconName")}
    />
    <label
      visible={bind(wifi, "enabled")}
      label={bind(wifi, "ssid")}
    />
  </box>
}

function BatteryStatus() {
  const battery = Battery.get_default()

  return <box
    className="BatteryStatus"
    visible={bind(battery, "isPresent")}
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
  return <box className="Clock">
    <Date />
    <Time />
  </box>
}

function Date() {
  const date = Variable("").poll(1000, "date +'%a %-d %b'")

  return <label
    className="Date"
    label={date()}
  />
}

function Time() {
  const time = Variable("").poll(1000, "date +'%-H:%M'")

  return <label
    className="Time"
    label={time()}
  />
}

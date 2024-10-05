// const hyprland = await Service.import("hyprland")
// const notifications = await Service.import("notifications")
// const mpris = await Service.import("mpris")
// const audio = await Service.import("audio")
// const battery = await Service.import("battery")
// const systemtray = await Service.import("systemtray")

const date = Variable("", {
  poll: [500, 'date +"%a %-d %b"'],
})

const time = Variable("", {
  poll: [500, 'date +"%-H:%M"'],
})

const Bar = (monitor: number) => Widget.Window({
  monitor,
  name: `bar${monitor}`,
  class_name: "bar",
  anchor: ['top', 'left', 'right'],
  exclusivity: 'exclusive',
  child: Widget.CenterBox({
    "height-request": 28,
    start_widget: Widget.Label({
      class_name: "workspaces",
      label: "",
    }),
    center_widget: Widget.Label({
      class_name: "media",
      label: "",
    }),
    end_widget: Clock(),
  }),
})

function Clock() {
  return Widget.Box({
    hpack: "end",
    spacing: 8,
    "margin-right": 16,
    children: [
      Date(),
      Time(),
    ],
  })
}

function Date() {
  return Widget.Label({
    class_name: "date",
    label: date.bind(),
  })
}

function Time() {
  return Widget.Label({
    class_name: "time",
    label: time.bind(),
  })
}

export default Bar;

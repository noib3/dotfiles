import Progress from "./Progress"

const audio = await Service.import("audio")

const DELAY = 2500

function OnScreenProgress(vertical: boolean) {
    const indicator = Widget.Icon({
        size: 42,
        vpack: "start",
    })

    const progress = Progress({
        vertical,
        width: vertical ? 42 : 300,
        height: vertical ? 300 : 42,
        child: indicator,
    })

    const revealer = Widget.Revealer({
        transition: "slide_left",
        child: progress,
    })

    let count = 0

    function show(value: number) {
        revealer.reveal_child = true
        progress.setValue(value)
        count++
        Utils.timeout(DELAY, () => {
            count--

            if (count === 0)
                revealer.reveal_child = false
        })
    }

    return revealer
        .hook(audio.speaker, () => show(
            audio.speaker.volume,
        ), "notify::volume")
}

const OSD = (monitor: number) => Widget.Window({
  monitor,
  name: `indicator${monitor}`,
  class_name: "indicator",
  layer: "overlay",
  click_through: true,
  anchor: ["right", "left", "top", "bottom"],
  child: Widget.Box({
    css: "padding: 2px;",
    expand: true,
    child: Widget.Overlay(
      { child: Widget.Box({ expand: true }) },
      Widget.Box({
        hpack: "center",
        vpack: "center",
        child: OnScreenProgress(false),
      }),
    ),
  }),
})

export default OSD;

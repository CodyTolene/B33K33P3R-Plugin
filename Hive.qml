import QtQuick
import Quickshell
import Quickshell.Io

// The connection to the B33K33P3R app. The app listens on a socket in the
// runtime folder, pushes its status whenever it changes, and answers one line
// of JSON per request. Nothing here runs a task. The app does all of that.
Item {
  id: root
  visible: false

  readonly property string socketPath: {
    var chosen = Quickshell.env("B33K33P3R_HIVE_SOCKET")
    if (chosen) return String(chosen)
    var runtime = Quickshell.env("XDG_RUNTIME_DIR")
    return runtime ? String(runtime) + "/b33k33p3r/hive.sock" : ""
  }

  // True once the app has told us its status, not when the socket opens.
  property bool online: false
  property var status: ({})
  property string lastError: ""
  // Connects refused in a row. A socket file nobody answers on is left over
  // from an app that didn't close cleanly, so ask it less often.
  property int refusals: 0

  readonly property string phase: online ? String(status.state || "standby") : "offline"
  readonly property bool busy: online && status.busy === true
  readonly property bool waiting: phase === "waiting"
  readonly property bool running: phase === "running"
  readonly property bool pausable: busy && (phase === "running" || phase === "pausing" || phase === "paused")
  readonly property bool resumes: phase === "paused" || phase === "pausing"
  readonly property bool stoppable: busy && phase !== "stopping"
  readonly property string bee: online ? String(status.bee || "") : ""
  readonly property int turns: online ? Number(status.turns || 0) : 0
  readonly property int turnBudget: online ? Number(status.turn_budget || 0) : 0
  readonly property string prompt: online ? String(status.prompt || "") : ""
  readonly property string question: online ? String(status.question || "") : ""
  readonly property string questionFrom: online ? String(status.question_from || "") : ""
  readonly property string result: online ? String(status.result || "") : ""
  // Older apps don't say, and that reads as subscribed.
  readonly property bool freePlan: online && status.subscribed === false

  function request(action, text) {
    lastError = ""
    if (!socket.connected) {
      lastError = "B33K33P3R isn't running."
      return
    }
    var message = { "do": action }
    if (text !== undefined) message.text = String(text)
    socket.write(JSON.stringify(message) + "\n")
    socket.flush()
  }

  function send(text) { request("send", text) }
  function pause() { request("pause") }
  function stop() { request("stop") }

  // The app's own window size on Linux (DEFAULT_WINDOW_SIZES in the app).
  readonly property string windowClass: "local.omarchy.B33K33P3R"
  readonly property int nativeWidth: 888
  readonly property int nativeHeight: 1000

  // Hyprland tiles new windows, which stretches the app across the whole
  // workspace. Float it at its native size, centred, once its window exists.
  // On a screen too short for that, it takes all the height the bar and gaps
  // leave and keeps its shape. A window that's already floating keeps
  // whatever size it has now.
  // Lua dispatchers first (Hyprland 0.55+), classic ones as the fallback.
  readonly property string floatScript: `
    class="$1"; width="$2"; height="$3"
    exec >>"\${XDG_RUNTIME_DIR:-/tmp}/b33k33p3r-float.log" 2>&1
    echo "$(date +%T.%N) start PATH=$PATH"
    command -v hyprctl >/dev/null && command -v jq >/dev/null || { echo "missing hyprctl/jq"; exit 0; }
    for _ in $(seq 50); do
      read -r address floating < <(hyprctl clients -j 2>/dev/null |
        jq -r --arg c "$class" 'first(.[] | select(.class == $c)) | "\\(.address) \\(.floating)"')
      [ -n "$address" ] && break
      sleep 0.2
    done
    echo "$(date +%T.%N) window address=$address floating=$floating"
    [ -n "$address" ] && [ "$floating" = "false" ] || exit 0
    win="address:$address"
    # The focused monitor's height in layout pixels, less the bar, the gaps
    # and the window border; the width scales with it to keep the shape.
    read -r screen_w screen_h < <(hyprctl monitors -j 2>/dev/null | jq -r '
      first(.[] | select(.focused)) |
      (if (.transform % 2) == 1 then [.height, .width] else [.width, .height] end) as $s |
      "\\(($s[0] / .scale) - .reserved[0] - .reserved[2] | floor) \\(($s[1] / .scale) - .reserved[1] - .reserved[3] | floor)"')
    gaps=$(hyprctl getoption general:gaps_out -j 2>/dev/null | jq -r '.css // .int // 0')
    read -r gap_t gap_r gap_b gap_l <<<"$gaps"
    gap_r=\${gap_r:-$gap_t}; gap_b=\${gap_b:-$gap_t}; gap_l=\${gap_l:-$gap_r}
    border=$(hyprctl getoption general:border_size -j 2>/dev/null | jq -r '.int // 0')
    if [ -n "$screen_h" ]; then
      room_h=$(( screen_h - gap_t - gap_b - 2 * border ))
      room_w=$(( screen_w - gap_l - gap_r - 2 * border ))
      if [ "$height" -gt "$room_h" ]; then
        width=$(( width * room_h / height )); height=$room_h
      fi
      if [ "$width" -gt "$room_w" ]; then
        height=$(( height * room_w / width )); width=$room_w
      fi
    fi
    echo "$(date +%T.%N) size \${width}x\${height} (room \${room_w:-?}x\${room_h:-?})"
    run() { local lua="$1"; shift; hyprctl dispatch "$lua" >/dev/null 2>&1 || hyprctl dispatch "$@" >/dev/null 2>&1; }
    run "hl.dsp.window.float({ action = \\"on\\", window = \\"$win\\" })" setfloating "$win"
    run "hl.dsp.window.resize({ x = $width, y = $height, window = \\"$win\\" })" resizewindowpixel exact "$width $height,$win"
    run "hl.dsp.window.center({ window = \\"$win\\" })" centerwindow
  `

  function floatWindow() {
    Quickshell.execDetached(["bash", "-c", floatScript, "b33k33p3r-float",
      windowClass, String(nativeWidth), String(nativeHeight)])
  }

  // Raise the app's window, or start the app when it isn't running, then
  // float it at its native size rather than tiled full-workspace.
  function openApp() {
    if (online) request("show")
    else Quickshell.execDetached(["gtk-launch", windowClass])
    floatWindow()
  }

  function receive(line) {
    var message = null
    try {
      message = JSON.parse(line)
    } catch (error) {
      return
    }
    if (!message || typeof message !== "object") return
    if (message.status && typeof message.status === "object") {
      status = message.status
      online = true
    }
    if (message.ok === false) lastError = String(message.error || "B33K33P3R said no.")
  }

  function reset() {
    online = false
    status = ({})
  }

  Socket {
    id: socket
    path: root.socketPath
    parser: SplitParser {
      onRead: function(line) { root.receive(line) }
    }
    onConnectedChanged: {
      if (connected) {
        root.refusals = 0
        root.request("status")
      } else {
        root.reset()
      }
    }
    onError: root.refusals++
  }

  // The shell logs every connect that fails, and the app is often closed, so
  // only knock once the socket file is there.
  Process {
    id: probe
    command: ["test", "-S", root.socketPath]
    onExited: function(code) {
      if (code === 0) socket.connected = true
      else root.refusals = 0
    }
  }

  Timer {
    interval: root.refusals >= 2 ? 30000 : 3000
    repeat: true
    triggeredOnStart: true
    running: root.socketPath !== "" && !socket.connected
    onTriggered: if (!probe.running) probe.running = true
  }
}

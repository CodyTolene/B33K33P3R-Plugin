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

  readonly property string phase: online ? String(status.state || "standby") : "offline"
  readonly property bool busy: online && status.busy === true
  readonly property bool waiting: phase === "waiting"
  readonly property bool pausable: busy && (phase === "running" || phase === "pausing" || phase === "paused")
  readonly property bool resumes: phase === "paused" || phase === "pausing"
  readonly property bool stoppable: busy && phase !== "stopping"
  readonly property string bee: online ? String(status.bee || "") : ""
  readonly property int turns: online ? Number(status.turns || 0) : 0
  readonly property string prompt: online ? String(status.prompt || "") : ""
  readonly property string question: online ? String(status.question || "") : ""
  readonly property string questionFrom: online ? String(status.question_from || "") : ""
  readonly property string result: online ? String(status.result || "") : ""

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

  // Raise the app's window, or start the app when it isn't running.
  function openApp() {
    if (online) request("show")
    else Quickshell.execDetached(["gtk-launch", "local.omarchy.B33K33P3R"])
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
      if (connected) root.request("status")
      else root.reset()
    }
  }

  // The app comes and goes. Keep knocking until it answers.
  Timer {
    interval: 3000
    repeat: true
    triggeredOnStart: true
    running: root.socketPath !== "" && !socket.connected
    onTriggered: socket.connected = true
  }
}

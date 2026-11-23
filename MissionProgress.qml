import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons

// The app's Mission Progress strip, small: turns done and the turn budget,
// then a chain of hive cells. One cell sweeps along it while the colony
// works, and they all fill once the mission is done.
Column {
  id: root

  property int turns: 0
  property int turnBudget: 0
  property string phase: "standby"
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family

  readonly property int cells: 15
  readonly property bool sweeping: phase === "running"
  readonly property bool done: phase === "completed"
  readonly property color dim: Qt.darker(foreground, 1.4)
  property int lit: -1

  spacing: Style.space(6)

  function pad(number) {
    var text = String(Math.max(0, number))
    while (text.length < 3) text = "0" + text
    return text
  }

  Item {
    width: parent.width
    height: turnsText.implicitHeight

    Text {
      id: turnsText
      textFormat: Text.PlainText
      text: root.pad(root.turns) + " TURNS DONE"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
    }

    Text {
      textFormat: Text.PlainText
      anchors.right: parent.right
      anchors.left: turnsText.right
      anchors.leftMargin: Style.space(8)
      horizontalAlignment: Text.AlignRight
      visible: root.turnBudget > 0
      text: "TURN BUDGET " + root.pad(root.turnBudget)
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 1.2
      elide: Text.ElideRight
    }
  }

  Item {
    id: track
    width: parent.width
    height: Math.round(radius * 2)

    readonly property real radius: Math.max(4, Math.min(Style.space(7), width / (root.cells * 2.6)))
    readonly property real step: (width - radius * 2) / (root.cells - 1)

    Rectangle {
      x: track.radius
      width: track.width - track.radius * 2
      height: Math.max(1, Math.round(track.radius * 0.25))
      anchors.verticalCenter: parent.verticalCenter
      color: root.foreground
      opacity: 0.45
    }

    Repeater {
      model: root.cells

      Shape {
        id: cell
        readonly property bool on: root.done || index === root.lit
        x: index * track.step
        width: track.radius * 2
        height: track.radius * 2
        preferredRendererType: Shape.CurveRenderer
        opacity: on ? 1 : 0.4

        ShapePath {
          strokeColor: root.foreground
          strokeWidth: Math.max(1, track.radius * 0.28)
          fillColor: cell.on ? root.foreground : Commons.Color.popups.background
          joinStyle: ShapePath.MiterJoin
          PathPolyline {
            path: {
              var r = track.radius * 0.86
              var points = []
              for (var step = 0; step <= 6; step++) {
                var angle = Math.PI / 3 * step
                points.push(Qt.point(track.radius + Math.cos(angle) * r, track.radius + Math.sin(angle) * r))
              }
              return points
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 333
    repeat: true
    running: root.sweeping && root.visible
    onRunningChanged: if (!running) root.lit = -1
    onTriggered: root.lit = (root.lit + 1) % root.cells
  }
}

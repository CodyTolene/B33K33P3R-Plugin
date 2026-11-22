import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons

// A hive cell like the ones on the app's Hive Map: a flat-topped hexagon
// outline with a smaller cell inside. The inner cell is lit while the app is
// up and breathes while the colony works.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Commons.Color.foreground
  property color badgeColor: Commons.Color.urgent
  // A dot in the corner, for when a bee is waiting on an answer.
  property bool badge: false
  property bool lit: true
  property bool pulsing: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  // Corners of a flat-topped hexagon of radius r around the icon's center.
  function corners(r) {
    var points = []
    for (var step = 0; step < 6; step++) {
      var angle = Math.PI / 3 * step
      points.push(Qt.point(iconSize / 2 + Math.cos(angle) * r, iconSize / 2 + Math.sin(angle) * r))
    }
    points.push(points[0])
    return points
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.color
      strokeWidth: Math.max(1.5, root.iconSize * 0.11)
      fillColor: "transparent"
      joinStyle: ShapePath.MiterJoin
      PathPolyline { path: root.corners(root.iconSize * 0.44) }
    }
  }

  Shape {
    id: core
    anchors.fill: parent
    visible: root.lit
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: "transparent"
      fillColor: root.color
      PathPolyline { path: root.corners(root.iconSize * 0.22) }
    }

    SequentialAnimation on opacity {
      running: root.pulsing
      loops: Animation.Infinite
      onRunningChanged: if (!running) core.opacity = 1
      NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
      NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
    }
  }

  Rectangle {
    visible: root.badge
    width: Math.max(5, root.iconSize * 0.4)
    height: width
    radius: width / 2
    color: root.badgeColor
    anchors.right: parent.right
    anchors.top: parent.top
  }
}

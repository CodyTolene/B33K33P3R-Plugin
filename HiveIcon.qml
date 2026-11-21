import QtQuick
import qs.Commons
import qs.Commons as Commons

// A honeycomb cell. Three bars turned 60 degrees apart overlap into a hexagon,
// which stays sharp at bar size where a tiny SVG wouldn't.
Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Commons.Color.foreground
  property color badgeColor: Commons.Color.urgent
  // A dot in the corner, for when a bee is waiting on an answer.
  property bool badge: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Repeater {
    model: [0, 60, -60]

    Rectangle {
      anchors.centerIn: parent
      width: root.iconSize * 0.866
      height: root.iconSize * 0.5
      rotation: modelData
      color: root.color
      antialiasing: true
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

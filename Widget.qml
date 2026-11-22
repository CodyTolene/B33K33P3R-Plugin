import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Panel {
  id: root
  moduleName: "codytolene.b33k33p3r"
  ipcTarget: "codytolene.b33k33p3r"

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  // Faded while the app is closed, so the bar shows it at a glance.
  readonly property color barIconColor: hive.online ? barForeground : Qt.darker(barForeground, 1.55)

  // The app's own words for each state.
  readonly property var phaseLabels: ({
    "offline": "Offline",
    "standby": "Standby",
    "running": "Running",
    "pausing": "Pausing",
    "paused": "Paused",
    "waiting": "Waiting on you",
    "stopping": "Stopping",
    "stopped": "Stopped",
    "completed": "Complete",
    "failed": "Failed"
  })
  readonly property string phaseText: phaseLabels[hive.phase] || hive.phase

  readonly property string metaText: {
    if (!hive.online) return "Not running"
    if (!hive.busy) return hive.prompt !== "" ? "Last mission" : "Ready for a mission"
    if (hive.bee !== "") return hive.bee
    return "Queen / Command"
  }

  readonly property string inputHint: {
    if (hive.waiting) return "Answer the bee"
    if (hive.busy) return "Message the Queen"
    return "What should the colony do?"
  }

  readonly property string sendLabel: {
    if (hive.waiting) return "Reply"
    if (hive.busy) return "Send"
    return "Start"
  }

  function submit(field) {
    var text = String(field.text || "").trim()
    if (text === "") return
    hive.send(text)
    field.text = ""
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    hive.lastError = ""
    Qt.callLater(function() {
      if (panel.loadedContent && panel.loadedContent.input) panel.loadedContent.input.forceActiveFocus()
    })
  }

  Hive {
    id: hive
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        HiveIcon {
          x: (parent.width - width) / 2
          y: (parent.height - height) / 2
          iconSize: button.iconSize
          color: root.barIconColor
          badgeColor: root.urgent
          badge: hive.waiting
          lit: hive.online
          pulsing: hive.running
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) hive.openApp()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    content: PanelKeyCatcher {
      id: keyCatcher
      property alias input: input
      implicitHeight: column.implicitHeight
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "B33K33P3R"
          meta: root.metaText
          detail: hive.online ? root.phaseText.toUpperCase() : ""
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: hive.online ? 1.0 : 0.5
          iconComponent: Component {
            HiveIcon {
              iconSize: Style.font.display
              color: root.foreground
              badgeColor: root.urgent
              badge: hive.waiting
              lit: hive.online
              pulsing: hive.running
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: !hive.online
          width: parent.width
          text: "Open the app to bring the hive online."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Text {
          textFormat: Text.PlainText
          visible: hive.freePlan
          width: parent.width
          text: "You're on the free plan. Subscribe in the app to unlock every bee."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Text {
          textFormat: Text.PlainText
          visible: hive.lastError !== ""
          width: parent.width
          text: hive.lastError
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Column {
          visible: hive.waiting && hive.question !== ""
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: (hive.questionFrom !== "" ? hive.questionFrom : "A bee").toUpperCase() + " ASKS"
            foreground: root.foreground
            font.letterSpacing: 1.2
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: hive.question
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            maximumLineCount: 8
            elide: Text.ElideRight
          }
        }

        Column {
          visible: hive.online && hive.prompt !== "" && !hive.waiting
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "MISSION BRIEF"
            foreground: root.foreground
            font.letterSpacing: 1.2
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: hive.prompt
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
          }
        }

        Column {
          visible: hive.online && !hive.busy && hive.result !== ""
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: hive.phase === "completed" ? "MISSION COMPLETE"
              : hive.phase === "failed" ? "MISSION FAILED"
              : hive.phase === "stopped" ? "MISSION STOPPED"
              : "MISSION REPORT"
            foreground: root.foreground
            font.letterSpacing: 1.2
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: hive.result
            color: hive.phase === "failed" ? root.urgent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
            maximumLineCount: 6
            elide: Text.ElideRight
          }
        }

        MissionProgress {
          visible: hive.online && (hive.busy || hive.prompt !== "")
          width: parent.width
          turns: hive.turns
          turnBudget: hive.turnBudget
          phase: hive.phase
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        PanelSeparator {
          foreground: root.foreground
        }

        TextField {
          id: input
          visible: hive.online
          width: parent.width
          enabled: hive.phase !== "stopping"
          placeholderText: root.inputHint
          foreground: root.foreground
          onAccepted: root.submit(input)
          Keys.onEscapePressed: root.close()
        }

        Row {
          spacing: Style.space(8)

          Button {
            visible: hive.online
            text: root.sendLabel
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.submit(input)
          }

          Button {
            visible: hive.pausable
            text: hive.resumes ? "Resume" : "Pause"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: hive.pause()
          }

          Button {
            visible: hive.stoppable
            text: "Stop"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: hive.stop()
          }

          Button {
            text: hive.online ? "Open app" : "Open B33K33P3R"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: {
              hive.openApp()
              root.close()
            }
          }
        }
      }
    }
  }
}

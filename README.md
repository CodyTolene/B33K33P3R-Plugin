# B33K33P3R for Omarchy

A bar widget for [B33K33P3R](https://b33k33p3r.com), the desktop app that puts a colony of AI coding bees to work on a task.

I wanted to keep an eye on a running task without leaving the app open on a workspace. This puts a honeycomb in the Omarchy bar and a small panel behind it.

## What it does

- Shows what the colony is doing: standing by, working, paused, or waiting on you.
- Puts a dot on the bar icon when a bee has a question, and pulses the icon while the colony works.
- Shows the mission brief, turns done and the turn budget, and the result when it's done, in the same hive cells as the app's Mission Progress strip.
- Tells you when you're on the free plan.
- Lets you start a task, answer a question, or send the Queen a message from the panel.
- Pause, resume and stop.
- Opens the app, or brings its window forward if it's already running.

The widget doesn't run anything. The app does all the work and the widget talks to it, so your plan, providers and settings are whatever the app says they are.

## What you need

- Omarchy with the Quickshell shell (the one with `omarchy plugin`).
- B33K33P3R for Linux, a version with the bar widget socket. Get it from [b33k33p3r.com](https://b33k33p3r.com).
- `hyprctl` and `jq` to float the app's window when the widget opens it. Omarchy ships both. Without them the window just opens tiled.

## Install

```bash
omarchy plugin add https://github.com/CodyTolene/B33K33P3R-Plugin.git --enable
```

Omarchy warns you that plugins run unsandboxed inside the shell. That's true of this one too, so have a read through the code first. It's four small QML files.

The widget lands on the right side of the bar. Move it with `omarchy bar move codytolene.b33k33p3r`.

To update or remove it:

```bash
omarchy plugin update codytolene.b33k33p3r
omarchy plugin remove codytolene.b33k33p3r
```

## Using it

- Left click the honeycomb to open the panel.
- Right click it to open the app.
- Type in the box and press Enter. With nothing running that starts a task. While the colony is working it goes to the Queen, and when a bee is waiting it's your answer.
- With the app closed, Enter opens it.
- Esc closes the panel.

A task started from the panel uses the crew and folders you last picked in the app. If you want a different crew or project folder, set it there first.

To toggle the panel from a keybinding:

```bash
omarchy-shell codytolene.b33k33p3r toggle
```

## How it talks to the app

While it's running, B33K33P3R listens on a Unix socket at `$XDG_RUNTIME_DIR/b33k33p3r/hive.sock`. Only your user can open it. The app pushes a line of JSON whenever its status changes, and the widget sends a line of JSON to ask for something:

```json
{"do": "send", "text": "Fix the failing test"}
```

The actions are `status`, `send`, `pause`, `stop` and `show`. Nothing leaves your computer, and the widget makes no network requests.

If the app isn't running the icon fades to an empty cell and the panel offers to open it. The widget checks for the socket every few seconds and only connects once it's there, so it stays quiet in your logs while the app is closed. The widget starts the app with `gtk-launch local.omarchy.B33K33P3R`, which is the desktop entry the Linux installer adds. On Hyprland, opening the app from the widget floats its window at the app's native size (888×1000), centred, instead of tiling it across the workspace. On a screen too short for that it takes all the height the bar and gaps leave and scales the width to keep the same shape. A window you've already floated keeps its size. This only moves and sizes the window while it's open, and doesn't touch your Hyprland config. Each time it runs it adds a few lines to `$XDG_RUNTIME_DIR/b33k33p3r-float.log`, which is the only file the widget writes and is cleared when you reboot.

Set `B33K33P3R_HIVE_SOCKET` if you need the socket somewhere else. The app and the widget both read it.

## Files

- `manifest.json` tells Omarchy what this is.
- `Widget.qml` is the bar icon and the panel.
- `Hive.qml` is the socket connection.
- `HiveIcon.qml` draws the hive cell icon.
- `MissionProgress.qml` is the turns and progress strip.

## License

MIT. See [LICENSE](LICENSE).

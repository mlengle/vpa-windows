# VPA for Windows — How to run

**VGA Planets Assistant (VPA) 3.67**, native Windows build.

VPA is a helper/client for the classic play-by-email strategy game **VGA Planets 3**:
it loads your turn (`RST`), lets you review the star map, planets, ships, bases,
messages, and the combat simulator, and writes your orders back into a turn file
(`TRN`). This is a faithful native Windows port of the original DOS program — same
look, same keys.

> This is the **player's guide** for the built package. To compile it, see
> [`BUILD.md`](BUILD.md).

---

## 1. What you need

- **Windows** (any version SDL 3 supports; `VPA.exe` is 32-bit and runs on
  32- and 64-bit Windows).
- The **package** (`build\vpa-windows_package\` after
  `.\build-windows.ps1 package`):

  | File | What for |
  |---|---|
  | `VPA.exe` | The program. |
  | `plugins\vpagraph-sdl3.dll` | The graphics plugin VPA draws through. **VPA won't start without it.** |
  | `plugins\SDL3.dll` | SDL 3.4.16, used by the plugin (licence in `LICENSE.SDL3.txt`). |
  | `DISTTABL.DAT` | A precomputed distance table. **Required.** |
  | `VPA.HLP` | The built-in help (**F1**). **Required.** |
  | `VPA_RUS.HLP` | The same help in Russian (see §2). |
  | `VPA.MSG` | Templates VPA uses to parse host messages. |
  | `LITT_VPA.CHR` | The small vector font of the map labels. |
  | `EXAMPLES\` | A sample `VPA.INI` and the `game_launch.cmd` launcher. |

  The `plugins\` folder must stay **next to `VPA.exe`**.
- A **VGA Planets game directory** of your own: the folder with your turn files
  (`GENx.DAT`, `SHIPx.DAT`, `PDATAx.DAT`, `BDATAx.DAT`, `PLAYERx.RST`, etc.), where
  `x` is your race number. VPA does **not** come with a game; you get those files
  from your VGA Planets host.
- Some **VGA Planets files** that are not shipped with VPA, above all
  `RESOURCE.PLN` — see "Files not shipped with VPA" in §2.

---

## 2. Running VPA

Open a **Command Prompt** or **PowerShell** in the VPA folder and run it with your
**race number** and your **game directory**:

```bat
VPA.exe <race> [game-directory]
```

- `<race>` — your player number (1–11).
- `[game-directory]` — the folder with your turn files. If omitted, the current
  directory is used. An absolute path (`C:\PLANETS\MYGAME`) or one relative to
  the current folder (`MYGAME`) both work, with `\` or `/`. The trailing slash is
  optional. **Maximum 65 characters**: VPA keeps the DOS-era limit, so keep your
  games in a short path such as `C:\PLANETS\…`. If the path is too long, VPA says
  so and exits.

Example (playing race 3, game in `C:\PLANETS\MYGAME`):

```bat
VPA.exe 3 C:\PLANETS\MYGAME
```

**Run it from the VPA folder.** `VPA.HLP` and `VPA.MSG` are looked up only in
the **current directory**; `DISTTABL.DAT`, `RESOURCE.PLN` and `PLANETS.EXE` in the
game directory first and then in the current directory — exactly like the DOS
version did. A shortcut must
therefore have its "Start in" field set to the VPA folder — or use
`EXAMPLES\game_launch.cmd`, which changes to the VPA folder first. Edit its three
lines (VPA folder, race, game) and double-click it.

Run `VPA.exe` with no arguments to see the banner and usage;
`VPA.exe /?` lists all command-line options (`/B`, `/K`, `/M`, `/O`, `/P`,
`/PW:pwd`, `/R`, `/S`, `/REP:frm,rep`), exactly as the original VPA did.

> **Console output.** The text VPA prints (the loading log, usage, `--help`,
> `--graph-info`) is written straight to the console window. It shows up when you
> run VPA from a console, but not if you redirect it to a file.

### `--help` and `--graph-info`

`VPA.exe --help` (or `-h`) shows the same help as `/?` **plus the environment
variables** this build understands. Set them with `set NAME=value` in a Command
Prompt (or `$env:NAME = 'value'` in PowerShell) before running VPA:

| Variable | What it does |
|---|---|
| `VPA_SCALE` | Window size or fullscreen (§3). |
| `VPA_GRAPH_BACKEND` | Graphics backend: `auto` (default) or `sdl3`. On Windows both mean the SDL3 plugin. |
| `VPA_GRAPH_PLUGIN_DIR` | **Absolute** folder searched first for `vpagraph-sdl3.dll` (and its `SDL3.dll`), before `plugins\` next to `VPA.exe`. |
| `VPA_GRAPH_DEBUG` | With `1`, traces the plugin search on the error output. |
| `VPA_GRAPH_DUMP` | Testing aid: given a path prefix, **Ctrl-F12** dumps the 640×480 screen to `<prefix>NNNN.ppm` and its palette to `<prefix>NNNN.pal`. |

`VPA.exe --graph-info` is the diagnostic tool for bug reports: it prints which
backend was requested, which plugin was found and loaded (path, ABI and backend
version) or, if none works, **every reason**, one per place searched. It opens no
window. If the window does not open or looks wrong, include its output in the
report. Exit status is 0 when a backend was selected and 1 otherwise.

### Russian help (`VPA_RUS.HLP`)

The package ships the help in two languages: **`VPA.HLP`** (English) and
**`VPA_RUS.HLP`** (Russian), both compiled from the original `VHLP\VPA.HHH` and
`VHLP\VPA_RUS.HHH` sources.

VPA reads the file named by the `HelpFile` key in `VPA.INI`, which defaults to
`VPA.HLP`. Two ways to switch to Russian:

**Option A — edit `VPA.INI`** (recommended, leaves the files alone):

```ini
HelpFile        = VPA_RUS.HLP
```

**Option B — rename**, the way the original DOS VPA did it:

```bat
del VPA.HLP
ren VPA_RUS.HLP VPA.HLP
```

### Files not shipped with VPA, required to play a game

VPA is just the client: it does **not** include the VGA Planets game data nor your
game files. Those come from your original VGA Planets installation and from your
host.

**In the game directory, or in the VPA folder** — the game directory is searched
first:

| File | What it's for |
|---|---|
| `RESOURCE.PLN` | The ship pictures VPA shows (from your VGA Planets installation). **Required:** without it VPA stops with `Can't read file RESOURCE.PLN`. |
| `PLANETS.EXE` | VPA **reads your registration from it** (it never runs it). |

**In the game directory:**

| File | What it's for |
|---|---|
| `PLAYERx.RST` | Your turn, where `x` is your race number. Provided by the host. |
| `PCONFIG.SRC` | The host configuration. Only if you play with **PHost**; provided by the host. |
| `UTILx.DAT` | Auxiliary turn data. Only if you play with **PHost**; provided by the host. |
| `MISSION.INI` | Mission definitions. Only if you play with **PHost**. |
| `HULLFUNC.TXT` | Hull special functions, if your host uses them. The PHost 4 syntax (`Hull = *`, `Level = n`) is understood; functions granted only from an experience `Level` above 0 are not shown, because VPA keeps them per hull, not per ship. |

**In either the VPA folder or the game directory** — the game directory is
searched first, so a copy there takes precedence (handy when your host uses a
modified ship list):

| Files | What they're for |
|---|---|
| `BEAMSPEC.DAT`, `TORPSPEC.DAT`, `ENGSPEC.DAT` | Beam, torpedo and engine specs. |
| `HULLSPEC.DAT`, `TRUEHULL.DAT` | Hull specs and which hulls each race can build. |
| `PLANET.NM` | The planet names. |
| `RACE.NM` | The race names. |
| `STORM.NM` | The ion storm names (optional). |

---

## 3. Window size and fullscreen

VPA's screen is 640×480. By default it is shown in a window at **2×**. To change
that, set **`VPA_SCALE`** before running VPA (the value is case-insensitive):

```bat
rem Fullscreen:
set VPA_SCALE=fullscreen
VPA.exe 3 C:\PLANETS\MYGAME

rem 3x window:
set VPA_SCALE=3

rem Window at 220 % (2.2x):
set VPA_SCALE=220
```

| `VPA_SCALE` | Result |
|---|---|
| *(unset)* | **2×** window (default). |
| `1` | Native **640×480**, the smallest. |
| `2`…`20` | **N×** window (limited to what fits on your screen). |
| `21`…`800` | Window at **N %** (e.g. `220` = 2.2×, `137` = 1.37×). |
| `fullscreen` | **Fullscreen**, the largest 4:3 picture that fits. Aliases: `full`, `max`. |

The window can also be resized with the mouse; the picture keeps its 4:3 shape.
Fullscreen applies only to VPA's own window — it does **not** change your
monitor's resolution.

In PowerShell, use `$env:VPA_SCALE = 'fullscreen'` instead of `set`.
`EXAMPLES\game_launch.cmd` sets `VPA_SCALE=fullscreen` for you.

### Selection mouse sensitivity (`StickyMouseRange`)

VPA has a feature called **StickyMouse** that keeps you from losing an object
selection (planet, ship…) to an accidental mouse movement: as long as the pointer
doesn't stray from the selected object, the movement is ignored and the cursor
snaps back to it.

VPA's classic radius was a hardcoded **2 pixels**, which can be too tight for a
modern optical mouse. It is adjustable in `VPA.INI`, under `[Interface]`:

```ini
StickyMouse      = On
StickyMouseRange = 15
```

| Value | Effect |
|---|---|
| `2` | Classic VPA behaviour (the default if you don't set the key). |
| `10`–`20` | Recommended with modern optical mice. |
| `0` | Disables the filter (same as `StickyMouse = Off`). |
| max `100` | Larger values are clamped to 100. |

It can also be changed from the `VPA.INI` menu (**Ctrl-O**): `Enter` on
`StickyMouseRange` steps the value up to `20` and then back to `0`.

---

## 4. Controls & exiting

- **F1** — help · **F3** — messages · **F5** — combat simulator. The full key list
  is in the help and in [`DOC/KEYS.TXT`](DOC/KEYS.TXT); keys match the original DOS
  VPA.
- The mouse moves and selects on the map; inside the window the pointer becomes
  VPA's own white crosshair. Resting the pointer at the edge of the map scrolls
  it; a right click near the edge scrolls a larger step.
- **Exit:**
  - **Alt-X** (or the window's **[X]** button) — quit **saving** your turn.
  - **Ctrl-Alt-X** — quit **without saving** (asks for confirmation).

When you save, VPA writes your turn file (`PLAYERx.TRN`) into the game directory,
ready to send back to your host, and keeps its own notes and database
(`VPAx.DB`, `VPANOTx.DAT`, …) there too.

"Edit file" in the INI menus opens the editor named by `%VISUAL%` or `%EDITOR%`,
or Notepad if neither is set.

---

## 5. Combat viewer — no `PVCR.EXE` / `VCR.EXE` needed

The original DOS VPA launched **external** combat viewers — `PVCR.EXE` for
**PHost** battles and `VCR.EXE` for classic **Tim-Host** battles. This build has
the viewer **built in**:

- **PHost** battles use a **native viewer** ported from the combat algorithm of
  PCC2ng (bit-exact with the original).
- **Classic (Tim-Host)** battles use VPA's own internal viewer.

To watch a fight, open the combat message in the messages screen (**F3**) and
press **`v`**; the **F5** combat simulator uses the same engine.

**Sound.** The DOS VPA beeped through the PC speaker during battles (beams,
torpedoes, explosions). This build plays the same square-wave sounds through
Windows' default audio output. They are off by default: turn them on with
**`o`** ("Sound") in the combat simulator's settings (**F5**); the setting also
applies when viewing battles from the messages.

---

## 6. Credits & license

VPA was written by **Alex V. Ivlev** (© 1993–96) and maintained afterwards by the
VPA team; it includes combat logic derived from **PCC2ng** by **Stefan Reuther**.
The GNU/Linux port this build is based on is © 2026 **Pablo Romano Gómez**. All
original copyright notices are kept; see [`LICENSE.md`](LICENSE.md).

The package includes **SDL 3.4.16** (`plugins\SDL3.dll`), the official unmodified
Windows build, © Sam Lantinga, under the **zlib** licence: see `LICENSE.SDL3.txt`.

When reporting a problem, include your Windows version, the output of
`VPA.exe --graph-info`, and what you were doing when it happened.

Enjoy, and good luck out there, Commander. 🚀

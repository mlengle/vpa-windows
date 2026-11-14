# VPA for Windows

A native Windows build of VPA-Linux (VGA Planets Assistant 3.67), made from the
same source tree. No DOSBox, no WSL: `VPA.exe` is a Win32 program and draws
through an SDL3 graphics plugin.

> 🇷🇺 Краткая инструкция на русском — в конце файла.

## How the port works

VPA-Linux already split the program into an executable that links no graphics
library and graphics **plugins** loaded at run time (see `WAYLAND.md`). One of
them, the Wayland plugin, is a PTC console written on top of **SDL3**. SDL3 runs
on Windows too, so the Windows port reuses that plugin unchanged in substance:

| Linux | Windows |
|---|---|
| `build/VPA` | `build\VPA.exe` |
| `plugins/libvpagraph-wayland.so` (SDL3, video driver `wayland`) | `plugins\vpagraph-sdl3.dll` (SDL3, video driver `windows`) |
| `plugins/libSDL3.so.0`, found through `RUNPATH=$ORIGIN` | `plugins\SDL3.dll`, found through `LoadLibraryEx(…, LOAD_WITH_ALTERED_SEARCH_PATH)` |
| `dlopen(RTLD_NOW)` / `dlsym` / `dlclose` | `LoadLibraryEx` / `GetProcAddress` / `FreeLibrary` |
| `/proc/self/exe` | `GetModuleFileName` |
| backend auto-detection (`WAYLAND_DISPLAY`, `DISPLAY`…) | always `sdl3` |
| "Edit file" in the INI menus: `$VISUAL`, `$EDITOR`, nano, vi | `%VISUAL%`, `%EDITOR%`, Notepad |

Everything else — the game logic, the data file formats (`{$PACKRECORDS 1}`,
little-endian), the help compiler, the PHost combat viewer — is the same code.
The changes are all behind `{$IFDEF WINDOWS}`; the Linux build is unaffected.

## Build

Requirements:

- **Free Pascal 3.2.2** on the `PATH` (official installer from
  freepascal.org, or `scoop install freepascal`). The 32-bit compiler
  (`i386-win32`) gives a 32-bit `VPA.exe` that runs on every Windows; a
  `x86_64-win64` compiler gives a 64-bit one. `SDL3.dll` is chosen to match.
- Internet access the first time: the script downloads the official
  **SDL 3.4.16** zip from libsdl-org's GitHub releases (the same version the
  Linux package ships) and checks its SHA256.

> **scoop users:** scoop's Free Pascal install has no `fpc.cfg`, so `fpc` cannot
> find its own units. The script detects this and prints the one command that
> fixes it (`fpcmkcfg -d basepath=… -o …\fpc.cfg`).

From the project root, in PowerShell:

```powershell
.\build-windows.ps1              # build\VPA.exe + build\plugins\{vpagraph-sdl3.dll, SDL3.dll}
.\build-windows.ps1 hlp          # build\VPA.HLP and build\VPA_RUS.HLP
.\build-windows.ps1 package      # all of it, in build\vpa-windows_package\
.\build-windows.ps1 graphtest    # plugin vs. direct ptcgraph, 10 frames compared byte by byte
.\build-windows.ps1 clean
```

If script execution is disabled: `powershell -ExecutionPolicy Bypass -File .\build-windows.ps1 package`.

The `Makefile` is still the Linux build; it is not used on Windows.

## Install and play

Copy the **contents** of `build\vpa-windows_package\` into your game folder
(next to the `.DAT` / `.RST` files, or one level up), keeping the `plugins\`
subfolder next to `VPA.exe`. Then, from a Command Prompt or PowerShell in that
folder:

```bat
VPA.exe 3 MYGAME
```

Everything in `HOWTO.en.md` applies (race number, options `/B /K /M /O /P /R /S`,
Alt-X / Ctrl-Alt-X, `VPA.INI`, Russian help), with these differences:

- **Environment variables** are set with `set` (cmd) or `$env:` (PowerShell):
  `set VPA_SCALE=fullscreen` then `VPA.exe 3 MYGAME`. `EXAMPLES\game_launch.cmd`
  is a ready-made launcher you can double-click.
- `VPA.exe --graph-info` reports which plugin it found and why; `VPA_GRAPH_DEBUG=1`
  traces the plugin search on the error output.
- `RESOURCE.PLN` (from your VGA Planets installation, not shipped) is looked
  up first in the game folder, then next to `VPA.exe`, as the DOS version did.
- `HULLFUNC.TXT` in PHost 4 syntax (`Hull = *`, `Level = n`) is understood.
  Assignments with `Level` > 0 apply only to experienced ships and are not
  shown, because VPA's hull-function table is per hull, not per ship.
- `build-windows.ps1 package` and `clean` never delete
  `build\vpa-windows_package\`, so game folders kept there are safe.
- Paths can be written with `\` or `/`.
- Run it from a console window: the text output (usage, `--graph-info`, the
  "save changes?" dialog when there is no game window) goes to the console.

## What was verified

- `VPA.exe`, the plugin and the help compiler build with FPC 3.2.2 i386-win32
  without errors.
- `VPA.exe --graph-info` finds `plugins\vpagraph-sdl3.dll`, loads it with its
  `SDL3.dll`, validates the ABI and unloads it.
- `graphtest`: the graphics API test opens a real SDL3 window on Windows and the
  10 frames drawn through the DLL plugin are byte-identical to the ones drawn
  by ptcgraph linked directly.
- `VPA.HLP` generated on Windows is byte-identical to the one in the repository
  (proof that the record layout matches the DOS/Linux one).

Not yet verified: a full game session on real turn files (the reference game
used for the golden images is not in the repository).

---

## Кратко по-русски

**Сборка:** нужен Free Pascal 3.2.2 в `PATH`. В PowerShell в корне проекта:
`.\build-windows.ps1 package` — получится папка `build\vpa-windows_package\`
(`VPA.exe`, `plugins\vpagraph-sdl3.dll`, `plugins\SDL3.dll`, справка и данные).
SDL3 3.4.16 скачивается с официального GitHub libsdl-org с проверкой SHA256.

**Запуск:** скопируйте содержимое пакета в папку с игрой (подпапка `plugins\`
должна лежать рядом с `VPA.exe`) и запустите из консоли `VPA.exe <раса> <папка игры>`.
Размер окна: `set VPA_SCALE=3` или `set VPA_SCALE=fullscreen`. Готовый пример —
`EXAMPLES\game_launch.cmd`. Диагностика графики: `VPA.exe --graph-info`.

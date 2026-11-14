# VPA for Windows

A native Windows build of **VGA Planets Assistant (VPA) 3.67**, the classic
client for the play-by-email strategy game *VGA Planets 3*. `VPA.exe` is a
Win32 program: no DOSBox, no WSL, no emulator. It looks and plays like the
original DOS VPA — same screens, same keys — in a window you can scale or run
fullscreen.

It loads your turn (`PLAYERx.RST`), shows the star map, planets, ships,
starbases and messages, and writes your orders back into `PLAYERx.TRN` for
your host. PHost battles are replayed by a built-in, bit-exact combat viewer,
so `PVCR.EXE` is not needed.

## Quick start

1. **Build** the package (needs Free Pascal 3.2.2; details in
   [`BUILD.md`](BUILD.md)):

   ```powershell
   .\build-windows.ps1 package
   ```

   Everything you need ends up in `build\vpa-windows_package\`.

2. **Install:** copy the contents of that folder wherever you keep VPA, and
   add `RESOURCE.PLN` from your VGA Planets installation (it is not
   redistributable, so it is not included). Keep the `plugins\` folder next to
   `VPA.exe`.

3. **Play** from a Command Prompt or PowerShell in that folder:

   ```bat
   VPA.exe 3 C:\PLANETS\MYGAME
   ```

   `3` is your race number, the second argument is the folder with your turn
   files. `EXAMPLES\game_launch.cmd` is a ready-made launcher you can
   double-click.

The full player's guide — files VPA needs, window size, fullscreen, keys,
Russian help — is in [`HOWTO.md`](HOWTO.md).

## Documentation

| File | What it covers |
|---|---|
| [`HOWTO.md`](HOWTO.md) | Running and playing: setup, files, options, window size, controls. |
| [`BUILD.md`](BUILD.md) | Building from source, the package, how the Windows port is put together. |
| [`LICENSE.md`](LICENSE.md) | Which license covers which part, and every copyright holder. |
| [`DOC/`](DOC) | The original VPA documentation: hot keys (`KEYS.TXT`), `VPA.INI` options (`VPAINI.TXT`), FAQ, reports, starbases, extended features, what's new. |
| [`CHANGE.TXT`](CHANGE.TXT) | The original VPA change log. |
| `F1` inside VPA | The built-in help, in English (`VPA.HLP`) or Russian (`VPA_RUS.HLP`). |

## What is different from DOS VPA

- Runs natively on Windows (32-bit `VPA.exe`, works on 32- and 64-bit
  Windows); the screen is still VPA's 640×480, scaled up in a window
  (2× by default) or fullscreen.
- Built-in PHost combat viewer ported from PCC2ng; no external `PVCR.EXE` or
  `VCR.EXE`.
- `HULLFUNC.TXT` in PHost 4 syntax (`Hull = *`, `Level = n`) is understood.
- Map auto-scroll is about three times faster and smoother: it was paced by
  the 55 ms BIOS timer, which no longer matches how fast the map redraws.
- "Edit file" in the INI menus opens `%EDITOR%`, or Notepad.

## Where this comes from

VPA was written by **Alex V. Ivlev** (1993–96) in Turbo/Borland Pascal for DOS
and maintained afterwards by the VPA team; the source was published on
SourceForge under the Mozilla Public License.

**Pablo Romano Gómez** ported it to GNU/Linux with Free Pascal as
[VPA-Linux](https://github.com/promano7/vpa-linux) (2026): the graphics layer
moved to `ptcgraph` behind a plugin ABI, data files were made portable, and
the PHost combat viewer was ported from **Stefan Reuther**'s PCC2ng.

This repository is an independent Windows port of VPA-Linux. It builds the
same sources as a Win32 program, using the SDL3 graphics plugin as a DLL, and
fixes the problems that only showed up on Windows. The Linux build files
(`Makefile`, `setup-env.sh`, the X11/Wayland backends) are still in the tree,
inherited from VPA-Linux, but are not maintained or tested here.

## Repository layout

| Path | Contents |
|---|---|
| `VPA/`, `UNIT/`, `VHLP/`, `CC/` | VPA itself, its units, the help compiler and the PCC command code. |
| `GRAPH/` | VPAGraph: the graphics API the executable uses and the plugin loader. |
| `BACKENDS/` | Graphics plugins; on Windows, `BACKENDS/WAYLAND` builds `vpagraph-sdl3.dll`. |
| `VENDOR/` | Vendored Free Pascal graphics code (`ptcgraph`, PTCPas with its SDL3 console) and the SDL3 bindings. |
| `TESTS/` | Graphics API test (`build-windows.ps1 graphtest`) and the Linux screenshot tooling. |
| `EXAMPLES/` | Sample `VPA.INI` and `game_launch.cmd`. |
| `build-windows.ps1` | The Windows build script. |

## License

VPA's own code and the changes to it are under the **Mozilla Public License**;
other parts are under the PCC II terms, the LGPL with the Free Pascal
static-linking exception, zlib and BSD 3-Clause. See
[`LICENSE.md`](LICENSE.md). *VGA Planets* is a trademark of its owner; this
is an unofficial fan-made helper and ships no game data.

---

### Кратко по-русски

Нативная Windows-версия VGA Planets Assistant 3.67: `VPA.exe` без DOSBox.
Сборка — `.\build-windows.ps1 package` (нужен Free Pascal 3.2.2, см.
[`BUILD.md`](BUILD.md)), результат — папка `build\vpa-windows_package\`.
Скопируйте её содержимое к себе, добавьте `RESOURCE.PLN` из установки
VGA Planets и запускайте из консоли `VPA.exe <раса> <папка партии>`.
Справка на русском — `VPA_RUS.HLP` (как включить — в [`HOWTO.md`](HOWTO.md)).

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

VGA Planets Assistant (VPA) 3.67 — a DOS Turbo/Borland Pascal program — ported
to Windows. It is an independent fork of VPA-Linux
(https://github.com/promano7/vpa-linux, remote `upstream`; its `main` is the
local branch `upstream-main`). The same sources still build on Linux with the
inherited `Makefile`, but only the Windows build is maintained here.
User docs: `README.md`, `HOWTO.md` (playing), `BUILD.md` (building, port design).

## Build and test (PowerShell, Free Pascal 3.2.2 on PATH)

```powershell
.\build-windows.ps1              # build\VPA.exe + build\plugins\{vpagraph-sdl3.dll,SDL3.dll}
.\build-windows.ps1 hlp          # build\VPA.HLP, VPA_RUS.HLP (VHLP\vhlpmake from VHLP\*.HHH)
.\build-windows.ps1 package      # everything into build\vpa-windows_package\
.\build-windows.ps1 graphtest    # the only automated test on Windows (see below)
```

- The scoop FPC is i386-win32 only, so builds are 32-bit. If `fpc` cannot find
  its units, `fpc.cfg` is missing; the script prints the `fpcmkcfg` fix.
- `VPA.exe` itself is `fpc @vpa.cfg VPA/VPA.PAS` (output in `build\`). To build
  a variant without touching the tree (e.g. with tracing), put modified copies
  of `VPA.PAS` **and** the changed unit in a separate dir and pass it first with
  `-Fu<dir>` plus `-FU<units dir> -FE<out dir>`: FPC searches the main
  program's directory first, so `VPA.PAS` must be copied too. Use Windows paths
  (`C:\…`), not Git-Bash `/c/…` paths, with `fpc`.
- `graphtest` compiles `TESTS/vpagraph/graphapi_test.pas` twice (via the plugin
  and with `ptcgraph` linked directly), draws 10 frames in a real SDL3 window and
  requires them byte-identical. A regenerated `build\VPA.HLP` should also be
  byte-identical to the committed `VPA.HLP` (checks record layout).
- Everything else under `TESTS/` (`capture.sh`, `compare.py`, `abi/`, `x11/`,
  `wayland/`, golden images) is Linux-only `make` tooling.
- `package` and `clean` deliberately never delete `build\vpa-windows_package\`:
  the user keeps real game folders (`med`, `TEST`) and `RESOURCE.PLN` there.

## Running VPA when testing

- `VPA.exe <race> <gamedir>` must run from the folder holding `VPA.HLP`,
  `VPA.MSG`, `DISTTABL.DAT`, `RESOURCE.PLN` (looked up in the current dir; the
  last two in the game dir first). Game dir path max 65 chars.
- Its text output goes through FPC `crt`, which writes to the console directly:
  it is invisible when stdout is piped. Run it in a real terminal tab to read it.
- **Run on copies of game folders.** On exit — including the window's close
  button and even after a crash — VPA writes `PLAYERx.TRN`, `VPAx.DB`,
  `VPASCRx.INI`, `VPANOTx.DAT` into the game dir.
- Driving it from outside: key presses posted as `WM_KEYDOWN`/`WM_CHAR` to the
  SDL window work; `WM_CLOSE` = quit with save. Posted mouse messages do *not*
  reach VPA (SDL ignores them while the real cursor is elsewhere).
- `VPA.exe --graph-info` diagnoses plugin loading; `VPA_GRAPH_DEBUG=1` traces it.

## Architecture

**Executable vs. graphics plugin.** `VPA.exe` links no graphics library. Units
use `vpagraph` (`GRAPH/`), which re-exposes the BGI/ptcgraph-style API and
forwards to a plugin loaded at run time (`GRAPH/vpagraph_loader.pas`: env
`VPA_GRAPH_PLUGIN_DIR`, then `<exe dir>\plugins\`; `LoadLibraryEx` with
altered search path so `SDL3.dll` beside the plugin is found).
`GRAPH/vpagraph_abi.inc` is the only contract; its header lists the rules:
cdecl only, fixed-size types, no strings/dynamic arrays/classes/exceptions
across the boundary (the EXE and DLL each have their own FPC RTL), fields only
appended. Keyboard and mouse also come from the plugin (`GRAPH/vpagraph_input.pas`
→ `UNIT/KEYBOARD.PAS`, `UNIT/MOUSE.PAS`).

**The Windows plugin** `vpagraph-sdl3.dll` is the VPA-Linux Wayland plugin
rebuilt: `BACKENDS/WAYLAND/vpagraph_wayland.lpr` compiled with `-dVPAG_WAYLAND`
reusing `BACKENDS/X11/vpagraph_x11_impl.pas`, linking vendored `ptcgraph` +
PTCPas (`VENDOR/`) built with `-dPTC_SDL3`, whose console is
`VENDOR/ptc/sdl/sdlconsolei.inc` (SDL video driver `windows`). VPA draws into
an 8-bit 640×480 ptcgraph buffer; `VENDOR/ptc/ptcwrapper.pp` runs a thread that
copies it to the SDL window every ~10 ms under a lock. Platform branches use
`{$IFDEF WINDOWS}`; many "not DOS" features are guarded
`{$IF DEFINED(UNIX) OR DEFINED(WINDOWS)}`.

**VPA itself** (`VPA/`, `UNIT/`): `VPA.PAS` → `VPAINIT` (args, `--help`,
loading, graphics init) → `VPA2.Main` (the map's event loop: keys via a big
`case`, mouse events, auto-scroll). Game data and file helpers in `VPADATA.PAS`;
host config and `HULLFUNC.TXT` in `CONFIG.PAS`; messages in `MSGREAD.PAS`/
`MESSAGES.PAS`; combat viewer in `TCOMBAT.PAS` + `PVCRALG.PAS` (PHost
algorithm ported from PCC2ng); `CC/` is PCC command-message code (only with
`VPACC`, which is not defined).

## Pascal conventions that bite

- Compiled in Turbo Pascal mode (`-Mtp`, see `vpa.cfg`) with I/O, range and
  overflow checks off. `integer` is 16-bit; there is no `initialization`/
  `finalization` (use the unit's `begin … end.` block); `{$PACKRECORDS 1}`
  matters for on-disk records.
- Files are opened with `{$I-}` + `IOResult`. A stale, unread `IOResult`
  makes FPC skip the next I/O call entirely, so the `Open*` helpers in
  `VPADATA.PAS` read and discard it first. Windows also cannot rewrite a file
  that is still open (Linux can): close what you open, even on failure paths.
- Nil pointers that DOS tolerated (`lplan^` with no planet data) crash on
  Windows; check before dereferencing.
- `filename` is `string[12]` (`UNIT/STRF.PAS`); use `str79` or `OpenFile` for
  paths. `addir` (game dir, with trailing `\`) is `string[67]`.
- Timing: `Timer` counts 55 ms BIOS ticks; `MsTimer` (`UNIT/AUXF.PAS`, via
  `timeGetTime`) is milliseconds. `GetTickCount64` has 15.6 ms granularity on
  Windows. `AUXF` calls `timeBeginPeriod(1)` at start-up so `Sleep`/`Delay`
  are accurate.
- Comments are mostly Spanish (from VPA-Linux); keep that style when editing
  nearby code. Comments referencing `WAYLAND.md` or `docs/*.md` point to
  VPA-Linux documents removed here (still in git history).

## Editing files safely

- Most sources are CRLF, and several (`VPA/VPADATA.PAS`, `VPA/BUILDING.PAS`,
  `VPA/SCREEN.PAS`, …) contain DOS-codepage bytes and are not UTF-8, so the
  Edit tool refuses them. Edit those with a byte-preserving script (Python:
  read bytes / `latin-1`, keep the original line endings).
- `.gitattributes` forces CRLF for `*.cmd`, `*.bat`, `*.ps1`
  (`VPA/GREETS.BAT` is exempt: it has bare CRs).
- In Python string literals, write Windows paths with doubled backslashes or
  `chr(92)`: `"\v"`, `"\b"` in a path silently become control characters.

# Building VPA for Windows

How to compile `VPA.exe` and its graphics plugin from source, what the package
contains, and how the Windows port is put together. To play, see
[`HOWTO.md`](HOWTO.md).

## Requirements

- **Free Pascal 3.2.2** on the `PATH` — the official installer from
  freepascal.org, or `scoop install freepascal`. The 32-bit compiler
  (`i386-win32`) gives a 32-bit `VPA.exe` that runs on every Windows; an
  `x86_64-win64` compiler gives a 64-bit one. `SDL3.dll` is chosen to match.
- **PowerShell** (the Windows PowerShell 5.1 that comes with Windows is enough).
- **Internet access the first time**: the script downloads the official
  **SDL 3.4.16** Windows zip from libsdl-org's GitHub releases into
  `build\sdl3-win\` and checks its SHA-256 before using it.

> **scoop users:** scoop's Free Pascal install has no `fpc.cfg`, so `fpc` cannot
> find its own units. The script detects this and prints the one command that
> fixes it (`fpcmkcfg -d basepath=… -o …\fpc.cfg`).

## Build

From the project root, in PowerShell:

```powershell
.\build-windows.ps1              # build\VPA.exe + build\plugins\{vpagraph-sdl3.dll, SDL3.dll}
.\build-windows.ps1 hlp          # build\VPA.HLP and build\VPA_RUS.HLP from VHLP\*.HHH
.\build-windows.ps1 package      # all of the above, assembled in build\vpa-windows_package\
.\build-windows.ps1 graphtest    # graphics API test: plugin vs. direct ptcgraph, 10 frames
.\build-windows.ps1 clean        # remove build output
```

If script execution is disabled:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-windows.ps1 package
```

`package` and `clean` **never delete `build\vpa-windows_package\`**: only the
package's own files are (over)written, so game folders and `RESOURCE.PLN` kept
there to play from are safe. `clean` also keeps the downloaded SDL3 in
`build\sdl3-win\`.

## The package

`build\vpa-windows_package\` is everything a player needs, apart from the
VGA Planets files that cannot be redistributed:

| File | |
|---|---|
| `VPA.exe` | The program. |
| `plugins\vpagraph-sdl3.dll`, `plugins\SDL3.dll` | The graphics plugin and SDL 3. |
| `VPA.HLP`, `VPA_RUS.HLP` | Built-in help, English and Russian. |
| `DISTTABL.DAT`, `VPA.MSG`, `LITT_VPA.CHR` | Support files VPA reads at start-up. |
| `EXAMPLES\` | Sample `VPA.INI` and `game_launch.cmd`. |
| `README.md`, `HOWTO.md`, `LICENSE.md`, `MPL-2.0.txt`, `LICENSE.SDL3.txt` | Documentation and licences. |

## How the port works

VPA-Linux split the program into an executable that links no graphics library
and graphics **plugins** loaded at run time through a small C ABI
(`GRAPH\vpagraph_abi.inc`, entry point `VPAGraph_GetInterface`). One of its
plugins, the Wayland one, is a PTC console written on top of **SDL3** — and SDL3
runs on Windows too. The Windows port therefore builds that same plugin as a DLL
and points SDL at its Windows video driver:

| VPA-Linux | VPA for Windows |
|---|---|
| `build/VPA` | `build\VPA.exe` |
| `plugins/libvpagraph-wayland.so` (SDL3, video driver `wayland`) | `plugins\vpagraph-sdl3.dll` (SDL3, video driver `windows`), built from `BACKENDS\WAYLAND` with `-dVPAG_WAYLAND` |
| `plugins/libSDL3.so.0`, found through `RUNPATH=$ORIGIN` | `plugins\SDL3.dll`, found through `LoadLibraryEx(…, LOAD_WITH_ALTERED_SEARCH_PATH)` |
| `dlopen` / `dlsym` / `dlclose` | `LoadLibraryEx` / `GetProcAddress` / `FreeLibrary` (`GRAPH\vpagraph_loader.pas`) |
| `/proc/self/exe` | `GetModuleFileName` |
| backend auto-detection (`WAYLAND_DISPLAY`, `DISPLAY`…) | always `sdl3` (`GRAPH\vpagraph_detect.pas`) |
| "Edit file": `$VISUAL`, `$EDITOR`, nano, vi | `%VISUAL%`, `%EDITOR%`, Notepad |

Everything else — the game logic, the data file formats (`{$PACKRECORDS 1}`,
little-endian), the help compiler, the PHost combat viewer — is the same code.
The Windows-specific parts sit behind `{$IFDEF WINDOWS}`.

Things that only show up on Windows, and how they are handled:

- **Timer resolution.** Windows' default clock ticks every 15.6 ms, which
  stretched every `Sleep`/`Delay` (combat animation, input loop, the window
  refresh thread). VPA asks for 1 ms with `timeBeginPeriod` at start-up
  (`UNIT\AUXF.PAS`); millisecond timing uses `timeGetTime`.
- **Open files.** Windows cannot rewrite a file that is still open. The file
  helpers in `VPA\VPADATA.PAS` close empty files they open and discard stale
  I/O errors, so notes and other per-game files are saved on exit.
- **Null pointers.** DOS silently read through a nil pointer; Windows does not.
  Key handlers that used the selected planet without checking it are guarded.
- **Console output.** Free Pascal's `crt` unit writes straight to the console,
  so VPA's text output is visible in a console window but not when redirected.

## Tests

`.\build-windows.ps1 graphtest` compiles `TESTS\vpagraph\graphapi_test.pas` twice —
once against the plugin and once against `ptcgraph` linked directly — opens a
real SDL3 window, draws ten scenes with both and checks that the frames are
byte-for-byte identical.

A quick check of a build:

- `VPA.exe --graph-info` from the package must find `plugins\vpagraph-sdl3.dll`,
  load it with its `SDL3.dll`, and report ABI 1 and backend `sdl3`.
- `build\VPA.HLP` generated on Windows is byte-identical to `VPA.HLP` in the
  repository, which confirms that the record layout matches the DOS one.

The screenshot comparison tooling under `TESTS\` (`capture.sh`, `compare.py`)
and the `Makefile` are inherited from VPA-Linux and run on Linux only.

<#
  build-windows.ps1 - build VPA for Windows (the Windows counterpart of the Makefile).

  Usage (from the project root, in PowerShell):
    .\build-windows.ps1            # = build: VPA.exe + plugins\vpagraph-sdl3.dll + SDL3.dll
    .\build-windows.ps1 hlp        # VPA.HLP and VPA_RUS.HLP
    .\build-windows.ps1 package    # everything, assembled in build\vpa-windows_package\
    .\build-windows.ps1 graphtest  # graph API test: plugin vs direct ptcgraph, pixel-identical
    .\build-windows.ps1 clean      # remove build artifacts (keeps build\sdl3-win\ and build\vpa-windows_package\)

  Needs Free Pascal 3.2.2 (fpc on the PATH). The executable has the same
  architecture as the compiler: the i386-win32 FPC gives a 32-bit VPA (runs on
  any Windows), an x86_64-win64 FPC a 64-bit one; the SDL3.dll is picked to match.

  If PowerShell refuses to run scripts:
    powershell -ExecutionPolicy Bypass -File .\build-windows.ps1
#>
param([ValidateSet('build', 'hlp', 'package', 'graphtest', 'clean')][string]$Target = 'build')

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# SDL3 shipped next to the plugin: the same release the Linux package pins
# (Makefile, SDL3VER). Official binaries from libsdl-org, checked by SHA256.
$SDL3Ver = '3.4.16'
$SDL3Sha = @{
    'x86' = 'beb4e86e4a101f66556162c3efff9fd1ad88f1761b63be35867a3336a72f8c41'
    'x64' = '4217944b4e51457af4a59c82d883f8443b3e65964b2acd8943484c492756c4b6'
}

$Build     = 'build'
$PlugDir   = "$Build\plugins"
$SdlUnits  = "$PlugDir\units-sdl3"
$PlugObj   = "$PlugDir\sdl3"
$Plugin    = "$PlugDir\vpagraph-sdl3.dll"
$Sdl3Dir   = "$Build\sdl3-win"
$PkgDir    = "$Build\vpa-windows_package"
$PtcFlags  = @('-O2', '-dPTC_SDL3', '-FiVENDOR/ptc', '-FiVENDOR/ptc/core', '-FiVENDOR/ptc/sdl',
               '-FuVENDOR/ptc', '-FuVENDOR/sdl3', '-FiVENDOR/sdl3')
$PkgFiles  = @('DISTTABL.DAT', 'LITT_VPA.CHR', 'VPA.MSG', 'HOWTO.en.md', 'HOWTO.es.md',
               'LICENSE.md', 'MPL-2.0.txt', 'WINDOWS.md')

function Invoke-Fpc {
    # Plain $args, not a param block: fpc options such as -O2 must not be
    # taken for parameters of this function.
    $FpcArgs = @($args | ForEach-Object { $_ })
    Write-Host "fpc $($FpcArgs -join ' ')" -ForegroundColor DarkGray
    $ErrorActionPreference = 'Continue'   # fpc's stderr is not a PowerShell error
    $out = & (Get-Command fpc -CommandType Application | Select-Object -First 1).Source @FpcArgs 2>&1
    $code = $LASTEXITCODE
    # Errors and the final line only; the benign warnings stay out of the way.
    $out | Where-Object { "$_" -match 'Error|Fatal|Linking' } | ForEach-Object { Write-Host "  $_" }
    if ($code -ne 0) {
        $out | Select-Object -Last 25 | ForEach-Object { Write-Host "  $_" }
        throw "fpc failed (exit code $code)"
    }
}

function Get-FpcTarget {
    if (-not (Get-Command fpc -ErrorAction SilentlyContinue)) {
        throw 'fpc is not on the PATH. Install Free Pascal 3.2.2 (https://www.freepascal.org, or: scoop install freepascal).'
    }
    $t = (& fpc -iTP) + '-' + (& fpc -iTO)
    # Without an fpc.cfg (some unattended installs, e.g. scoop) the RTL is not found.
    $probe = Join-Path $env:TEMP "vpa_fpcprobe_$PID.pas"
    Set-Content -Encoding ascii $probe 'program p; uses SysUtils, Classes, SyncObjs, Hermes; begin end.'
    try {
        & fpc -s "-FE$env:TEMP" $probe *> $null
        if ($LASTEXITCODE -ne 0) {
            $base = Split-Path (Split-Path (Split-Path (Get-Command fpc).Source))
            throw ("fpc cannot find its units (no fpc.cfg?). Create one with:`n" +
                   "  fpcmkcfg -d basepath=$base -o `"$(Split-Path (Get-Command fpc).Source)\fpc.cfg`"")
        }
    } finally { Remove-Item -Force $probe -ErrorAction SilentlyContinue }
    return $t
}

function Get-SDL3 {
    param([string]$Arch)
    $dll = "$Sdl3Dir\$Arch\SDL3.dll"
    if (Test-Path $dll) { return $dll }
    New-Item -ItemType Directory -Force "$Sdl3Dir\$Arch" | Out-Null
    $zip = "$Sdl3Dir\SDL3-$SDL3Ver-win32-$Arch.zip"
    $url = "https://github.com/libsdl-org/SDL/releases/download/release-$SDL3Ver/SDL3-$SDL3Ver-win32-$Arch.zip"
    Write-Host ">> Downloading $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "$zip.part"
    $h = (Get-FileHash -Algorithm SHA256 "$zip.part").Hash.ToLower()
    if ($h -ne $SDL3Sha[$Arch]) {
        Remove-Item -Force "$zip.part"
        throw "SHA256 mismatch: the download is NOT the official SDL $SDL3Ver ($Arch) zip."
    }
    Move-Item -Force "$zip.part" $zip
    Expand-Archive -Force $zip "$Sdl3Dir\$Arch"
    return $dll
}

function Invoke-Build {
    $t = Get-FpcTarget
    $arch = if ($t -like 'x86_64-*') { 'x64' } else { 'x86' }
    Write-Host ">> Compiler target: $t (SDL3 $arch)"
    New-Item -ItemType Directory -Force $SdlUnits, $PlugObj | Out-Null

    # 1. ptc with the SDL3 console, ptcwrapper and ptcgraph, for the plugin.
    Invoke-Fpc @PtcFlags "-FU$SdlUnits" VENDOR/ptc/ptc.pp
    Invoke-Fpc @PtcFlags "-FU$SdlUnits" VENDOR/ptc/ptcwrapper.pp
    Invoke-Fpc -O2 -FiVENDOR "-Fu$SdlUnits" "-FU$SdlUnits" VENDOR/ptcgraph.pp

    # 2. The graphics plugin: the same ABI adapter as the Linux Wayland plugin.
    Invoke-Fpc '@plugins.cfg' -dVPAG_WAYLAND -FuBACKENDS/X11 "-Fu$SdlUnits" "-FU$PlugObj" "-o$Plugin" BACKENDS/WAYLAND/vpagraph_wayland.lpr
    Copy-Item -Force (Get-SDL3 $arch) "$PlugDir\SDL3.dll"

    # 3. The executable (links no graphics library; loads plugins\ at run time).
    Invoke-Fpc '@vpa.cfg' VPA/VPA.PAS
    Copy-Item -Force LITT_VPA.CHR $Build
    Write-Host ">> Done: $Build\VPA.exe, $Plugin, $PlugDir\SDL3.dll" -ForegroundColor Green
}

function Invoke-Hlp {
    New-Item -ItemType Directory -Force $Build | Out-Null
    Invoke-Fpc '@vpa.cfg' "-o$Build/vhlpmake.exe" VHLP/VHLPMAKE.PAS
    Copy-Item -Force VHLP\VPA.HHH, VHLP\VPA_RUS.HHH $Build
    Push-Location $Build
    try {
        foreach ($n in 'VPA', 'VPA_RUS') {
            & .\vhlpmake.exe "$n.HHH" | Out-Null
            if (-not (Test-Path "$n.hlp")) { throw "vhlpmake did not produce $n.HLP" }
            # Windows is case-insensitive: just normalise the name.
            Move-Item -Force "$n.hlp" "$n.tmp"; Move-Item -Force "$n.tmp" "$n.HLP"
        }
        Remove-Item -Force VPA.HHH, VPA_RUS.HHH, vhlpmake.exe
    } finally { Pop-Location }
    Write-Host ">> Generated $Build\VPA.HLP and $Build\VPA_RUS.HLP" -ForegroundColor Green
}

function Invoke-Package {
    Invoke-Build
    Invoke-Hlp
    # The package folder is NOT wiped: people copy game folders and
    # RESOURCE.PLN into it to play from there. Only the package's own files
    # are (over)written.
    New-Item -ItemType Directory -Force "$PkgDir\plugins", "$PkgDir\EXAMPLES" | Out-Null
    Copy-Item -Force "$Build\VPA.exe", "$Build\VPA.HLP", "$Build\VPA_RUS.HLP" $PkgDir
    Copy-Item -Force $Plugin, "$PlugDir\SDL3.dll" "$PkgDir\plugins"
    $lic = Get-ChildItem -Recurse "$Sdl3Dir" -Filter LICENSE.txt | Select-Object -First 1
    if ($lic) { Copy-Item -Force $lic.FullName "$PkgDir\LICENSE.SDL3.txt" }
    Copy-Item -Force EXAMPLES\* "$PkgDir\EXAMPLES"
    Copy-Item -Force $PkgFiles $PkgDir
    Write-Host ">> Package ready in $PkgDir\ - copy its contents to your game folder." -ForegroundColor Green
}

function Invoke-GraphTest {
    Invoke-Build
    $T = "$Build\vpagraph"
    New-Item -ItemType Directory -Force "$T\core", "$T\direct" | Out-Null
    $tp = @('-Mtp', '-Ci-', '-Cr-', '-Co-', '-Ct-', '-vwn')
    Invoke-Fpc @tp -FuGRAPH -FiGRAPH "-FU$T/core" "-o$T/graphapi_test_core.exe" TESTS/vpagraph/graphapi_test.pas
    Invoke-Fpc @tp -dDIRECT "-Fu$SdlUnits" "-FU$T/direct" "-o$T/graphapi_test_direct.exe" TESTS/vpagraph/graphapi_test.pas
    Copy-Item -Force "$PlugDir\SDL3.dll" $T     # the direct variant links SDL3.dll itself
    $abs = (Resolve-Path $T).Path
    if (Test-Path "$T\out") { Remove-Item -Recurse -Force "$T\out" }
    New-Item -ItemType Directory -Force "$T\out\core", "$T\out\direct" | Out-Null
    $env:VPA_SCALE = '1'
    $env:VPA_GRAPH_PLUGIN_DIR = (Resolve-Path $PlugDir).Path
    foreach ($v in 'core', 'direct') {
        $env:VPA_GRAPH_DUMP = "$abs\out\$v\frame"
        # PowerShell 5.1 turns a native program's stderr into errors under
        # ErrorActionPreference=Stop: let cmd do the redirection.
        cmd /c "`"$abs\graphapi_test_$v.exe`" > `"$abs\out\$v\log.txt`" 2>&1"
        if (-not (Select-String -Quiet -Path "$abs\out\$v\log.txt" -Pattern '^graphapi_test: PASS')) {
            Get-Content "$abs\out\$v\log.txt" | Select-Object -Last 20
            throw "graphapi_test ($v) failed"
        }
    }
    Remove-Item Env:VPA_GRAPH_DUMP, Env:VPA_SCALE, Env:VPA_GRAPH_PLUGIN_DIR
    $n = 0
    foreach ($f in Get-ChildItem "$T\out\core\frame*") {
        $o = "$T\out\direct\$($f.Name)"
        if ((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $o).Hash) { throw "$($f.Name) differs between plugin and direct" }
        $n++
    }
    if ($n -ne 10) { throw "expected 10 dump files, got $n" }
    Write-Host ">> graphapi-test passed: $n frames, plugin and direct ptcgraph pixel-identical" -ForegroundColor Green
}

function Invoke-Clean {
    Get-ChildItem $Build -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin 'sdl3-win', 'vpa-windows_package' } |
        Remove-Item -Recurse -Force
    # The package folder may hold the user's games: never delete it here.
    Write-Host '>> Cleaned (build\sdl3-win and build\vpa-windows_package kept).'
}

switch ($Target) {
    'build'     { Invoke-Build }
    'hlp'       { Invoke-Hlp }
    'package'   { Invoke-Package }
    'graphtest' { Invoke-GraphTest }
    'clean'     { Invoke-Clean }
}

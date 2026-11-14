{ vpagraph_wayland - plugin de backend grafico Wayland de VPA-Linux
  (build/plugins/libvpagraph-wayland.so). Fase 8 de WAYLAND.md, tarea T8B.9.

  Es el MISMO adaptador de ABI que el plugin X11 (BACKENDS/X11/
  vpagraph_x11_impl.pas y vpagraph_x11_input.pas), compilado otra vez con
  -dVPAG_WAYLAND y enlazado contra un ptc compilado con -dPTC_SDL3, cuya
  consola es VENDOR/ptc/sdl (ADR-001, via B). Lo unico propio de este
  directorio es vpagraph_wayland_window.pas (D-22). No enlaza libX11.

  cthreads va el PRIMERO por lo mismo que en vpagraph_x11.lpr
  (docs/threads-and-rtl.md).

  Se construye con:  make wayland-plugin

  VPA-Windows: el mismo fichero es el plugin SDL3 de Windows
  (build/plugins/vpagraph-sdl3.dll), sobre la misma consola SDL3 con el
  controlador de video 'windows'. Lo construye build-windows.ps1.
}
library vpagraph_wayland;

{$MODE OBJFPC}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}   { Windows: hilos nativos, sin gestor aparte }
  vpagraph_x11_impl;

exports
  VPAGraph_GetInterface name VPAGRAPH_ENTRY_POINT;

end.

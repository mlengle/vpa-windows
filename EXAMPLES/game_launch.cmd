@echo off
rem Sample Windows launcher: game in the folder GAME, playing race 3, fullscreen,
rem with VPA installed in C:\PLANETS. Adjust the three lines below and
rem double-click this file (or create a shortcut to it).

cd /d C:\PLANETS || exit /b 1

set VPA_SCALE=fullscreen

VPA.exe 3 GAME

@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

rem ===========================================================================
rem tools\junction.cmd - verbindet diesen Ordner mit dem AddOns-Verzeichnis
rem ---------------------------------------------------------------------------
rem WoW laedt Addons nur aus  ...\_retail_\Interface\AddOns\ . Statt die
rem Dateien dorthin zu kopieren (zwei Fassungen, die auseinanderlaufen) wird
rem eine Junction angelegt: ein Verzeichnisverweis. Das Spiel sieht einen
rem normalen Ordner, geaendert wird aber nur an einer Stelle.
rem
rem Eine Junction braucht KEINE Administratorrechte (im Gegensatz zu mklink /D).
rem
rem Einfach doppelklicken, oder in der Eingabeaufforderung aufrufen.
rem ===========================================================================

rem Der Ordner, in dem dieses Skript liegt, minus \tools
set "QUELLE=%~dp0.."
for %%I in ("%QUELLE%") do set "QUELLE=%%~fI"

rem ---------------------------------------------------------------------------
rem WoW finden. Der erste Treffer gewinnt.
rem ---------------------------------------------------------------------------
set "ZIELBASIS="
for %%P in (
  "F:\Blizzard\World of Warcraft\_retail_\Interface\AddOns"
  "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
  "D:\World of Warcraft\_retail_\Interface\AddOns"
  "E:\World of Warcraft\_retail_\Interface\AddOns"
) do (
  if not defined ZIELBASIS if exist "%%~P" set "ZIELBASIS=%%~P"
)

if not defined ZIELBASIS (
  echo.
  echo   Der AddOns-Ordner wurde nicht gefunden.
  echo   Bitte den Pfad oben in dieser Datei eintragen.
  echo.
  pause
  exit /b 1
)

set "ZIEL=%ZIELBASIS%\TacticalCalloutDock"

echo.
echo   Quelle : %QUELLE%
echo   Ziel   : %ZIEL%
echo.

rem ---------------------------------------------------------------------------
rem Ist dort schon etwas?
rem ---------------------------------------------------------------------------
if exist "%ZIEL%" (
  rem Junctions erkennt man in der dir-Ausgabe am Merkmal <JUNCTION>.
  dir /al "%ZIELBASIS%" 2>nul | find /i "TacticalCalloutDock" >nul
  if !errorlevel! equ 0 (
    echo   Es besteht bereits eine Junction.
    echo   Zum Erneuern wird sie zuerst entfernt.
    rmdir "%ZIEL%"
    if exist "%ZIEL%" (
      echo   Entfernen fehlgeschlagen - bitte den Ordner von Hand loeschen.
      pause
      exit /b 1
    )
  ) else (
    echo   ACHTUNG: Dort liegt ein ECHTER Ordner, keine Junction.
    echo   Er wird NICHT angetastet - sonst waeren Daten weg.
    echo.
    echo   Bitte zuerst pruefen und dann von Hand entfernen:
    echo     %ZIEL%
    echo.
    pause
    exit /b 1
  )
)

rem ---------------------------------------------------------------------------
rem Anlegen
rem ---------------------------------------------------------------------------
mklink /J "%ZIEL%" "%QUELLE%"

if errorlevel 1 (
  echo.
  echo   Anlegen fehlgeschlagen.
  echo.
  pause
  exit /b 1
)

echo.
echo   Fertig. Naechste Schritte im Spiel:
echo     1. /reload        (oder WoW neu starten)
echo     2. /tcd doctor   zeigt, ob wirklich alles greift
echo.
pause

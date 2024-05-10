import strformat
import os
import winim/lean
import strutils

type
    GROUND* = enum
        BACK = "48"
        FORE = "38"
    COLORMODE* = enum
        INT = "5"
        RGB = "2"

proc getTerminal*(): string =
    when defined(windows):
        if getEnv("WT_SESSION") != "":
            return "Windows Terminal"
        var windowTitle = newString(128)
        discard GetWindowTextA(GetForegroundWindow(), cstring(windowTitle), 128)
        var d = getCurrentDir().split("\\")
        if windowTitle.contains("Command Prompt"):
            return "Command Prompt"
        elif windowTitle.strip() == d[d.high]:
            return "Windows Powershell"

let terminal = getTerminal()

when defined(windows):
    if terminal != "Windows Terminal":
        const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
        var hOuput: HANDLE = GetStdHandle(STD_OUTPUT_HANDLE)
        SetConsoleMode(hOuput, ENABLE_PROCESSED_OUTPUT or ENABLE_VIRTUAL_TERMINAL_PROCESSING)

let prefix* = '\e'
let RESET* = $prefix & "[0m"
let UNDERLINE* = $prefix & "[4m"

proc rgb*(r: int, g: int, b: int, ground: GROUND = FORE, mode: COLORMODE = RGB): string =
    return fmt"{$prefix}[{ground};{mode};{$r};{$g};{$b}m"
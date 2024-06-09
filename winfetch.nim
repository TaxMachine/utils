import winim/[com]
import os
import strutils
import strformat
import regex
import math
import common/colors

type
    IDisk = object
        letter*: string
        fileSystem*: string
        sizeMin*: float
        sizeMax*: float
    IMemory = object
        min*: float
        max*: float
    IHostname = object
        username*: string
        hostname*: string
    IOS = object
        name*: string
        version*: string
    IUptime = object
        days*: int
        hours*: int
        minutes*: int
    IResolution = object
        width*: int
        height*: int

proc `$`(res: IResolution): string =
    return $res.width & "x" & $res.height

proc cimv2(query: string): com =
    ## WMI query for CIMv2 namespace
    ## https://learn.microsoft.com/en-us/previous-versions/windows/desktop/cimwin32a/cimwin32a-provider-classes
    ## 
    ## `query` is a WQL query string
    ## 
    ## Returns:
    ## `com` object
    ## 
    ## Example:
    ## .. code-block:: nim
    ##   import winim/com
    ##   for i in cimv2("SELECT * FROM Win32_Process"):
    ##      echo $i.Name
    var wmi = GetObject("winmgmts:{impersonationLevel=impersonate}!\\\\.\\root\\cimv2")
    result = wmi.ExecQuery(query)

var blue = rgb(30, 60, 247)
let WINLOGO: seq[string] = @[
    "                                        ",
    blue & "                        ....,,:;+ccllll " & colors.RESET,
    blue & "          ...,,+:;  cllllllllllllllllll " & colors.RESET,
    blue & "    ,cclllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "                                        " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    llllllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "    `'ccllllllllll  lllllllllllllllllll " & colors.RESET,
    blue & "           `' \\*::  :ccllllllllllllllll" & colors.RESET,
    blue & "                           ````''*::cll " & colors.RESET,
    blue & "                                     `` " & colors.RESET
]

proc getCPU(): string =
    for i in cimv2("SELECT Name FROM Win32_Processor"):
        return $i["Name"]

proc getGPU(): seq[string] =
    for i in cimv2("SELECT Name FROM Win32_VideoController"):
        result.add($i["Name"])

proc getMotherboard(): string =
    for i in cimv2("SELECT Manufacturer, Product, SerialNumber FROM Win32_BaseBoard WHERE Status = 'OK'"):
        return $i["Manufacturer"] & " " & $i["Product"]

proc getUser(): IHostname =
    return IHostname(
        username: getEnv("USERNAME"),
        hostname: getEnv("COMPUTERNAME")
    )

proc getDisks(): seq[IDisk] =
    for i in cimv2("SELECT Name, Size, FreeSpace, FileSystem FROM Win32_LogicalDisk WHERE DriveType = 3"):
        var disksize = parseInt($i["Size"])
        result.add(IDisk(
            letter: $i["Name"],
            fileSystem: $i["FileSystem"],
            sizeMax: disksize / 1024 / 1024 / 1024,
            sizeMin: (disksize - parseInt($i["FreeSpace"])) / 1024 / 1024 / 1024
        ))

proc getMemory(): IMemory =
    for i in cimv2("SELECT TotalVisibleMemorySize, FreePhysicalMemory FROM Win32_OperatingSystem"):
        var maxmem = parseInt($i["TotalVisibleMemorySize"])
        return IMemory(
            max: maxmem / 1024 / 1024,
            min: (maxmem - parseInt($i["FreePhysicalMemory"])) / 1024 / 1024
        )

proc getOS(): IOS =
    for i in cimv2("SELECT Caption, ServicePackMajorVersion, BuildNumber FROM Win32_OperatingSystem"):
        var build = $i["BuildNumber"]
        var major = $i["ServicePackMajorVersion"]
        var os = $i["Caption"]
        var m: RegexMatch2
        discard find(os, re2"Microsoft Windows ([0-9]+)", m)
        return IOS(
            name: os,
            version: fmt"{os[m.group(0)]}.{major}.{build}"
        )

proc getUptime(): IUptime =
    var uptime = GetTickCount64()
    return IUptime(
        days: splitDecimal(uptime / 1000 / 60 / 60 / 24).intpart.int,
        hours: splitDecimal(uptime / 1000 / 60 / 60 mod 24).intpart.int,
        minutes: splitDecimal(uptime / 1000 / 60 mod 60).intpart.int
    )

proc getResolution(): IResolution =
    var width = GetSystemMetrics(SM_CXSCREEN)
    var height = GetSystemMetrics(SM_CYSCREEN)
    return IResolution(
        width: width,
        height: height
    )

proc `*`(str: string, n: int): string =
    for _ in 1..n:
        result.add(str)

proc `*`(ch: char, n: int): string =
    for _ in 1..n:
        result.add(ch)

## Source: https://www.reddit.com/r/nim/comments/byob7v/is_there_an_alternative_to_echo_that_does_not/
template printf(s: varargs[string, `$`]) =
    for x in s:
        stdout.write x

proc printProperty(name: string, value: string): void =
    var tabs = '\t' * 6
    var green = rgb(26, 228, 19)
    echo fmt"{tabs}{green}{name}{colors.RESET}: {value}"

when isMainModule:
    var
        red = rgb(255, 61, 67)
        green = rgb(26, 228, 19)
        whiteish = rgb(246, 241, 241)

    var user = getUser()
    var user_bar = "-" * (user.hostname.len + 1 + user.username.len)
    var tabs = '\t' * 6

    echo WINLOGO.join("\n")
    printf(fmt"{colors.prefix}[{$(len(WINLOGO) - 2)}A{colors.prefix}[9999999D")
    echo fmt"{tabs}{red}{user.username}{whiteish}@{red}{user.hostname}{colors.RESET}"
    echo fmt"{tabs}{user_bar}"

    var osversion = getOS()
    printProperty("OS", osversion.name)
    printProperty("Kernel", osversion.version)
    
    var uptime = getUptime()
    printf fmt"{tabs}{green}Uptime{colors.RESET}: "
    if uptime.days > 0:
        printf fmt"{uptime.days} days "
    if uptime.hours > 0:
        printf fmt"{uptime.hours} hours "
    if uptime.minutes > 0:
        printf fmt"{uptime.minutes} minutes"
    echo ""

    printProperty("Terminal", getTerminal())
    printProperty("Resolution", $getResolution())
    printProperty("Motherboard", getMotherboard())

    printProperty("CPU", getCPU())
    for gpu in getGPU():
        printProperty("GPU", gpu)

    var memory = getMemory()
    printProperty("RAM", fmt"{$memory.min.formatFloat(ffDecimal, 2)}GB / {$memory.max.formatFloat(ffDecimal, 2)}GB")

    for disk in getDisks():
        printProperty("Disk", fmt"({disk.letter}) {disk.sizeMin.formatFloat(ffDecimal, 2)}GB / {disk.sizeMax.formatFloat(ffDecimal, 2)}GB")

    for i in 0..4:
        echo ""
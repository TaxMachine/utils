import winim/[com, extra]
import os
import strutils
import strformat
import regex
import math

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

let WINLOGO: seq[string] = @[
    "                                        ",
    "                        ....,,:;+ccllll ",
    "          ...,,+:;  cllllllllllllllllll ",
    "    ,cclllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "                                        ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    llllllllllllll  lllllllllllllllllll ",
    "    `'ccllllllllll  lllllllllllllllllll ",
    "           `' \\*::  :ccllllllllllllllll",
    "                           ````''*::cll ",
    "                                     `` "
]

proc getCPU(): string =
    for i in cimv2("SELECT Name FROM Win32_Processor"):
        return $i["Name"]

proc getGPU(): seq[string] =
    for i in cimv2("SELECT Name FROM Win32_VideoController"):
        result.add($i["Name"])

proc getMotherboard(): string =
    for i in cimv2("SELECT Manufacturer, Product, SerialNumber FROM Win32_BaseBoard WHERE Status = 'OK'"):
        return $i["Product"]

proc getUser(): IHostname =
    return IHostname(
        username: getEnv("USERNAME"),
        hostname: getEnv("COMPUTERNAME")
    )

proc getDisks(): seq[IDisk] =
    for i in cimv2("SELECT Name, Size, FreeSpace, FileSystem FROM Win32_LogicalDisk WHERE DriveType = 3"):
        result.add(IDisk(
            letter: $i["Name"],
            fileSystem: $i["FileSystem"],
            sizeMin: parseInt($i["Size"]) / 1024 / 1024 / 1024,
            sizeMax: parseInt($i["FreeSpace"]) / 1024 / 1024 / 1024
        ))

proc getMemory(): IMemory =
    for i in cimv2("SELECT TotalVisibleMemorySize, FreePhysicalMemory FROM Win32_OperatingSystem"):
        return IMemory(
            max: parseInt($i["TotalVisibleMemorySize"]) / 1024,
            min: parseInt($i["FreePhysicalMemory"]) / 1024
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

proc `*`(str: string, n: int): string =
    for _ in 1..n:
        result.add(str)


when isMainModule:
    var user = getUser()
    var user_bar = "-" * (user.hostname.len + 1 + user.username.len)

    echo fmt"{WINLOGO[0]}"
    echo fmt"{WINLOGO[1]}       {user.username}@{user.hostname}"
    echo fmt"{WINLOGO[2]}       {user_bar}"
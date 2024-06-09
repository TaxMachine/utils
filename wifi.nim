import strutils
import osproc
import regex
import argparse
import os

var p = newParser:
    help("a utility to export WiFi profiles saved on the current device")
    option("-s", "--ssid", help="Specify an SSID")

let profileRE = re2("\\:(.+)")
let keyRE = re2("Key Content\\W+\\:(.+)")

proc getWifiProfiles(): seq[string] =
    var profiles = execCmdEx("netsh wlan show profiles").output
    for m in findAll(profiles, profileRE):
        result.add(profiles[m.group(0)].strip())

proc getKey(ssid: string): string =
    var keymaterial = execCmdEx("netsh wlan show profile name=\"" & ssid & "\" key=clear").output
    var m: RegexMatch2
    if find(keymaterial, keyRE, m):
        var key = keymaterial[m.group(0)].strip()
        return key
    raise newException(Exception, "Key not found for SSID: " & ssid)

when isMainModule:
    try:
        var opts = p.parse(commandLineParams())
        var profiles = getWifiProfiles()
        if opts.ssid_opt.isNone():
            for p in profiles:
                echo "SSID: " & p & "\n" &
                    "Key: " & getKey(p) & "\n"
        else:
            echo "SSID: " & opts.ssid_opt.get() & "\n" &
                "Key: " & getKey(opts.ssid_opt.get())
    except ShortCircuit as e:
        echo e.help
    except Exception as e:
        stderr.writeLine(e.msg)
        quit(1)
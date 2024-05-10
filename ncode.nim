import base64
import strutils
import argparse
import os

var p = newParser:
    help("a utility to encode/decode and hash an input string")
    option("-a", "--alg", choices = @["b64", "hex"])
    flag("-d", "--decode")
    arg("input")
    
proc str2hex(str: string): string =
    for c in str:
        var charcode = cast[int](c)
        var encoded = charcode.toHex(2)
        result.add(encoded)

when isMainModule:
    var o_algorithm: string
    var o_decode: bool
    var o_input: string
    try:
        let opts = p.parse(commandLineParams())
        o_algorithm = opts.alg
        o_decode = opts.decode
        o_input = opts.input
    except ShortCircuit as err:
        echo err.help
        quit(1)
    except UsageError:
        stderr.writeLine(getCurrentExceptionMsg())
        quit(1)

    case o_algorithm:
    of "b64":
        if o_decode:
            try:
                var decoded = decode(o_input)
                echo decoded
            except ValueError as err:
                stderr.writeLine(err.msg)
                quit(1)
        else:
            var encoded = encode(o_input)
            echo encoded
    of "hex":
        if o_decode:
            var str = parseHexStr(o_input)
            echo str
        else:
            var hexstr = str2hex(o_input)
            echo hexstr
    else:
        stderr.writeLine("Invalid algorithm: " & o_algorithm)
        quit(1)
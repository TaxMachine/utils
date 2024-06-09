switch("d", "release")
switch("opt", "speed")
switch("o", "bin/")

var programs = [
    "ncode", "wifi", "winfetch"
]

var packages = [
    "argparse", "regex", "winim"
]

task build, "build all of the utils":
    for p in programs:
        exec("nim c " & p)

task install, "install every dependencies":
    for p in packages:
        echo "Installing " & p & "..."
        exec("nimble install " & p & " -y --silent")
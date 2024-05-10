import base64
import strutils
import argparse

var p = newParser:
    flag("-d", "--decode")

#!/usr/bin/env python
# coding=utf-8
"""
Copyright 2019 Xilinx Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""


from subcommands import *
import subcommands


def main():
    import argparse

    parser = argparse.ArgumentParser(description="xilinx tools")
    parser.add_argument("-v", "--version", action="version", version="%(prog)s 1.0")
    subparsers = parser.add_subparsers(
        title="sub command ", description="xmodel tools", help="sub-command help"
    )
    for i in subcommands.__all__:
        m = getattr(subcommands, i)
        m.help(subparsers)
    args = parser.parse_args()

    try:
        args.func(args)
    except AttributeError:
        parser.exit(1, parser.format_help())


if __name__ == "__main__":
    main()

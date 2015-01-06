#!/bin/bash

set -e

haxe -v --connect 6000 build.hxml

#tortilla build nw
#./build/nw/linux64/game

tortilla build browser

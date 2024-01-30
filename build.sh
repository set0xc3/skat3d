#!/bin/sh

mkdir -p bin

odin build src -out:bin/skat3d -o:none -build-mode:exe -collection:skat3d=src -debug -show-timings

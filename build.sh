#!/bin/sh

mkdir -p bin

odin build src -out:bin/out.bin -o:none -build-mode:exe -collection:my=src -debug -show-timings

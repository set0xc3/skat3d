#!/bin/sh

mkdir -p bin

odin build src -out:bin/live -o:none -build-mode:exe -collection:live=src -debug -show-timings

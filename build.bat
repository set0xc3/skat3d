@echo off

if not exist bin mkdir bin

odin.exe build src -out:bin/skat3d.exe -o:none -build-mode:exe -subsystem:console -collection:skat3d=src -debug -show-timings

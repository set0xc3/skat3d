@echo off

if not exist bin mkdir bin

odin.exe build src -out:bin/live.exe -o:none -build-mode:exe -subsystem:console -collection:live=src -debug -show-timings

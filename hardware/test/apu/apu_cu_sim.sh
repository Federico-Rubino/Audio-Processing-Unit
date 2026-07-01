#!/bin/bash
set -e

echo "Cleaning"
rm -rf .sim && mkdir .sim

echo "Analyzing"
ghdl -a --std=08 --workdir=.sim src/apu/apu_opcode_pkg.vhd src/apu/apu_internal_pkg.vhd src/apu/audio_control_unit.vhd test/apu/apu_cu_tb.vhd

echo "Elaborating"
ghdl -e --std=08 --workdir=.sim AudioCU_tb

echo "Running Simulation"
ghdl -r --std=08 --workdir=.sim AudioCU_tb --stop-time=10us --wave=wave.ghw

echo "Opening GTKWave"
gtkwave wave.ghw &
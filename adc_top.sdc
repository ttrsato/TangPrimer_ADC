# This file is generated by Anlogic Timing Wizard. 28 11 2021

#Created Clock
create_clock -name CLK_IN -period 40 -waveform {0 20} 
create_clock -name SCLK -period 50 -waveform {50 25} 
create_clock -name XRES_IN -period 100 -waveform {0 50} [get_ports {XRES_IN}]


//------------------------------------------------------------------------------
// Filename        : adc_top.v
// Description     : Anlogic EG4S20 ADC module + SPI I/F top level
// Copyright (C) 2021 Tatsuro Sato
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module adc_top
  ( 
    input  wire        CLK_IN,  // Xtal input (24MHz)
    input  wire        XRES_IN, // System reset, will be pulled-up
    input  wire        SS,      // SPI SS
    input  wire        SCLK,    // SPI SCLK
    inout  wire        MISO,    // SPI MISO
    input  wire        MOSI     // SPI MOSI (Don't use)
    );

  // T-FF for simple clock divider 24MHz->12MHz
  reg clk2; // System clock

  always @(posedge CLK_IN, negedge XRES_IN)
    begin
      if (!XRES_IN)
        begin
          clk2 <= 0;
        end
      else
        begin
          clk2 <= ~clk2;
        end
    end

  // ADC module
  wire soc;         // ADC soc
  wire eoc;         // ADC eoc
  wire [11:0] dout; // ADC dout

  adc_core u_adc_core
    (
     .eoc(eoc),   // End of conversion
     .dout(dout), // 12-bit ADC results
     .clk(clk2),  // ADC clock
     .pd(1'b0),   // Always turn on the power
     .s(3'b0),    // Channel 0 (fixed)
     .soc(soc)    // Start of conversion
     );

  // Tri-state buffer for SPI MISO. MISO will be HZ if SS goes high. 
  wire miso_o;
  bufif0 u_miso_buf(MISO, miso_o, SS);

  // Dedicated SPI I/F
  spi u_spi
    (
     .clk(clk2),      // System clock
     .xres(XRES_IN),  // System reset
     .sclk(SCLK),     // SPI SCLK
     .ss(SS),         // SPI SS
     .adc_soc(soc),   // ADC soc
     .adc_data(dout), // ADC results
     .miso(miso_o)    // SPI MISO internal buffer
   );

endmodule

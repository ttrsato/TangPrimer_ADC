//------------------------------------------------------------------------------
// Filename        : tb_spi_test.v
// Description     : Simple SPI I/F for EG4S20 ADC module
//                   CPOL = 0, CPHA = 0, 16-bit
//                   Generate ADC start flag (adc_soc)
//                   Expects ADC is done before 4th fall edge of sclk
//                   ADC data is latched by fall edge of 4th edge of sclk
//                   after that, the latched data will be shifted out to miso 
//                   from MSB of the data. Don't check eoc of ADC module.
//                   Don't use mosi.
// Copyright (C) 2021 Tatsuro Sato
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module spi
  (
   input  wire        clk,      // System clock (12MHz)
   input  wire        xres,     // System reset
   input  wire        ss,       // SPI chip select, active low
   input  wire        sclk,     // SPI clock
   output wire        miso,     // SPI data output from slave
   input  wire [11:0] adc_data, // ADC 12-bit results
   output wire        adc_soc   // ADC start of conversion flag
   );
  
  reg [2:0] ss_dly; // Sync and generate edge

  wire ss_fall = (ss_dly[2] & ~ss_dly[1]);

  always @(posedge clk, negedge xres)
    begin
      if (!xres)
        begin
          ss_dly <= 3'b0;
        end
      else
        begin
          ss_dly <= {ss_dly[1:0], ss};
        end
    end

  reg [2:0] sclk_dly; // Sync and generate edge

  wire sclk_fall = (sclk_dly[2] & ~sclk_dly[1]);

  always @(posedge clk, negedge xres)
    begin
      if (!xres)
        begin
          sclk_dly <= 3'b0;
        end
      else
        begin
          sclk_dly <= {sclk_dly[1:0], sclk};
        end
    end

  reg [3:0]  st_spi;

  assign adc_soc      = (st_spi == 4'd0 && ss_fall);
  wire   spi_load_en  = (st_spi == 4'd3 && sclk_fall);
  wire   spi_shift_en = (st_spi != 4'd3 && sclk_fall);

  // SPI state
  always @(posedge clk, negedge xres)
    begin
      if (!xres)
        begin
          st_spi <= 4'd0;
        end
      else if (sclk_fall)
        begin
          if (st_spi == 4'd15 || ss == 1'b1)
            begin
              st_spi <= 4'd0;
            end
          else
            begin
              st_spi <= st_spi + 1'b1;
            end          
        end
    end

  reg [11:0] obuf;
  assign miso = obuf[11];

  // Parallel to serial
  always @(posedge clk, negedge xres)
    begin
      if (!xres)
        begin
          obuf <= 0;
        end
      else if (spi_load_en)
        begin
          obuf <= adc_data;
        end
      else if (spi_shift_en)
        begin
          obuf <= {obuf[10:0], 1'b0};
        end
    end

endmodule

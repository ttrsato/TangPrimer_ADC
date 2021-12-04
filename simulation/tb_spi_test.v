//------------------------------------------------------------------------------
// Filename        : tb_spi_test.v
// Description     : Anlogic EG4S20 ADC module + SPI I/F test bench
// Copyright (C) 2021 Tatsuro Sato
//------------------------------------------------------------------------------

`timescale 1ns / 1ps

`define SPI_CLK2_DLY 250
`define SPI_SS_WAIT  1000

module tb_spi_test;
  reg          CLK   = 1'b0;  // 24MHz system clock
  reg          XRES  = 1'b0;  // System reset
  reg          SCLK;          // SPI SCLK
  reg          SS;            // SPI SS
  reg          MOSI;          // SPI MOSI
  wire         MISO;          // SPI MISO
  reg  [15:0]  rdata;         // SPI tentative received data (Serial to parallel)
  reg  [15:0]  RD;            // Latch rdata when SS is rised

  reg  [15:0]  in_data;       // ADC module input data

  integer      err = 0; // error counter
  integer      x   = 0; // for loop 

  // SPI write behavior task
  task spi_write;
    input [15:0] data;  // Output 16-bit data
    integer i;
    begin
      SS   = 1'b1;
      SCLK = 1'b0;
      #(`SPI_CLK2_DLY);
      SS   = 1'b0;
      MOSI = data[0];
      #(`SPI_CLK2_DLY);
      for (i = 0; i < 16; i = i + 1)
        begin
          MOSI = data[i];
          SCLK = 1'b0;
          #(`SPI_CLK2_DLY);
          SCLK = 1'b1;
          #(`SPI_CLK2_DLY);
        end
        SCLK = 1'b0;
        #(`SPI_CLK2_DLY);
      SS   = 1'b1;
    end
  endtask

  // Master tentative received data from ADC module
  always @(posedge SCLK)
    if (SS)
      begin
        rdata <= 16'd0;
      end
    else
      begin
        rdata <= {rdata[14:0], MISO};
      end

  // Master latched received data
  always @(posedge SS)
      begin
        RD <= rdata;
      end
  
  // 24MHz Xtal behavior
  always
    begin
      CLK = ~CLK;
      #20; // 24MHz
    end

  // ADC module instance
  adc_top u_adc_top
    ( 
      .CLK_IN(CLK),
      .XRES_IN(XRES),
      .SCLK(SCLK),
      .SS(SS),
      .MISO(MISO),
      .MOSI(MOSI)
      );
  
  // VCD dump file setting
  initial
    begin
      $dumpfile("tb_spi_test.vcd");
      $dumpvars(0, tb_spi_test);
    end

  // Test bench body
  initial
    begin
      XRES = 1'b0; // Force reset
      #100;
      XRES = 1'b1; // Released reset
      #100;

      // Set one hot data to ADC module diractly and received it via SPI
      for (x = 0; x < 12; x = x + 1)
        begin
          in_data = 1'b1 << x;
          force u_adc_top.u_adc_core.adc.udt.sample_B = in_data; // Set data
          spi_write(16'h5555); // Execute SPI master
          #`SPI_SS_WAIT;
          if (RD !== in_data)  // Check received data
            begin
              err = err + 1;
              $display("ERR: %t", $time);
            end
        end

      if (err == 0)
        begin
          $display("=============");
          $display(" PASS");
          $display("=============");
        end
      else
        begin
          $display("=============");
          $display(" FAIL");
          $display("=============");
        end

      $finish;
    end

endmodule

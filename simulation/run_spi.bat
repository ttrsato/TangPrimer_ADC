iverilog -T typ -Wall -yc:\Anlogic\TD4.6.4\sim\eg -o tb_spi_test.out tb_spi_test.v c:\Anlogic\TD4.6.4\sim\eg\eg_phy_glbl.v ..\al_ip\adc_core.v ..\src\spi.v ..\src\adc_top.v
vvp tb_spi_test.out

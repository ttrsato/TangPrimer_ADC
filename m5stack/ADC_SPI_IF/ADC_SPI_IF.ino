#include <M5Stack.h>

#define SCLK (5)
#define MISO (17)
#define MOSI (16)
#define SS   (22)

#define HSPI_CLK 1000000

SPIClass hspi(HSPI);
SPISettings spiSettings = SPISettings(HSPI_CLK, SPI_MSBFIRST, SPI_MODE0);

uint16_t tangPrimerADC(uint16_t data)
{
  int highByte, lowByte;

  hspi.beginTransaction(spiSettings);
  digitalWrite(SS, LOW);
  highByte = hspi.transfer((data >> 8) & 0xFF);
  lowByte  = hspi.transfer(data & 0xFF);
  digitalWrite(SS, HIGH);
  hspi.endTransaction();
  // uint16_t sign = (highByte & 0x08) ? 0xE000 : 0x0000;
  // return sign | (((highByte & 0x0F) << 8) | lowByte);
  return (((highByte & 0x0F) << 8) | lowByte);
}

// the setup routine runs once when M5Stack starts up
void setup() {
  
  // initialize the M5Stack object
  M5.begin();

  // text print
  M5.Lcd.fillScreen(BLACK);
  M5.Lcd.setTextColor(GREEN, BLACK);
  M5.Lcd.setTextSize(3);

  pinMode(SCLK, OUTPUT);
  pinMode(MISO, INPUT);
  pinMode(MOSI, OUTPUT);
  pinMode(SS,   OUTPUT);

  hspi.begin(SCLK, MISO, MOSI, SS);

}

// the loop routine runs over and over again forever
void loop(){
  M5.update();
  uint16_t adc_data = tangPrimerADC(0x1234);
  M5.Lcd.setCursor(0, 10);
  float f_data = adc_data * (3.3f / 4095.0f);
  M5.Lcd.printf("%4d : %.3f V   ", adc_data, f_data);
  // Serial.printf("%.3f\n", f_data);
  Serial.printf("%d\n", adc_data);
}

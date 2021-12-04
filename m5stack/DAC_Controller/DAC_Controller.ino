#include <M5Stack.h>

#define DAC1_PIN (26)
#define Faces_Encoder_I2C_ADDR (0X5E)

int encoder_increment;//positive: clockwise nagtive: anti-clockwise
int encoder_value=0;
int encoder_value_last=0;
int times = 1;
uint8_t direction;//0: clockwise 1: anti-clockwise
uint8_t last_button, cur_button;

void GetValue(void){
    int temp_encoder_increment;

    Wire.requestFrom(Faces_Encoder_I2C_ADDR, 3);
    if(Wire.available()){
       temp_encoder_increment = Wire.read();
       cur_button = Wire.read();
    }
    if(temp_encoder_increment > 127){//anti-clockwise
        direction = 1;
        encoder_increment = 256 - temp_encoder_increment;
    }
    else{
        direction = 0;
        encoder_increment = temp_encoder_increment;
    }

}

void Led(int i, int r, int g, int b){
    Wire.beginTransmission(Faces_Encoder_I2C_ADDR);
    Wire.write(i);
    Wire.write(r);
    Wire.write(g);
    Wire.write(b);
    Wire.endTransmission();
}

void setup()
{
    M5.begin();
    M5.Power.begin();
    Wire.begin();
    Serial.begin(115200);

    dacWrite(25, 0);
    M5.Lcd.setTextSize(3);
    M5.Lcd.fillScreen(BLACK);

    for(int i=0;i<12;i++)
    {
        Led(i, 0, 0xff, 0);
        delay(10);
    }
    for(int i=0;i<12;i++)
    {
        Led(i, 0, 0, 0);
        delay(10);
    }
    M5.Lcd.setCursor(0,40); M5.Lcd.printf("%3d : %.3f V ", encoder_value, (float)encoder_value * (3.3f / 255.0f));
    M5.Lcd.setCursor(250,200); M5.Lcd.printf("x%d", times);
    dacWrite(DAC1_PIN, encoder_value);
}

void loop()
{
    int i;
    M5.update();
    GetValue();

    if (last_button != cur_button)
    {
        last_button = cur_button;
    }
    if (cur_button)
    {
        for(i=0;i<12;i++){
            Led(i, 0, 0, 0);
        }
    }
    else
    {
        for(i=0;i<12;i++){
            Led(i, 255, 255, 255);
        }
        encoder_value = 0;
    }

    if(direction)
    {
        encoder_value -= (encoder_increment * times);
    }
    else{
        encoder_value += (encoder_increment * times);
    }
    if (encoder_value > 255) encoder_value -= 255;
    if (encoder_value <   0) encoder_value += 255;
    if (encoder_value != encoder_value_last)
    {
        M5.Lcd.setCursor(0,40); M5.Lcd.printf("%3d : %.3f V ", encoder_value, (float)encoder_value * (3.3f / 255.0f));
        dacWrite(DAC1_PIN, encoder_value);
    }
    encoder_value_last = encoder_value;
    if (M5.BtnA.wasPressed())
    {
        // M5.Lcd.printf("BtnA pressed!");
        times--;
        if (times < 1) times = 1;
        M5.Lcd.setCursor(250,200); M5.Lcd.printf("x%d", times);
    }
    else if (M5.BtnC.wasReleased())
    {
        // M5.Lcd.print("BtnA Released!");
        times++;
        if (times > 4) times = 4;
        M5.Lcd.setCursor(250,200); M5.Lcd.printf("x%d", times);
    }
    else
    {
        // M5.Lcd.print("BtnA None     ");
    }
  
    delay(10);
}

// Read 12bit ADC samples from pin PA0 of STM32F103C8T6 (blue pill) at 800kHz using DMA
// Tested on BluePill F103C8

#include "stm32f1xx.h"
#include "stm32f1xx_hal_def.h"

// number of samples
#define BUF_SIZE 500
uint16_t buffer[BUF_SIZE];

ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

inline void Serial_write16(uint16_t value) {
  // Send single uint16_t
  Serial.write((value >> 8) & 0xFF);
  Serial.write(value & 0xFF);
}

uint32_t currentSamplingTime = ADC_SAMPLETIME_1CYCLE_5;
uint32_t currentChannel = ADC_CHANNEL_0;

void MX_ADC1_Init() {
  // Configure ADC1
  hadc1.Instance = ADC1;
  hadc1.Init.ScanConvMode = ADC_SCAN_DISABLE;
  hadc1.Init.ContinuousConvMode = ENABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 1;
  if (HAL_ADC_Init(&hadc1) != HAL_OK) {
    Serial.println("HAL_ADC_Init() failed!");
    return;
  }
    
  // Configure Regular Channel
  ADC_ChannelConfTypeDef sConfig = {0};
  sConfig.Channel = currentChannel; //ADC_CHANNEL_0;
  sConfig.Rank = ADC_REGULAR_RANK_1;
  sConfig.SamplingTime = currentSamplingTime;
  //ADC_SAMPLETIME_239CYCLES_5;
  //sConfig.SamplingTime = ADC_SAMPLETIME_13CYCLES_5;
  //sConfig.SamplingTime = ADC_SAMPLETIME_7CYCLES_5;
  //sConfig.SamplingTime = ADC_SAMPLETIME_1CYCLE_5;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK){
    Serial.println("HAL_ADC_ConfigChannel() failed!");
    return;
  }

  // Configure DMA for ADC1
  __HAL_RCC_DMA1_CLK_ENABLE();
  hdma_adc1.Instance = DMA1_Channel1;
  hdma_adc1.Init.Direction = DMA_PERIPH_TO_MEMORY;
  hdma_adc1.Init.PeriphInc = DMA_PINC_DISABLE;
  hdma_adc1.Init.MemInc = DMA_MINC_ENABLE;
  hdma_adc1.Init.PeriphDataAlignment = DMA_PDATAALIGN_HALFWORD;
  hdma_adc1.Init.MemDataAlignment = DMA_MDATAALIGN_HALFWORD;
  hdma_adc1.Init.Mode = DMA_NORMAL; //DMA_CIRCULAR;
  hdma_adc1.Init.Priority = DMA_PRIORITY_LOW;
  if (HAL_DMA_Init(&hdma_adc1) != HAL_OK) {
    Serial.println("HAL_DMA_Init() failed!");
    return;
  }

  // Link DMA to ADC
  __HAL_LINKDMA(&hadc1, DMA_Handle, hdma_adc1);
}

extern "C" void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc) {
  // This should be called at the end of the conversion but it's not
  // for now I know how long it takes to measure samples so I just wait
  Serial.println("adc conversion completed");
  if (hadc->Instance == ADC1) {
    Serial.println("adc1 conversion completed");
  }
}

void analogReadFast(uint16_t* buffer, int size) {
  // read samples into buffer
  // Stop ADC and DMA after reading the first sample
  HAL_ADC_Stop_DMA(&hadc1);
  // Clear the buffer
  for (int i = 0; i < size; i++) {
    buffer[i] = 123;
  }
  // Restart ADC and DMA for the next sample and entire buffer
  if (HAL_ADC_Start_DMA(&hadc1, (uint32_t*)buffer, BUF_SIZE) != HAL_OK) {
    Serial.println("HAL_ADC_Start_DMA() failed!");
    return;
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PA0, INPUT_ANALOG);
  pinMode(PA7, INPUT_ANALOG);
  // start with PA0
  MX_ADC1_Init();
}

int t1, t2;

void Serial_wait() {
  while (not Serial.available()) {};
}
   
void loop() {
  if (Serial.available()) {
    int c = Serial.read();
   
    // B,block of data
    if (c == 'B') {
      t1 = millis();
      analogReadFast(&buffer[0], BUF_SIZE);
      delay(5);
      for (int i = 0; i < BUF_SIZE; i++) {
        Serial_write16(buffer[i]);
      }
      t2 = millis();
    }
    // Cx - channel switching, x=1..4  (lowercase c is the same but doesn't print anything back)
    if (c == 'C' || c == 'c') {
      Serial_wait();
      int r = Serial.read();
      switch (r) {
        case '1': currentChannel = ADC_CHANNEL_0; break;
        case '2': currentChannel = ADC_CHANNEL_7; break;
        case '3': currentChannel = ADC_CHANNEL_8; break;
        case '4': currentChannel = ADC_CHANNEL_9; break;
      }
      MX_ADC1_Init();
      if (c == 'C') {
        Serial_write16(currentChannel);
      }
    }
    // Sx sample time switching, x=1..8   (lowercase s is the same but doesn't print anything back)
    if (c == 'S' || c == 's') {
      Serial_wait();
      int d = Serial.read();
      switch (d) {
        case '1': currentSamplingTime = ADC_SAMPLETIME_1CYCLE_5; break;
        case '2': currentSamplingTime = ADC_SAMPLETIME_7CYCLES_5; break;
        case '3': currentSamplingTime = ADC_SAMPLETIME_13CYCLES_5; break;
        case '4': currentSamplingTime = ADC_SAMPLETIME_28CYCLES_5; break;
        case '5': currentSamplingTime = ADC_SAMPLETIME_41CYCLES_5; break;
        case '6': currentSamplingTime = ADC_SAMPLETIME_55CYCLES_5; break;
        case '7': currentSamplingTime = ADC_SAMPLETIME_71CYCLES_5; break;
        case '8': currentSamplingTime = ADC_SAMPLETIME_239CYCLES_5; break;
      }
      MX_ADC1_Init();
      if (c == 'S') {
        Serial_write16(d);
      }
    }
    // measure period of a square wave signal
    if (c == 'P') {
      analogReadFast(&buffer[0], BUF_SIZE);
      delay(5);
      // find high and low levels
      int lo = 4096;
      int hi = 0;
      for (int i = 0; i < BUF_SIZE; i++) {
        lo = buffer[i] < lo ? buffer[i] : lo;
        hi = buffer[i] > hi ? buffer[i] : hi;
      }
      int mid = (lo + hi) / 2;
      // find 3 transitions from high to low or low to high
      bool o = buffer[0] < mid ? false : true;
      int i1 = 0, i2 = 0, i3 = 0;
      for (int i = 0; i < BUF_SIZE; i++) {
        bool n = buffer[i] < mid ? false : true;
        if (o != n) {
          if (i1 == 0) {
            i1 = i;
          } else {
            if (i2 == 0) {
              i2 = i;
            } else {
              if (i3 == 0) {
                i3 = i;
                // break; no break to make all frequencies be measured in same time with same delay
              }
            }
          }
        }
        o = n;
      }
      Serial_write16(i3-i1);
    }
    
    // print some debug info
    if (c == 'j') {
      Serial.print("currentSamplingTime=");
      Serial.print(currentSamplingTime);
      Serial.print(" currentChannel=");
      Serial.print(currentChannel);
      Serial.println();
    }

    // A,average code from entire block
    if (c == 'a') {
      analogReadFast(&buffer[0], BUF_SIZE);
      delay(5);
      int s = 0;
      for (int i = 0; i < BUF_SIZE; i++) {
        s += buffer[i];
      }
      Serial_write16((10 * s) / BUF_SIZE);
    }  
    // A,average code from entire block 30 times
    if (c == 'A') {
      float t = 0;
      int repeats = 30;
      for (int r = 0; r < repeats; r++) {
        analogReadFast(&buffer[0], BUF_SIZE);
        delay(5);
        int s = 0;
        for (int i = 0; i < BUF_SIZE; i++) {
          s += buffer[i];
        }
        t += s / BUF_SIZE;
      }
      Serial_write16(10.0 * t / repeats);
    }     
  }
}

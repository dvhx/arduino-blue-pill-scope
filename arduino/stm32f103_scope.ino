// Read 12bit ADC samples from pin PA0 of STM32F103C8T6 (blue pill) at 800kHz using DMA
// Tested on BluePill F103C8

#include "stm32f1xx.h"
#include "stm32f1xx_hal_def.h"

// number of samples
#define BUF_SIZE 500
uint16_t buffer[BUF_SIZE];

ADC_HandleTypeDef hadc1;
DMA_HandleTypeDef hdma_adc1;

void MX_ADC1_Init(int which_channel) {
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
  sConfig.Channel = which_channel; //ADC_CHANNEL_0;
  sConfig.Rank = ADC_REGULAR_RANK_1;
  //sConfig.SamplingTime = ADC_SAMPLETIME_13CYCLES_5;
  //sConfig.SamplingTime = ADC_SAMPLETIME_7CYCLES_5;
  sConfig.SamplingTime = ADC_SAMPLETIME_1CYCLE_5;
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
    buffer[i] = 0;
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
  pinMode(PA1, INPUT_ANALOG);
  pinMode(PA2, INPUT_ANALOG);
  pinMode(PA3, INPUT_ANALOG);
  pinMode(PA4, INPUT_ANALOG);
  pinMode(PA5, INPUT_ANALOG);
  pinMode(PA6, INPUT_ANALOG);
  pinMode(PA7, INPUT_ANALOG);
  // start with PA0
  MX_ADC1_Init(ADC_CHANNEL_0);
  Serial.println("0=use PA0, 7=use PA7, r=read samples once, c=continous reading");
}
   
void loop() {
  if (Serial.available()) {
    int c = Serial.read();
    if (c == '0') {
      MX_ADC1_Init(ADC_CHANNEL_0);
    }
    if (c == '7') {
      MX_ADC1_Init(ADC_CHANNEL_7);
    }
    if (c == 'r') {
      // read samples once
      analogReadFast(&buffer[0], BUF_SIZE);
      delay(100);
      for (int i = 0; i < BUF_SIZE; i++) {
        Serial.println(buffer[i]);
      }
    }
    if (c == 'c') {
      // continuous mode
      while (1) {
        analogReadFast(&buffer[0], BUF_SIZE);
        delay(100);
        for (int i = 0; i < BUF_SIZE; i++) {
          Serial.println(buffer[i]);
        }
      }
    }
  }
}

void setup() {
  Serial.begin(115200);
  while (!Serial); // wait for serial port to connect.

  uint32_t uniqueId[4];
  uniqueId[0] = *(volatile uint32_t *)(0x400E0740);
  uniqueId[1] = *(volatile uint32_t *)(0x400E0744);
  uniqueId[2] = *(volatile uint32_t *)(0x400E0748);
  uniqueId[3] = *(volatile uint32_t *)(0x400E074C);

  Serial.print("Unique Device ID: ");
  for (int i = 0; i < 4; i++) {
    Serial.print(uniqueId[i], HEX);
    if (i < 3) Serial.print("-");
  }
  
  Serial.println();
}

void loop() {
  // nothing to do
}

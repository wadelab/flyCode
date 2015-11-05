
// Modified from https://coolarduino.wordpress.com/2014/03/11/fft-library-for-arduino-due-sam3x-cpu/

#include <Radix4.h>



// FFT_SIZE IS DEFINED in Header file Radix4.h
// #define   FFT_SIZE           2048

#define   MIRROR         FFT_SIZE / 2
#define   INP_BUFF       FFT_SIZE


int         f_r[FFT_SIZE]   = { 0};
int         f_i[FFT_SIZE]   = { 0};
int         out[MIRROR]     = { 0};     // Magnitudes

uint8_t    print_inp  =    0;     // print switch
Radix4     radix;



void setup()
{
  Serial.begin (115200) ;

}



void loop()
{

  // set up the data array...
  for ( uint16_t i = 0, k = (NWAVE / FFT_SIZE); i < FFT_SIZE; i++ )
  {
    f_r[i] = int(525.0 * sin (PI * i / 8) + 225.0 * sin (PI * i / 4) ) ; 
  }
  memset( f_i, 0, sizeof(f_i));                   // Image -zero.

  if ( print_inp ) {
    Serial.print("\n\tBuffer: ");
    prnt_out2( f_r, FFT_SIZE);
    print_inp =  0;
  }

  radix.rev_bin( f_r, FFT_SIZE);
  radix.fft_radix4_I( f_r, f_i, LOG2_FFT);
  radix.gain_Reset( f_r, LOG2_FFT - 1);
  radix.gain_Reset( f_i, LOG2_FFT - 1);
  radix.get_Magnit( f_r, f_i, out);


  while (Serial.available()) {
    uint8_t input = Serial.read();
    switch (input) {
      case '\r':
        break;
      case 'x':
        print_inp = 1;
        break;
      case 'f':
        Serial.print("\n\tReal: ");
        prnt_out2( f_r, MIRROR);
        Serial.print("\n\tImag: ");
        prnt_out2( f_i, MIRROR);
        break;
      case 'o':
        Serial.print("\n\tMagnitudes: ");
        prnt_out2( out, MIRROR);
        break;

      case '?':
      case 'h':
        cmd_print_help();
        break;
      default: // -------------------------------
        Serial.print("Unexpected: ");
        Serial.print((char)input);
        cmd_print_help();
    }
    Serial.print("> ");
  }


}

void prnt_out2( int *array, int dlina)
{
  Serial.print("\n\t");
  for ( uint32_t i = 0; i < dlina; i++)
  {
    Serial.print(array[i]);
    Serial.print("\t");
    if ((i + 1) % 16 == 0) Serial.print("\n\t");
  }
  Serial.println("\n\t");
}



void cmd_print_help(void)
{
  Serial.println("\n  Listing of all available CLI Commands\n");
  Serial.println("\t\"?\" or \"h\": print this menu");
  Serial.println("\t\"x\": print out adc array");
  Serial.println("\t\"f\": print out fft array");
  Serial.println("\t\"o\": print out magnitude array");

}




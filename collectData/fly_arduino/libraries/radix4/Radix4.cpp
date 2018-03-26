/*
 **************************       RADIX-4 FFT LIBRARY      *************************
 * http://coolarduino.wordpress.com
 *
 * Created for Arduino DUE & like boards, word size optimized for 12-bits data input.
 * 
 * FFT takes as input ANY size of inputs array 8, 16, 32, 64, 128, 256, 512, 1024, 2048.
 * Max. size 2048 defined by LUT. 
 *
 * Library may run on different platform, only PROGMEM macros and variable declaration
 * type may need to be adjusted accordingly.
 *
 * Algorithm tested on Arduino DUE and IDE 1.5.6-r2 (Tested on Linux OS only).
 *
 * Timing results, in usec:
 * Hamng 864	Revb 817	RDX4 6968	GainR 320	Sqrt 5297	Sqrt2 405
 *
 * There is two subfunctions for magnitude calculation, as you can see second one runs 
 * more than 10x times faster, but it is less accurate, error in worst case scenario
 * may reach 5 %. Approximation based on
 *
 * http://www.dspguru.com/dsp/tricks/magnitude-estimator
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute copies of the Software, 
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * Copyright (C) 2014 Anatoly Kuzmenko.
 * All Rights Reserved.
 * 11 March 2014 
 * k_anatoly@hotmail.com
 *********************************************************************************************
 */
#include "Radix4.h"

Radix4::Radix4() {
}

void Radix4::get_Magnit2(int *f_r, int *f_i, int *f_o)
{	
   const       int16_t  alpha             =  3881, beta = 1608;   

   for ( int  i = 1; i < MIRROR; i++) { //Fastest Magnitude Calculation, w/o slow sqrt.

      int abs_R = abs(f_r[i]);
      int abs_I = abs(f_i[i]);
      int tmp_M;

      if (abs_R > abs_I) tmp_M = mult_shft( alpha, abs_R) + mult_shft( beta, abs_I);
      else               tmp_M = mult_shft( alpha, abs_I) + mult_shft( beta, abs_R);

      f_o[i] = tmp_M;
     }
}

void Radix4::get_Magnit(int *f_r, int *f_i, int *f_o)
{
    for ( int  i = 0; i < MIRROR; i++) {
    	f_o[i] = sqrt((f_r[i] * f_r[i]) + (f_i[i] * f_i[i]));
    }
}

void Radix4::gain_Reset(int *fr, int r_bit)
{
    for ( int  i = 0; i < MIRROR; i++) {
        int delit = fr[i];
        if ( delit  <  0 ) delit = ((delit >> r_bit) +1); // round_down.
        else delit = delit >> r_bit;
        fr[i] = delit;
    }
}

//static inline int Radix4::mult_shft( int a, int b)  __attribute__((always_inline));
inline int Radix4::mult_shft( int a, int b)  
{
  return (( a  *  b )  >> 12);      
}

//static inline void Radix4::mult_shf_I( int c, int s, int x, int y, int &u, int &v)  __attribute__((always_inline));
inline void Radix4::mult_shf_I( int c, int s, int x, int y, int &u, int &v)
{
  u = ((x  *  c)  - (y  *  s))  >> 12;
  v = ((y  *  c)  + (x  *  s))  >> 12;
}

//static inline void Radix4::sum_dif_I(int a, int b, int &s, int &d)  __attribute__((always_inline));
inline void Radix4::sum_dif_I(int a, int b, int &s, int &d)
{
  s = (a + b);   
  d = (a - b); 
}

void Radix4::rev_bin( int *fr, int fft_n)
{
    int m, mr, nn, l;
    int tr;

    mr = 0;
    nn = fft_n - 1;

    for (m=1; m<=nn; ++m) {
            l = fft_n;
         do {
             l >>= 1;
            } while (mr+l > nn);

            mr = (mr & (l-1)) + l;

        if (mr <= m)
             continue;
            tr = fr[m];
            fr[m] = fr[mr];
            fr[mr] = tr;
    }
}

void Radix4::fft8_dit_core_p1(int *fr, int *fi)
{
    int plus1a, plus2a, plus3a, plus4a, plus1b, plus2b;
    int mins1a, mins2a, mins3a, mins4a, mins1b, mins2b, mM1a, mM2a;

    sum_dif_I(fr[0], fr[1], plus1a, mins1a);
    sum_dif_I(fr[2], fr[3], plus2a, mins2a);
    sum_dif_I(fr[4], fr[5], plus3a, mins3a);
    sum_dif_I(fr[6], fr[7], plus4a, mins4a);

    sum_dif_I(plus1a, plus2a, plus1b, mins1b);
    sum_dif_I(plus3a, plus4a, plus2b, mins2b);

    sum_dif_I(plus1b, plus2b, fr[0], fr[4]);
    sum_dif_I(mins3a, mins4a, mM1a, mM2a);

    int prib1a, prib2a, prib3a, prib4a, prib1b, prib2b;
    int otnt1a, otnt2a, otnt3a, otnt4a, otnt1b, otnt2b, oT1a, oT2a;

    sum_dif_I(fi[0], fi[1], prib1a, otnt1a);
    sum_dif_I(fi[2], fi[3], prib2a, otnt2a);
    sum_dif_I(fi[4], fi[5], prib3a, otnt3a);
    sum_dif_I(fi[6], fi[7], prib4a, otnt4a);

    sum_dif_I(prib1a, prib2a, prib1b, otnt1b);
    sum_dif_I(prib3a, prib4a, prib2b, otnt2b);

    sum_dif_I(prib1b, prib2b, fi[0], fi[4]);
    sum_dif_I(otnt3a, otnt4a, oT1a, oT2a);

    mM2a   = mult_shft(mM2a, 2896);
    sum_dif_I(mins1a,   mM2a, plus1a, plus2a);

    prib2b = mult_shft(oT1a, 2896);
    sum_dif_I(otnt2a, prib2b, mins3a, plus3a);

    sum_dif_I(plus1a, mins3a, fr[7], fr[1]);
    sum_dif_I(mins1b, otnt2b, fr[6], fr[2]);
    sum_dif_I(plus2a, plus3a, fr[3], fr[5]);

    oT2a   = mult_shft(oT2a, 2896);
    sum_dif_I( otnt1a,   oT2a, plus1a, plus2a);

    plus2b = mult_shft(mM1a, 2896);
    sum_dif_I(-mins2a, plus2b, plus3a, mins3a);

    sum_dif_I(plus1a, mins3a, fi[7], fi[1]);
    sum_dif_I(otnt1b,-mins2b, fi[6], fi[2]);
    sum_dif_I(plus2a, plus3a, fi[3], fi[5]);
}

void Radix4::fft_radix4_I( int *fr, int *fi, int ldn)
{
    const int n = (1UL<<ldn);
    int ldm = 0, rdx = 2;

    ldm = (ldn&1);
    if ( ldm!=0 )
    {
        for (int i0=0; i0<n; i0+=8)
        {
            fft8_dit_core_p1(fr+i0, fi+i0);
        }
    }
    else
       {
    for (int i0 = 0; i0 < n; i0 += 4)
        {
            int xr,yr,ur,vr, xi,yi,ui,vi;

            int i1 = i0 + 1;
            int i2 = i1 + 1;
            int i3 = i2 + 1;

            sum_dif_I(fr[i0], fr[i1], xr, ur);
            sum_dif_I(fr[i2], fr[i3], yr, vi);
            sum_dif_I(fi[i0], fi[i1], xi, ui);
            sum_dif_I(fi[i3], fi[i2], yi, vr);

            sum_dif_I(ui, vi, fi[i1], fi[i3]);
            sum_dif_I(xi, yi, fi[i0], fi[i2]);
            sum_dif_I(ur, vr, fr[i1], fr[i3]);
            sum_dif_I(xr, yr, fr[i0], fr[i2]);
        }
       }    
    for (ldm += 2 * rdx; ldm <= ldn; ldm += rdx)
    {
        int m = (1UL<<ldm);
        int m4 = (m>>rdx);

        int phI0 =  NWAVE / m;                            
        int phI  = 0;

        for (int j = 0; j < m4; j++)
        {
        int c,s,c2,s2,c3,s3;

         s  = Sinewave[   phI];
         s2 = Sinewave[ 2*phI];
         s3 = Sinewave[ 3*phI];

         c  = Sinewave[   phI + NWAVE/4];
         c2 = Sinewave[ 2*phI + NWAVE/4];
         c3 = Sinewave[ 3*phI + NWAVE/4];

       for (int r = 0; r < n; r += m)    
       {
                int i0 = j + r;
                int i1 = i0 + m4;
                int i2 = i1 + m4;
                int i3 = i2 + m4;

           int xr,yr,ur,vr, xi,yi,ui,vi;

             mult_shf_I( c2, s2, fr[i1], fi[i1], xr, xi);
             mult_shf_I(  c,  s, fr[i2], fi[i2], yr, vr);
             mult_shf_I( c3, s3, fr[i3], fi[i3], vi, yi);

             int t = yi - vr;
                yi += vr;
                vr = t;

                ur = fr[i0] - xr;
                xr += fr[i0];

              sum_dif_I(ur, vr, fr[i1], fr[i3]);

                 t = yr - vi;
                yr += vi;
                vi = t;

                ui = fi[i0] - xi;
                xi += fi[i0];

              sum_dif_I(ui, vi, fi[i1], fi[i3]);
              sum_dif_I(xr, yr, fr[i0], fr[i2]);
              sum_dif_I(xi, yi, fi[i0], fi[i2]);
            }
          phI += phI0;
        }
    }
}


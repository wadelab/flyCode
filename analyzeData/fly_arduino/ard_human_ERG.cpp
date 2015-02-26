//
//  main.cpp
//  ard_translate
//
//  Created by chris on 25/02/2015.
//  Copyright (c) 2015 chris. All rights reserved.
//

#include <iostream>
#include <fstream>
#include "stdio.h"
#include "math.h"

typedef uint8_t byte;
#define PI 3.141

const byte maxContrasts = 9 ;
const byte F2contrastchange = 4;
const double F1contrast[] = {
    5.0, 10.0, 30.0, 70.0, 100.0,  5.0, 10.0, 30.0, 70.0
};
const byte F2contrast[] = {
    0, 30
};
byte contrastOrder[ maxContrasts ];
byte iThisContrast = 0 ;

const double freq1 = 12.0 ; // flicker of LED Hz
const double freq2 = 15.0 ; // flicker of LED Hz

const int MaxInputStr = 135 ;

const short max_data = 1025  ;
unsigned short time_stamp [max_data] ;
short erg_in [max_data];


uint16_t swap_uint16( uint16_t val )
{
    return (val << 8) | (val >> 8 );
}

//! Byte swap short
int16_t swap_int16( int16_t val )
{
    return (val << 8) | ((val >> 8) & 0xFF);
}

int br_Now(double t)
{
    int randomnumber = contrastOrder[iThisContrast];
    int F2index = 0 ;
    if (randomnumber > F2contrastchange) F2index = 1;
    return int(sin((t / 1000.0) * PI * 2.0 * freq1) * 1.270 * F1contrast[randomnumber] + sin((t / 1000.0) * PI * 2.0 * freq2) * 1.270 * F2contrast[F2index]) + 127;
}

int fERG_Now (unsigned int t)
{
    // 2ms per sample
    if (t < (2 * max_data) / 3) return 0;
    if (t > (4 * max_data) / 3) return 0;
    return 255;
}


int doreadFile (const char * c)
{
    char  cPtr [MaxInputStr + 2];
    std::ifstream file ;

    file.open(c) ; // root, c, O_READ);

    int iBytesRequested;
    long iBytesRead;
    // note this overwrites any data already in memeory...
    //first read the header string ...
    iBytesRequested = MaxInputStr + 2;
    file.read(cPtr, iBytesRequested);
    iBytesRead = file.gcount() ;
    
    // write out the string ....
    std::cout << (cPtr);
    //std::cout << '\n' ;
    // test if its an ERG
    bool bERG = ( NULL != strstr ( cPtr, "stim=fERG&") ) ;
    
    // now on to the data
    iBytesRequested = max_data * sizeof (short);
    file.read((char *)erg_in, iBytesRequested);
    iBytesRead = file.gcount() ;
    int nBlocks = 0;
    while (iBytesRead == iBytesRequested)
    {
        iBytesRequested = max_data * sizeof (short);
        file.read ((char *)time_stamp, iBytesRequested );
        nBlocks ++;
//        Serial.print ("Reading file blocks ");
//        Serial.println (nBlocks);
        
        for (int i = 0; i < max_data - 1; i++)
        {
            // make a string for assembling the data to log:
            std::cout << (time_stamp[i]);
            std::cout << ", ";
            if (bERG)
            {
                std::cout <<( fERG_Now (time_stamp[i] - time_stamp[0] ) );
            }
            else
            {
                std::cout <<(br_Now(time_stamp[i]));
            }
            std::cout << ", ";
            
            std::cout << (erg_in[i]);
            std::cout << "\n";
        } //for
        
        // write out contrast
        
        std::cout << "-99, ";
        
        std::cout <<(time_stamp[max_data - 1]);
        std::cout << ", ";
        
        std::cout <<(erg_in[max_data - 1]);
        std::cout << "\n";
        //read next block
        iBytesRequested = max_data * sizeof (short);
        file.read((char *)erg_in, iBytesRequested);
        iBytesRead = file.gcount() ;
    } // end of while
    
    file.close();
    return nBlocks ;
    
}


int main(int argc, const char * argv[]) {
    // insert code here...
    
    int iBlocks = doreadFile (argv[1]);
    
    
    
    return iBlocks;
}

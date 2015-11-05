
#ifndef _RADIX4_H_
#define _RADIX4_H_

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <inttypes.h>
#include <avr/pgmspace.h>

#define    FFT_SIZE          1024 //256
#define    MIRROR        FFT_SIZE / 2
#define    LOG2_FFT            10                   /* log2 FFT_SIZE */
//#define    NWAVE              256                   /* full length of Sinewave[] */
#define    NWAVE             2048                   /* full length of Sinewave[] */
/*
const int16_t  Sinewave[NWAVE] = {

      +0,    +100,    +200,    +301,    +401,    +501,    +600,    +700,    +798,    +897,    +995,   +1092,   +1188,   +1284,   +1379,   +1473,
   +1567,   +1659,   +1750,   +1841,   +1930,   +2018,   +2105,   +2190,   +2275,   +2357,   +2439,   +2519,   +2597,   +2674,   +2750,   +2823,
   +2895,   +2965,   +3034,   +3100,   +3165,   +3228,   +3289,   +3348,   +3404,   +3459,   +3512,   +3563,   +3611,   +3657,   +3701,   +3743,
   +3783,   +3820,   +3855,   +3888,   +3918,   +3946,   +3972,   +3995,   +4016,   +4034,   +4050,   +4064,   +4075,   +4083,   +4090,   +4093,
   +4095,   +4093,   +4090,   +4083,   +4075,   +4064,   +4050,   +4034,   +4016,   +3995,   +3972,   +3946,   +3918,   +3888,   +3855,   +3820,
   +3783,   +3743,   +3701,   +3657,   +3611,   +3563,   +3512,   +3459,   +3404,   +3348,   +3289,   +3228,   +3165,   +3100,   +3034,   +2965,
   +2895,   +2823,   +2750,   +2674,   +2597,   +2519,   +2439,   +2357,   +2275,   +2190,   +2105,   +2018,   +1930,   +1841,   +1750,   +1659,
   +1567,   +1473,   +1379,   +1284,   +1188,   +1092,    +995,    +897,    +798,    +700,    +600,    +501,    +401,    +301,    +200,    +100,
      +0,    -100,    -200,    -301,    -401,    -501,    -600,    -700,    -798,    -897,    -995,   -1092,   -1188,   -1284,   -1379,   -1473,
   -1567,   -1659,   -1750,   -1841,   -1930,   -2018,   -2105,   -2190,   -2275,   -2357,   -2439,   -2519,   -2597,   -2674,   -2750,   -2823,
   -2895,   -2965,   -3034,   -3100,   -3165,   -3228,   -3289,   -3348,   -3404,   -3459,   -3512,   -3563,   -3611,   -3657,   -3701,   -3743,
   -3783,   -3820,   -3855,   -3888,   -3918,   -3946,   -3972,   -3995,   -4016,   -4034,   -4050,   -4064,   -4075,   -4083,   -4090,   -4093,
   -4095,   -4093,   -4090,   -4083,   -4075,   -4064,   -4050,   -4034,   -4016,   -3995,   -3972,   -3946,   -3918,   -3888,   -3855,   -3820,
   -3783,   -3743,   -3701,   -3657,   -3611,   -3563,   -3512,   -3459,   -3404,   -3348,   -3289,   -3228,   -3165,   -3100,   -3034,   -2965,
   -2895,   -2823,   -2750,   -2674,   -2597,   -2519,   -2439,   -2357,   -2275,   -2190,   -2105,   -2018,   -1930,   -1841,   -1750,   -1659,
   -1567,   -1473,   -1379,   -1284,   -1188,   -1092,    -995,    -897,    -798,    -700,    -600,    -501,    -401,    -301,    -200,    -100
};
*/
const int16_t  Sinewave[NWAVE] PROGMEM = {

    +0,   +13,   +25,   +38,   +50,   +63,   +75,   +88,  +100,  +113,  +126,  +138,  +151,  +163,  +176,  +188,
  +201,  +213,  +226,  +239,  +251,  +264,  +276,  +289,  +301,  +314,  +326,  +339,  +351,  +364,  +376,  +389,
  +401,  +414,  +426,  +439,  +451,  +464,  +476,  +489,  +501,  +514,  +526,  +539,  +551,  +564,  +576,  +588,
  +601,  +613,  +626,  +638,  +651,  +663,  +675,  +688,  +700,  +712,  +725,  +737,  +750,  +762,  +774,  +787,
  +799,  +811,  +824,  +836,  +848,  +860,  +873,  +885,  +897,  +909,  +922,  +934,  +946,  +958,  +971,  +983,
  +995, +1007, +1019, +1032, +1044, +1056, +1068, +1080, +1092, +1104, +1116, +1128, +1141, +1153, +1165, +1177,
 +1189, +1201, +1213, +1225, +1237, +1249, +1261, +1273, +1285, +1296, +1308, +1320, +1332, +1344, +1356, +1368,
 +1380, +1391, +1403, +1415, +1427, +1439, +1450, +1462, +1474, +1485, +1497, +1509, +1521, +1532, +1544, +1555,
 +1567, +1579, +1590, +1602, +1613, +1625, +1636, +1648, +1659, +1671, +1682, +1694, +1705, +1717, +1728, +1739,
 +1751, +1762, +1774, +1785, +1796, +1807, +1819, +1830, +1841, +1852, +1864, +1875, +1886, +1897, +1908, +1919,
 +1930, +1941, +1952, +1964, +1975, +1986, +1997, +2007, +2018, +2029, +2040, +2051, +2062, +2073, +2084, +2094,
 +2105, +2116, +2127, +2137, +2148, +2159, +2170, +2180, +2191, +2201, +2212, +2223, +2233, +2244, +2254, +2265,
 +2275, +2285, +2296, +2306, +2317, +2327, +2337, +2348, +2358, +2368, +2378, +2389, +2399, +2409, +2419, +2429,
 +2439, +2449, +2460, +2470, +2480, +2490, +2500, +2509, +2519, +2529, +2539, +2549, +2559, +2569, +2578, +2588,
 +2598, +2608, +2617, +2627, +2636, +2646, +2656, +2665, +2675, +2684, +2694, +2703, +2713, +2722, +2731, +2741,
 +2750, +2759, +2769, +2778, +2787, +2796, +2805, +2815, +2824, +2833, +2842, +2851, +2860, +2869, +2878, +2887,
 +2896, +2904, +2913, +2922, +2931, +2940, +2948, +2957, +2966, +2974, +2983, +2992, +3000, +3009, +3017, +3026,
 +3034, +3043, +3051, +3059, +3068, +3076, +3084, +3093, +3101, +3109, +3117, +3125, +3133, +3141, +3149, +3157,
 +3165, +3173, +3181, +3189, +3197, +3205, +3213, +3221, +3228, +3236, +3244, +3251, +3259, +3267, +3274, +3282,
 +3289, +3297, +3304, +3311, +3319, +3326, +3333, +3341, +3348, +3355, +3362, +3370, +3377, +3384, +3391, +3398,
 +3405, +3412, +3419, +3426, +3433, +3439, +3446, +3453, +3460, +3466, +3473, +3480, +3486, +3493, +3499, +3506,
 +3512, +3519, +3525, +3532, +3538, +3544, +3551, +3557, +3563, +3569, +3575, +3581, +3588, +3594, +3600, +3606,
 +3611, +3617, +3623, +3629, +3635, +3641, +3646, +3652, +3658, +3663, +3669, +3675, +3680, +3686, +3691, +3696,
 +3702, +3707, +3713, +3718, +3723, +3728, +3733, +3739, +3744, +3749, +3754, +3759, +3764, +3769, +3774, +3778,
 +3783, +3788, +3793, +3798, +3802, +3807, +3811, +3816, +3821, +3825, +3830, +3834, +3838, +3843, +3847, +3851,
 +3856, +3860, +3864, +3868, +3872, +3876, +3880, +3884, +3888, +3892, +3896, +3900, +3904, +3908, +3911, +3915,
 +3919, +3922, +3926, +3929, +3933, +3936, +3940, +3943, +3947, +3950, +3953, +3957, +3960, +3963, +3966, +3969,
 +3972, +3975, +3978, +3981, +3984, +3987, +3990, +3993, +3996, +3998, +4001, +4004, +4006, +4009, +4011, +4014,
 +4016, +4019, +4021, +4023, +4026, +4028, +4030, +4033, +4035, +4037, +4039, +4041, +4043, +4045, +4047, +4049,
 +4051, +4053, +4054, +4056, +4058, +4059, +4061, +4063, +4064, +4066, +4067, +4069, +4070, +4071, +4073, +4074,
 +4075, +4076, +4078, +4079, +4080, +4081, +4082, +4083, +4084, +4085, +4086, +4087, +4087, +4088, +4089, +4089,
 +4090, +4091, +4091, +4092, +4092, +4093, +4093, +4093, +4094, +4094, +4094, +4095, +4095, +4095, +4095, +4095,
 +4095, +4095, +4095, +4095, +4095, +4095, +4094, +4094, +4094, +4093, +4093, +4093, +4092, +4092, +4091, +4091,
 +4090, +4089, +4089, +4088, +4087, +4087, +4086, +4085, +4084, +4083, +4082, +4081, +4080, +4079, +4078, +4076,
 +4075, +4074, +4073, +4071, +4070, +4069, +4067, +4066, +4064, +4063, +4061, +4059, +4058, +4056, +4054, +4053,
 +4051, +4049, +4047, +4045, +4043, +4041, +4039, +4037, +4035, +4033, +4030, +4028, +4026, +4023, +4021, +4019,
 +4016, +4014, +4011, +4009, +4006, +4004, +4001, +3998, +3996, +3993, +3990, +3987, +3984, +3981, +3978, +3975,
 +3972, +3969, +3966, +3963, +3960, +3957, +3953, +3950, +3947, +3943, +3940, +3936, +3933, +3929, +3926, +3922,
 +3919, +3915, +3911, +3908, +3904, +3900, +3896, +3892, +3888, +3884, +3880, +3876, +3872, +3868, +3864, +3860,
 +3856, +3851, +3847, +3843, +3838, +3834, +3830, +3825, +3821, +3816, +3811, +3807, +3802, +3798, +3793, +3788,
 +3783, +3778, +3774, +3769, +3764, +3759, +3754, +3749, +3744, +3739, +3733, +3728, +3723, +3718, +3713, +3707,
 +3702, +3696, +3691, +3686, +3680, +3675, +3669, +3663, +3658, +3652, +3646, +3641, +3635, +3629, +3623, +3617,
 +3611, +3606, +3600, +3594, +3588, +3581, +3575, +3569, +3563, +3557, +3551, +3544, +3538, +3532, +3525, +3519,
 +3512, +3506, +3499, +3493, +3486, +3480, +3473, +3466, +3460, +3453, +3446, +3439, +3433, +3426, +3419, +3412,
 +3405, +3398, +3391, +3384, +3377, +3370, +3362, +3355, +3348, +3341, +3333, +3326, +3319, +3311, +3304, +3297,
 +3289, +3282, +3274, +3267, +3259, +3251, +3244, +3236, +3228, +3221, +3213, +3205, +3197, +3189, +3181, +3173,
 +3165, +3157, +3149, +3141, +3133, +3125, +3117, +3109, +3101, +3093, +3084, +3076, +3068, +3059, +3051, +3043,
 +3034, +3026, +3017, +3009, +3000, +2992, +2983, +2974, +2966, +2957, +2948, +2940, +2931, +2922, +2913, +2904,
 +2896, +2887, +2878, +2869, +2860, +2851, +2842, +2833, +2824, +2815, +2805, +2796, +2787, +2778, +2769, +2759,
 +2750, +2741, +2731, +2722, +2713, +2703, +2694, +2684, +2675, +2665, +2656, +2646, +2636, +2627, +2617, +2608,
 +2598, +2588, +2578, +2569, +2559, +2549, +2539, +2529, +2519, +2509, +2500, +2490, +2480, +2470, +2460, +2449,
 +2439, +2429, +2419, +2409, +2399, +2389, +2378, +2368, +2358, +2348, +2337, +2327, +2317, +2306, +2296, +2285,
 +2275, +2265, +2254, +2244, +2233, +2223, +2212, +2201, +2191, +2180, +2170, +2159, +2148, +2137, +2127, +2116,
 +2105, +2094, +2084, +2073, +2062, +2051, +2040, +2029, +2018, +2007, +1997, +1986, +1975, +1964, +1952, +1941,
 +1930, +1919, +1908, +1897, +1886, +1875, +1864, +1852, +1841, +1830, +1819, +1807, +1796, +1785, +1774, +1762,
 +1751, +1739, +1728, +1717, +1705, +1694, +1682, +1671, +1659, +1648, +1636, +1625, +1613, +1602, +1590, +1579,
 +1567, +1555, +1544, +1532, +1521, +1509, +1497, +1485, +1474, +1462, +1450, +1439, +1427, +1415, +1403, +1391,
 +1380, +1368, +1356, +1344, +1332, +1320, +1308, +1296, +1285, +1273, +1261, +1249, +1237, +1225, +1213, +1201,
 +1189, +1177, +1165, +1153, +1141, +1128, +1116, +1104, +1092, +1080, +1068, +1056, +1044, +1032, +1019, +1007,
  +995,  +983,  +971,  +958,  +946,  +934,  +922,  +909,  +897,  +885,  +873,  +860,  +848,  +836,  +824,  +811,
  +799,  +787,  +774,  +762,  +750,  +737,  +725,  +712,  +700,  +688,  +675,  +663,  +651,  +638,  +626,  +613,
  +601,  +588,  +576,  +564,  +551,  +539,  +526,  +514,  +501,  +489,  +476,  +464,  +451,  +439,  +426,  +414,
  +401,  +389,  +376,  +364,  +351,  +339,  +326,  +314,  +301,  +289,  +276,  +264,  +251,  +239,  +226,  +213,
  +201,  +188,  +176,  +163,  +151,  +138,  +126,  +113,  +100,   +88,   +75,   +63,   +50,   +38,   +25,   +13,
    +0,   -13,   -25,   -38,   -50,   -63,   -75,   -88,  -100,  -113,  -126,  -138,  -151,  -163,  -176,  -188,
  -201,  -213,  -226,  -239,  -251,  -264,  -276,  -289,  -301,  -314,  -326,  -339,  -351,  -364,  -376,  -389,
  -401,  -414,  -426,  -439,  -451,  -464,  -476,  -489,  -501,  -514,  -526,  -539,  -551,  -564,  -576,  -588,
  -601,  -613,  -626,  -638,  -651,  -663,  -675,  -688,  -700,  -712,  -725,  -737,  -750,  -762,  -774,  -787,
  -799,  -811,  -824,  -836,  -848,  -860,  -873,  -885,  -897,  -909,  -922,  -934,  -946,  -958,  -971,  -983,
  -995, -1007, -1019, -1032, -1044, -1056, -1068, -1080, -1092, -1104, -1116, -1128, -1141, -1153, -1165, -1177,
 -1189, -1201, -1213, -1225, -1237, -1249, -1261, -1273, -1285, -1296, -1308, -1320, -1332, -1344, -1356, -1368,
 -1380, -1391, -1403, -1415, -1427, -1439, -1450, -1462, -1474, -1485, -1497, -1509, -1521, -1532, -1544, -1555,
 -1567, -1579, -1590, -1602, -1613, -1625, -1636, -1648, -1659, -1671, -1682, -1694, -1705, -1717, -1728, -1739,
 -1751, -1762, -1774, -1785, -1796, -1807, -1819, -1830, -1841, -1852, -1864, -1875, -1886, -1897, -1908, -1919,
 -1930, -1941, -1952, -1964, -1975, -1986, -1997, -2007, -2018, -2029, -2040, -2051, -2062, -2073, -2084, -2094,
 -2105, -2116, -2127, -2137, -2148, -2159, -2170, -2180, -2191, -2201, -2212, -2223, -2233, -2244, -2254, -2265,
 -2275, -2285, -2296, -2306, -2317, -2327, -2337, -2348, -2358, -2368, -2378, -2389, -2399, -2409, -2419, -2429,
 -2439, -2449, -2460, -2470, -2480, -2490, -2500, -2509, -2519, -2529, -2539, -2549, -2559, -2569, -2578, -2588,
 -2598, -2608, -2617, -2627, -2636, -2646, -2656, -2665, -2675, -2684, -2694, -2703, -2713, -2722, -2731, -2741,
 -2750, -2759, -2769, -2778, -2787, -2796, -2805, -2815, -2824, -2833, -2842, -2851, -2860, -2869, -2878, -2887,
 -2896, -2904, -2913, -2922, -2931, -2940, -2948, -2957, -2966, -2974, -2983, -2992, -3000, -3009, -3017, -3026,
 -3034, -3043, -3051, -3059, -3068, -3076, -3084, -3093, -3101, -3109, -3117, -3125, -3133, -3141, -3149, -3157,
 -3165, -3173, -3181, -3189, -3197, -3205, -3213, -3221, -3228, -3236, -3244, -3251, -3259, -3267, -3274, -3282,
 -3289, -3297, -3304, -3311, -3319, -3326, -3333, -3341, -3348, -3355, -3362, -3370, -3377, -3384, -3391, -3398,
 -3405, -3412, -3419, -3426, -3433, -3439, -3446, -3453, -3460, -3466, -3473, -3480, -3486, -3493, -3499, -3506,
 -3512, -3519, -3525, -3532, -3538, -3544, -3551, -3557, -3563, -3569, -3575, -3581, -3588, -3594, -3600, -3606,
 -3611, -3617, -3623, -3629, -3635, -3641, -3646, -3652, -3658, -3663, -3669, -3675, -3680, -3686, -3691, -3696,
 -3702, -3707, -3713, -3718, -3723, -3728, -3733, -3739, -3744, -3749, -3754, -3759, -3764, -3769, -3774, -3778,
 -3783, -3788, -3793, -3798, -3802, -3807, -3811, -3816, -3821, -3825, -3830, -3834, -3838, -3843, -3847, -3851,
 -3856, -3860, -3864, -3868, -3872, -3876, -3880, -3884, -3888, -3892, -3896, -3900, -3904, -3908, -3911, -3915,
 -3919, -3922, -3926, -3929, -3933, -3936, -3940, -3943, -3947, -3950, -3953, -3957, -3960, -3963, -3966, -3969,
 -3972, -3975, -3978, -3981, -3984, -3987, -3990, -3993, -3996, -3998, -4001, -4004, -4006, -4009, -4011, -4014,
 -4016, -4019, -4021, -4023, -4026, -4028, -4030, -4033, -4035, -4037, -4039, -4041, -4043, -4045, -4047, -4049,
 -4051, -4053, -4054, -4056, -4058, -4059, -4061, -4063, -4064, -4066, -4067, -4069, -4070, -4071, -4073, -4074,
 -4075, -4076, -4078, -4079, -4080, -4081, -4082, -4083, -4084, -4085, -4086, -4087, -4087, -4088, -4089, -4089,
 -4090, -4091, -4091, -4092, -4092, -4093, -4093, -4093, -4094, -4094, -4094, -4095, -4095, -4095, -4095, -4095,
 -4095, -4095, -4095, -4095, -4095, -4095, -4094, -4094, -4094, -4093, -4093, -4093, -4092, -4092, -4091, -4091,
 -4090, -4089, -4089, -4088, -4087, -4087, -4086, -4085, -4084, -4083, -4082, -4081, -4080, -4079, -4078, -4076,
 -4075, -4074, -4073, -4071, -4070, -4069, -4067, -4066, -4064, -4063, -4061, -4059, -4058, -4056, -4054, -4053,
 -4051, -4049, -4047, -4045, -4043, -4041, -4039, -4037, -4035, -4033, -4030, -4028, -4026, -4023, -4021, -4019,
 -4016, -4014, -4011, -4009, -4006, -4004, -4001, -3998, -3996, -3993, -3990, -3987, -3984, -3981, -3978, -3975,
 -3972, -3969, -3966, -3963, -3960, -3957, -3953, -3950, -3947, -3943, -3940, -3936, -3933, -3929, -3926, -3922,
 -3919, -3915, -3911, -3908, -3904, -3900, -3896, -3892, -3888, -3884, -3880, -3876, -3872, -3868, -3864, -3860,
 -3856, -3851, -3847, -3843, -3838, -3834, -3830, -3825, -3821, -3816, -3811, -3807, -3802, -3798, -3793, -3788,
 -3783, -3778, -3774, -3769, -3764, -3759, -3754, -3749, -3744, -3739, -3733, -3728, -3723, -3718, -3713, -3707,
 -3702, -3696, -3691, -3686, -3680, -3675, -3669, -3663, -3658, -3652, -3646, -3641, -3635, -3629, -3623, -3617,
 -3611, -3606, -3600, -3594, -3588, -3581, -3575, -3569, -3563, -3557, -3551, -3544, -3538, -3532, -3525, -3519,
 -3512, -3506, -3499, -3493, -3486, -3480, -3473, -3466, -3460, -3453, -3446, -3439, -3433, -3426, -3419, -3412,
 -3405, -3398, -3391, -3384, -3377, -3370, -3362, -3355, -3348, -3341, -3333, -3326, -3319, -3311, -3304, -3297,
 -3289, -3282, -3274, -3267, -3259, -3251, -3244, -3236, -3228, -3221, -3213, -3205, -3197, -3189, -3181, -3173,
 -3165, -3157, -3149, -3141, -3133, -3125, -3117, -3109, -3101, -3093, -3084, -3076, -3068, -3059, -3051, -3043,
 -3034, -3026, -3017, -3009, -3000, -2992, -2983, -2974, -2966, -2957, -2948, -2940, -2931, -2922, -2913, -2904,
 -2896, -2887, -2878, -2869, -2860, -2851, -2842, -2833, -2824, -2815, -2805, -2796, -2787, -2778, -2769, -2759,
 -2750, -2741, -2731, -2722, -2713, -2703, -2694, -2684, -2675, -2665, -2656, -2646, -2636, -2627, -2617, -2608,
 -2598, -2588, -2578, -2569, -2559, -2549, -2539, -2529, -2519, -2509, -2500, -2490, -2480, -2470, -2460, -2449,
 -2439, -2429, -2419, -2409, -2399, -2389, -2378, -2368, -2358, -2348, -2337, -2327, -2317, -2306, -2296, -2285,
 -2275, -2265, -2254, -2244, -2233, -2223, -2212, -2201, -2191, -2180, -2170, -2159, -2148, -2137, -2127, -2116,
 -2105, -2094, -2084, -2073, -2062, -2051, -2040, -2029, -2018, -2007, -1997, -1986, -1975, -1964, -1952, -1941,
 -1930, -1919, -1908, -1897, -1886, -1875, -1864, -1852, -1841, -1830, -1819, -1807, -1796, -1785, -1774, -1762,
 -1751, -1739, -1728, -1717, -1705, -1694, -1682, -1671, -1659, -1648, -1636, -1625, -1613, -1602, -1590, -1579,
 -1567, -1555, -1544, -1532, -1521, -1509, -1497, -1485, -1474, -1462, -1450, -1439, -1427, -1415, -1403, -1391,
 -1380, -1368, -1356, -1344, -1332, -1320, -1308, -1296, -1285, -1273, -1261, -1249, -1237, -1225, -1213, -1201,
 -1189, -1177, -1165, -1153, -1141, -1128, -1116, -1104, -1092, -1080, -1068, -1056, -1044, -1032, -1019, -1007,
  -995,  -983,  -971,  -958,  -946,  -934,  -922,  -909,  -897,  -885,  -873,  -860,  -848,  -836,  -824,  -811,
  -799,  -787,  -774,  -762,  -750,  -737,  -725,  -712,  -700,  -688,  -675,  -663,  -651,  -638,  -626,  -613,
  -601,  -588,  -576,  -564,  -551,  -539,  -526,  -514,  -501,  -489,  -476,  -464,  -451,  -439,  -426,  -414,
  -401,  -389,  -376,  -364,  -351,  -339,  -326,  -314,  -301,  -289,  -276,  -264,  -251,  -239,  -226,  -213,
  -201,  -188,  -176,  -163,  -151,  -138,  -126,  -113,  -100,   -88,   -75,   -63,   -50,   -38,   -25,   -13
};
/*
const uint32_t  Hamming[FFT_SIZE] = {

     327,     328,     329,     332,     336,     341,     348,     355,     364,     373,     384,     396,     409,     423,     438,     454,
     472,     490,     509,     530,     551,     574,     597,     622,     647,     673,     701,     729,     758,     788,     819,     851,
     883,     916,     951,     985,    1021,    1057,    1094,    1132,    1171,    1210,    1249,    1289,    1330,    1371,    1413,    1456,
    1498,    1542,    1585,    1629,    1673,    1718,    1763,    1808,    1854,    1899,    1945,    1991,    2037,    2084,    2130,    2177,
    2223,    2269,    2316,    2362,    2408,    2454,    2500,    2546,    2592,    2637,    2682,    2727,    2771,    2816,    2859,    2903,
    2946,    2988,    3030,    3072,    3113,    3153,    3193,    3233,    3271,    3309,    3347,    3384,    3419,    3455,    3489,    3523,
    3556,    3588,    3619,    3650,    3679,    3708,    3736,    3762,    3788,    3813,    3837,    3860,    3882,    3903,    3923,    3942,
    3960,    3977,    3992,    4007,    4020,    4033,    4044,    4054,    4063,    4071,    4078,    4084,    4088,    4092,    4094,    4095,
    4095,    4094,    4092,    4088,    4084,    4078,    4071,    4063,    4054,    4044,    4033,    4020,    4007,    3992,    3977,    3960,
    3942,    3923,    3903,    3882,    3860,    3837,    3813,    3788,    3762,    3736,    3708,    3679,    3650,    3619,    3588,    3556,
    3523,    3489,    3455,    3419,    3384,    3347,    3309,    3271,    3233,    3193,    3153,    3113,    3072,    3030,    2988,    2946,
    2903,    2859,    2816,    2771,    2727,    2682,    2637,    2592,    2546,    2500,    2454,    2408,    2362,    2316,    2269,    2223,
    2177,    2130,    2084,    2037,    1991,    1945,    1899,    1854,    1808,    1763,    1718,    1673,    1629,    1585,    1542,    1498,
    1456,    1413,    1371,    1330,    1289,    1249,    1210,    1171,    1132,    1094,    1057,    1021,     985,     951,     916,     883,
     851,     819,     788,     758,     729,     701,     673,     647,     622,     597,     574,     551,     530,     509,     490,     472,
     454,     438,     423,     409,     396,     384,     373,     364,     355,     348,     341,     336,     332,     329,     328,     327
};
*/

const uint16_t  Hamming[NWAVE] PROGMEM = {

  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +329,  +329,  +329,  +329,  +330,
  +330,  +330,  +330,  +331,  +331,  +332,  +332,  +332,  +333,  +333,  +334,  +334,  +335,  +335,  +336,  +336,
  +337,  +337,  +338,  +338,  +339,  +340,  +340,  +341,  +342,  +342,  +343,  +344,  +345,  +346,  +346,  +347,
  +348,  +349,  +350,  +351,  +352,  +352,  +353,  +354,  +355,  +356,  +357,  +358,  +359,  +361,  +362,  +363,
  +364,  +365,  +366,  +367,  +368,  +370,  +371,  +372,  +373,  +375,  +376,  +377,  +379,  +380,  +381,  +383,
  +384,  +386,  +387,  +388,  +390,  +391,  +393,  +394,  +396,  +397,  +399,  +401,  +402,  +404,  +405,  +407,
  +409,  +410,  +412,  +414,  +416,  +417,  +419,  +421,  +423,  +425,  +426,  +428,  +430,  +432,  +434,  +436,
  +438,  +440,  +442,  +444,  +446,  +448,  +450,  +452,  +454,  +456,  +458,  +460,  +462,  +465,  +467,  +469,
  +471,  +473,  +476,  +478,  +480,  +482,  +485,  +487,  +489,  +492,  +494,  +496,  +499,  +501,  +504,  +506,
  +509,  +511,  +514,  +516,  +519,  +521,  +524,  +526,  +529,  +532,  +534,  +537,  +539,  +542,  +545,  +548,
  +550,  +553,  +556,  +558,  +561,  +564,  +567,  +570,  +573,  +575,  +578,  +581,  +584,  +587,  +590,  +593,
  +596,  +599,  +602,  +605,  +608,  +611,  +614,  +617,  +620,  +623,  +626,  +629,  +633,  +636,  +639,  +642,
  +645,  +649,  +652,  +655,  +658,  +662,  +665,  +668,  +672,  +675,  +678,  +682,  +685,  +688,  +692,  +695,
  +699,  +702,  +706,  +709,  +713,  +716,  +720,  +723,  +727,  +730,  +734,  +737,  +741,  +745,  +748,  +752,
  +756,  +759,  +763,  +767,  +770,  +774,  +778,  +782,  +785,  +789,  +793,  +797,  +801,  +804,  +808,  +812,
  +816,  +820,  +824,  +828,  +832,  +836,  +840,  +844,  +848,  +852,  +856,  +860,  +864,  +868,  +872,  +876,
  +880,  +884,  +888,  +892,  +896,  +900,  +905,  +909,  +913,  +917,  +921,  +926,  +930,  +934,  +938,  +943,
  +947,  +951,  +955,  +960,  +964,  +968,  +973,  +977,  +982,  +986,  +990,  +995,  +999, +1004, +1008, +1012,
 +1017, +1021, +1026, +1030, +1035, +1039, +1044, +1048, +1053, +1058, +1062, +1067, +1071, +1076, +1081, +1085,
 +1090, +1095, +1099, +1104, +1109, +1113, +1118, +1123, +1127, +1132, +1137, +1142, +1146, +1151, +1156, +1161,
 +1166, +1170, +1175, +1180, +1185, +1190, +1195, +1199, +1204, +1209, +1214, +1219, +1224, +1229, +1234, +1239,
 +1244, +1249, +1254, +1259, +1264, +1269, +1274, +1279, +1284, +1289, +1294, +1299, +1304, +1309, +1314, +1319,
 +1324, +1329, +1334, +1340, +1345, +1350, +1355, +1360, +1365, +1370, +1376, +1381, +1386, +1391, +1396, +1402,
 +1407, +1412, +1417, +1423, +1428, +1433, +1438, +1444, +1449, +1454, +1460, +1465, +1470, +1475, +1481, +1486,
 +1491, +1497, +1502, +1508, +1513, +1518, +1524, +1529, +1534, +1540, +1545, +1551, +1556, +1561, +1567, +1572,
 +1578, +1583, +1589, +1594, +1600, +1605, +1611, +1616, +1622, +1627, +1633, +1638, +1644, +1649, +1655, +1660,
 +1666, +1671, +1677, +1682, +1688, +1693, +1699, +1704, +1710, +1716, +1721, +1727, +1732, +1738, +1744, +1749,
 +1755, +1760, +1766, +1772, +1777, +1783, +1789, +1794, +1800, +1805, +1811, +1817, +1822, +1828, +1834, +1839,
 +1845, +1851, +1856, +1862, +1868, +1873, +1879, +1885, +1891, +1896, +1902, +1908, +1913, +1919, +1925, +1930,
 +1936, +1942, +1948, +1953, +1959, +1965, +1971, +1976, +1982, +1988, +1994, +1999, +2005, +2011, +2017, +2022,
 +2028, +2034, +2040, +2045, +2051, +2057, +2063, +2068, +2074, +2080, +2086, +2091, +2097, +2103, +2109, +2114,
 +2120, +2126, +2132, +2138, +2143, +2149, +2155, +2161, +2166, +2172, +2178, +2184, +2190, +2195, +2201, +2207,
 +2213, +2219, +2224, +2230, +2236, +2242, +2247, +2253, +2259, +2265, +2271, +2276, +2282, +2288, +2294, +2299,
 +2305, +2311, +2317, +2323, +2328, +2334, +2340, +2346, +2351, +2357, +2363, +2369, +2374, +2380, +2386, +2392,
 +2397, +2403, +2409, +2415, +2420, +2426, +2432, +2438, +2443, +2449, +2455, +2461, +2466, +2472, +2478, +2484,
 +2489, +2495, +2501, +2506, +2512, +2518, +2524, +2529, +2535, +2541, +2546, +2552, +2558, +2563, +2569, +2575,
 +2580, +2586, +2592, +2597, +2603, +2609, +2614, +2620, +2626, +2631, +2637, +2643, +2648, +2654, +2659, +2665,
 +2671, +2676, +2682, +2687, +2693, +2699, +2704, +2710, +2715, +2721, +2726, +2732, +2738, +2743, +2749, +2754,
 +2760, +2765, +2771, +2776, +2782, +2787, +2793, +2798, +2804, +2809, +2815, +2820, +2826, +2831, +2837, +2842,
 +2848, +2853, +2858, +2864, +2869, +2875, +2880, +2886, +2891, +2896, +2902, +2907, +2912, +2918, +2923, +2928,
 +2934, +2939, +2944, +2950, +2955, +2960, +2966, +2971, +2976, +2982, +2987, +2992, +2997, +3003, +3008, +3013,
 +3018, +3024, +3029, +3034, +3039, +3044, +3050, +3055, +3060, +3065, +3070, +3075, +3080, +3086, +3091, +3096,
 +3101, +3106, +3111, +3116, +3121, +3126, +3131, +3136, +3141, +3146, +3151, +3156, +3161, +3166, +3171, +3176,
 +3181, +3186, +3191, +3196, +3201, +3206, +3211, +3216, +3221, +3226, +3230, +3235, +3240, +3245, +3250, +3255,
 +3259, +3264, +3269, +3274, +3279, +3283, +3288, +3293, +3298, +3302, +3307, +3312, +3316, +3321, +3326, +3330,
 +3335, +3340, +3344, +3349, +3354, +3358, +3363, +3367, +3372, +3376, +3381, +3385, +3390, +3394, +3399, +3403,
 +3408, +3412, +3417, +3421, +3426, +3430, +3435, +3439, +3443, +3448, +3452, +3456, +3461, +3465, +3469, +3474,
 +3478, +3482, +3486, +3491, +3495, +3499, +3503, +3508, +3512, +3516, +3520, +3524, +3528, +3533, +3537, +3541,
 +3545, +3549, +3553, +3557, +3561, +3565, +3569, +3573, +3577, +3581, +3585, +3589, +3593, +3597, +3601, +3605,
 +3609, +3612, +3616, +3620, +3624, +3628, +3632, +3635, +3639, +3643, +3647, +3650, +3654, +3658, +3661, +3665,
 +3669, +3673, +3676, +3680, +3683, +3687, +3691, +3694, +3698, +3701, +3705, +3708, +3712, +3715, +3719, +3722,
 +3726, +3729, +3733, +3736, +3739, +3743, +3746, +3749, +3753, +3756, +3759, +3763, +3766, +3769, +3772, +3776,
 +3779, +3782, +3785, +3788, +3792, +3795, +3798, +3801, +3804, +3807, +3810, +3813, +3816, +3819, +3822, +3825,
 +3828, +3831, +3834, +3837, +3840, +3843, +3846, +3849, +3851, +3854, +3857, +3860, +3863, +3865, +3868, +3871,
 +3874, +3876, +3879, +3882, +3884, +3887, +3890, +3892, +3895, +3898, +3900, +3903, +3905, +3908, +3910, +3913,
 +3915, +3918, +3920, +3923, +3925, +3927, +3930, +3932, +3934, +3937, +3939, +3941, +3944, +3946, +3948, +3950,
 +3953, +3955, +3957, +3959, +3961, +3963, +3966, +3968, +3970, +3972, +3974, +3976, +3978, +3980, +3982, +3984,
 +3986, +3988, +3990, +3991, +3993, +3995, +3997, +3999, +4001, +4003, +4004, +4006, +4008, +4010, +4011, +4013,
 +4015, +4016, +4018, +4020, +4021, +4023, +4024, +4026, +4027, +4029, +4031, +4032, +4033, +4035, +4036, +4038,
 +4039, +4041, +4042, +4043, +4045, +4046, +4047, +4049, +4050, +4051, +4052, +4054, +4055, +4056, +4057, +4058,
 +4059, +4060, +4062, +4063, +4064, +4065, +4066, +4067, +4068, +4069, +4070, +4071, +4072, +4072, +4073, +4074,
 +4075, +4076, +4077, +4077, +4078, +4079, +4080, +4080, +4081, +4082, +4083, +4083, +4084, +4084, +4085, +4086,
 +4086, +4087, +4087, +4088, +4088, +4089, +4089, +4090, +4090, +4091, +4091, +4091, +4092, +4092, +4092, +4093,
 +4093, +4093, +4093, +4094, +4094, +4094, +4094, +4094, +4095, +4095, +4095, +4095, +4095, +4095, +4095, +4095,
 +4095, +4095, +4095, +4095, +4095, +4095, +4095, +4095, +4094, +4094, +4094, +4094, +4094, +4093, +4093, +4093,
 +4093, +4092, +4092, +4092, +4091, +4091, +4091, +4090, +4090, +4089, +4089, +4088, +4088, +4087, +4087, +4086,
 +4086, +4085, +4084, +4084, +4083, +4083, +4082, +4081, +4080, +4080, +4079, +4078, +4077, +4077, +4076, +4075,
 +4074, +4073, +4072, +4072, +4071, +4070, +4069, +4068, +4067, +4066, +4065, +4064, +4063, +4062, +4060, +4059,
 +4058, +4057, +4056, +4055, +4054, +4052, +4051, +4050, +4049, +4047, +4046, +4045, +4043, +4042, +4041, +4039,
 +4038, +4036, +4035, +4033, +4032, +4031, +4029, +4027, +4026, +4024, +4023, +4021, +4020, +4018, +4016, +4015,
 +4013, +4011, +4010, +4008, +4006, +4004, +4003, +4001, +3999, +3997, +3995, +3993, +3991, +3990, +3988, +3986,
 +3984, +3982, +3980, +3978, +3976, +3974, +3972, +3970, +3968, +3966, +3963, +3961, +3959, +3957, +3955, +3953,
 +3950, +3948, +3946, +3944, +3941, +3939, +3937, +3934, +3932, +3930, +3927, +3925, +3923, +3920, +3918, +3915,
 +3913, +3910, +3908, +3905, +3903, +3900, +3898, +3895, +3892, +3890, +3887, +3884, +3882, +3879, +3876, +3874,
 +3871, +3868, +3865, +3863, +3860, +3857, +3854, +3851, +3849, +3846, +3843, +3840, +3837, +3834, +3831, +3828,
 +3825, +3822, +3819, +3816, +3813, +3810, +3807, +3804, +3801, +3798, +3795, +3792, +3788, +3785, +3782, +3779,
 +3776, +3772, +3769, +3766, +3763, +3759, +3756, +3753, +3749, +3746, +3743, +3739, +3736, +3733, +3729, +3726,
 +3722, +3719, +3715, +3712, +3708, +3705, +3701, +3698, +3694, +3691, +3687, +3683, +3680, +3676, +3673, +3669,
 +3665, +3661, +3658, +3654, +3650, +3647, +3643, +3639, +3635, +3632, +3628, +3624, +3620, +3616, +3612, +3609,
 +3605, +3601, +3597, +3593, +3589, +3585, +3581, +3577, +3573, +3569, +3565, +3561, +3557, +3553, +3549, +3545,
 +3541, +3537, +3533, +3528, +3524, +3520, +3516, +3512, +3508, +3503, +3499, +3495, +3491, +3486, +3482, +3478,
 +3474, +3469, +3465, +3461, +3456, +3452, +3448, +3443, +3439, +3435, +3430, +3426, +3421, +3417, +3412, +3408,
 +3403, +3399, +3394, +3390, +3385, +3381, +3376, +3372, +3367, +3363, +3358, +3354, +3349, +3344, +3340, +3335,
 +3330, +3326, +3321, +3316, +3312, +3307, +3302, +3298, +3293, +3288, +3283, +3279, +3274, +3269, +3264, +3259,
 +3255, +3250, +3245, +3240, +3235, +3230, +3226, +3221, +3216, +3211, +3206, +3201, +3196, +3191, +3186, +3181,
 +3176, +3171, +3166, +3161, +3156, +3151, +3146, +3141, +3136, +3131, +3126, +3121, +3116, +3111, +3106, +3101,
 +3096, +3091, +3086, +3080, +3075, +3070, +3065, +3060, +3055, +3050, +3044, +3039, +3034, +3029, +3024, +3018,
 +3013, +3008, +3003, +2997, +2992, +2987, +2982, +2976, +2971, +2966, +2960, +2955, +2950, +2944, +2939, +2934,
 +2928, +2923, +2918, +2912, +2907, +2902, +2896, +2891, +2886, +2880, +2875, +2869, +2864, +2858, +2853, +2848,
 +2842, +2837, +2831, +2826, +2820, +2815, +2809, +2804, +2798, +2793, +2787, +2782, +2776, +2771, +2765, +2760,
 +2754, +2749, +2743, +2738, +2732, +2726, +2721, +2715, +2710, +2704, +2699, +2693, +2687, +2682, +2676, +2671,
 +2665, +2659, +2654, +2648, +2643, +2637, +2631, +2626, +2620, +2614, +2609, +2603, +2597, +2592, +2586, +2580,
 +2575, +2569, +2563, +2558, +2552, +2546, +2541, +2535, +2529, +2524, +2518, +2512, +2506, +2501, +2495, +2489,
 +2484, +2478, +2472, +2466, +2461, +2455, +2449, +2443, +2438, +2432, +2426, +2420, +2415, +2409, +2403, +2397,
 +2392, +2386, +2380, +2374, +2369, +2363, +2357, +2351, +2346, +2340, +2334, +2328, +2323, +2317, +2311, +2305,
 +2299, +2294, +2288, +2282, +2276, +2271, +2265, +2259, +2253, +2247, +2242, +2236, +2230, +2224, +2219, +2213,
 +2207, +2201, +2195, +2190, +2184, +2178, +2172, +2166, +2161, +2155, +2149, +2143, +2138, +2132, +2126, +2120,
 +2114, +2109, +2103, +2097, +2091, +2086, +2080, +2074, +2068, +2063, +2057, +2051, +2045, +2040, +2034, +2028,
 +2022, +2017, +2011, +2005, +1999, +1994, +1988, +1982, +1976, +1971, +1965, +1959, +1953, +1948, +1942, +1936,
 +1930, +1925, +1919, +1913, +1908, +1902, +1896, +1891, +1885, +1879, +1873, +1868, +1862, +1856, +1851, +1845,
 +1839, +1834, +1828, +1822, +1817, +1811, +1805, +1800, +1794, +1789, +1783, +1777, +1772, +1766, +1760, +1755,
 +1749, +1744, +1738, +1732, +1727, +1721, +1716, +1710, +1704, +1699, +1693, +1688, +1682, +1677, +1671, +1666,
 +1660, +1655, +1649, +1644, +1638, +1633, +1627, +1622, +1616, +1611, +1605, +1600, +1594, +1589, +1583, +1578,
 +1572, +1567, +1561, +1556, +1551, +1545, +1540, +1534, +1529, +1524, +1518, +1513, +1508, +1502, +1497, +1491,
 +1486, +1481, +1475, +1470, +1465, +1460, +1454, +1449, +1444, +1438, +1433, +1428, +1423, +1417, +1412, +1407,
 +1402, +1396, +1391, +1386, +1381, +1376, +1370, +1365, +1360, +1355, +1350, +1345, +1340, +1334, +1329, +1324,
 +1319, +1314, +1309, +1304, +1299, +1294, +1289, +1284, +1279, +1274, +1269, +1264, +1259, +1254, +1249, +1244,
 +1239, +1234, +1229, +1224, +1219, +1214, +1209, +1204, +1199, +1195, +1190, +1185, +1180, +1175, +1170, +1166,
 +1161, +1156, +1151, +1146, +1142, +1137, +1132, +1127, +1123, +1118, +1113, +1109, +1104, +1099, +1095, +1090,
 +1085, +1081, +1076, +1071, +1067, +1062, +1058, +1053, +1048, +1044, +1039, +1035, +1030, +1026, +1021, +1017,
 +1012, +1008, +1004,  +999,  +995,  +990,  +986,  +982,  +977,  +973,  +968,  +964,  +960,  +955,  +951,  +947,
  +943,  +938,  +934,  +930,  +926,  +921,  +917,  +913,  +909,  +905,  +900,  +896,  +892,  +888,  +884,  +880,
  +876,  +872,  +868,  +864,  +860,  +856,  +852,  +848,  +844,  +840,  +836,  +832,  +828,  +824,  +820,  +816,
  +812,  +808,  +804,  +801,  +797,  +793,  +789,  +785,  +782,  +778,  +774,  +770,  +767,  +763,  +759,  +756,
  +752,  +748,  +745,  +741,  +737,  +734,  +730,  +727,  +723,  +720,  +716,  +713,  +709,  +706,  +702,  +699,
  +695,  +692,  +688,  +685,  +682,  +678,  +675,  +672,  +668,  +665,  +662,  +658,  +655,  +652,  +649,  +645,
  +642,  +639,  +636,  +633,  +629,  +626,  +623,  +620,  +617,  +614,  +611,  +608,  +605,  +602,  +599,  +596,
  +593,  +590,  +587,  +584,  +581,  +578,  +575,  +573,  +570,  +567,  +564,  +561,  +558,  +556,  +553,  +550,
  +548,  +545,  +542,  +539,  +537,  +534,  +532,  +529,  +526,  +524,  +521,  +519,  +516,  +514,  +511,  +509,
  +506,  +504,  +501,  +499,  +496,  +494,  +492,  +489,  +487,  +485,  +482,  +480,  +478,  +476,  +473,  +471,
  +469,  +467,  +465,  +462,  +460,  +458,  +456,  +454,  +452,  +450,  +448,  +446,  +444,  +442,  +440,  +438,
  +436,  +434,  +432,  +430,  +428,  +426,  +425,  +423,  +421,  +419,  +417,  +416,  +414,  +412,  +410,  +409,
  +407,  +405,  +404,  +402,  +401,  +399,  +397,  +396,  +394,  +393,  +391,  +390,  +388,  +387,  +386,  +384,
  +383,  +381,  +380,  +379,  +377,  +376,  +375,  +373,  +372,  +371,  +370,  +368,  +367,  +366,  +365,  +364,
  +363,  +362,  +361,  +359,  +358,  +357,  +356,  +355,  +354,  +353,  +352,  +352,  +351,  +350,  +349,  +348,
  +347,  +346,  +346,  +345,  +344,  +343,  +342,  +342,  +341,  +340,  +340,  +339,  +338,  +338,  +337,  +337,
  +336,  +336,  +335,  +335,  +334,  +334,  +333,  +333,  +332,  +332,  +332,  +331,  +331,  +330,  +330,  +330,
  +330,  +329,  +329,  +329,  +329,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328,  +328
};

class Radix4 {
public:
	Radix4();
	void rev_bin( int *, int);

	inline void mult_shf_I( int c, int s, int x, int y, int &u, int &v)  __attribute__((always_inline));
	inline void sum_dif_I(int a, int b, int &s, int &d)  __attribute__((always_inline));
	inline int  mult_shft( int a, int b)  __attribute__((always_inline));

	void fft8_dit_core_p1(int *, int *);
	void fft_radix4_I( int *, int *, int);

	void gain_Reset( int *, int);
	void get_Magnit( int *,  int *, int *);
	void get_Magnit2( int *,  int *, int *);

private:
};

#endif  /* _RADIX4_H_ */

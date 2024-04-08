/* Compute Square Root using CORDIC
 * 
 * Author: Daniele Giardino
 * Date: 2024.03.28
 * 
 */

#include "lib_cordicSqrt.h"

// Cordic gain for the square root
float cordicSqrtGain(uint8_t N_iter) {
  float An = 1;
  uint8_t i = 1;
  uint8_t i_rep = 3*i+1;
  while (i<=N_iter) {
    An = An * sqrt(1.0-pow(2.0, -2*i));
    
    if (i==i_rep)
      i_rep = 3*i+1;
    else
      i += 1;
  }
  float cordicGain = 1.0/An;
  return cordicGain;
}


// Count the number of zeros
uint8_t countZeros(uint64_t s, uint8_t Wl) {
  uint8_t n = 0;  // number of zeros
  uint64_t s_max = (uint64_t) (0x1) << (Wl-1); // Max value
  for (uint8_t j=Wl; j>=0; j--) {
    
    // Get the MSB
    uint64_t MSB = s<<(Wl-j) & s_max;
    if (MSB == s_max)
      break;
    else
      n += 1;
    
  }
  
  /* Note
    * Because 'n' must be even, if the number of leading zero MSBs is odd,
    * one additional bit shift is made to make $$ n $$ even.
    */
  n = ((n > 1) & ((n % 2) == 1)) ? n -= 1 : n;
  n = (n==1) ? 2 : n;

  return n;
}


/* Cordic algorithm
 * This function implements the CORDIC algorithm to calculate the square root of a number.
 */
uint64_t cordicAlgorithm(uint64_t s, uint8_t Wl, uint8_t N_iter, float cordicGain) {

  //////// Pre-normalization ////////
  // Count the zeros
  uint8_t n = countZeros(s, Wl);

  // The resulting value after these shifts is the value u in [0.5, 2).
  uint64_t u = s << n;

  //////// CORDIC-Based Square Root Computation ////////
  // Initialization
  // x = u + 0.25
  // y = u - 0.25
  int64_t k_025 = 0.25 * pow(2, Wl);
  int64_t x = (int64_t) u + k_025;
  int64_t y = (int64_t) u - k_025;
  //printf("\nu=%ld; x=%ld; y=%ld;\n", int64_t(uint64_t(u)), x, y);
  
  // CORDIC Square Root Kernel
  // Note that for hyperbolic CORDIC-based algorithms, such as square root, 
  // certain iterations (i=4,13,40,121,…,k,3k+1,…) are repeated to achieve 
  // result convergence
  uint8_t i = 1;
  uint8_t i_rep = 3*i+1;
  int64_t x_tmp, y_tmp = 0;
  while (i<=N_iter) {
    x_tmp = x >> i;
    y_tmp = y >> i;
    x = (y<0) ? (x + y_tmp) : (x - y_tmp);
    y = (y<0) ? (y + x_tmp) : (y - x_tmp);
    //printf("i=%02u --> x=%04lX; y=%lX;\n", i, x, y);
    
    if (i==i_rep)
      i_rep = 3*i+1;
    else
      i += 1;
  
  }
  
  // Shift of 'n/2' to compensate the initial shift
  x = x >> (n/2);
  //printf("n=%02u; x=%04lX;\n", n, x);

  /* Gain compensation of the Cordic Algorithm. 
    * The value 'x' is multiplied with the 'cordicGain_int'.
    * Nextly, the 'Wl/2'-bit-shift is applied.
    */
  uint64_t cordicGain_int = ceil(cordicGain * pow(2, Wl/2));  // Scaling to output dynamic
  uint64_t x_cor = x * cordicGain_int;

  // Scaling is performed in the main.
  //x_cor = x_cor >> (Wl);

  return x_cor;
}


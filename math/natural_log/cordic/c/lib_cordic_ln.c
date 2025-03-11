/* Compute natural logarithm using CORDIC algorithm
 * 
 * Author: Daniele Giardino
 * Date: 2025.02.26
 * 
 */

#include "lib_cordic_ln.h"


// Initialize the lookup table atanh(2^-i)
void init_atanh_lut(int64_t *atanh_lut, uint8_t Wl, uint8_t N_iter) {

  double x;
  for (int i = 1; i <= N_iter; i++)
  {
    // atanh value - double representation
    // x is always less than 1 because the largest value of x is 0.5
    x = atanh(pow(2, -i));

    // FXP conversion
    double x_round = round(pow(2, Wl-1) * x);

    // Assign to the table
    atanh_lut[i-1] = (int64_t) x_round;
    // printf("atanh[%02i]=%li | x=%e | x_round=%e\n", i-1, atanh_lut[i-1], x, x_round);
  }
}

// Count the number of zeros
uint8_t countZeros(uint64_t s, uint8_t Wl) {
  uint8_t n = 0;  // number of zeros
  uint64_t s_max = 0x1; // Max value
  s_max = s_max << (Wl-1); // Max value
  for (uint8_t j=0; j<Wl; j++) {

    // Get the MSB
    uint64_t MSB = s<<(j) & s_max;
    if (MSB == s_max) {
      n = j;
      break;
    }
  }

  return n;
}


/* CORDIC algorithm
 * This function implements the CORDIC algorithm.
 */
int64_t cordicAlgorithm(uint64_t s, uint8_t Wl, uint8_t N_iter, int64_t *atanh_lut, int64_t ln_2) {

  //////// Pre-normalization ////////
  // Count the zeros
  uint8_t n = countZeros(s, Wl);
  
  // The resulting value after these shifts is the value u in [1.0, 2).
  uint64_t u = s << n;

  //////// CORDIC Computation ////////
  // Initialization
  // x = u + 1
  // y = u - 1
  int64_t k_1 = 1;
  k_1 = k_1 << (Wl - 1);
  int64_t x = (int64_t) u + k_1;
  int64_t y = (int64_t) u - k_1;
  int64_t z = 0;
  // printf("s = %li | n=%02u | u=%016lX; x=%016lX; y=%016lX; | k_1=%016lX\n", 
  //   s, n, u, x, y, k_1);
  // printf("s = %li | n=%02u | u=%f; x=%f; y=%f; | k_1=%f\n", 
  //   s, n, u/pow(2,Wl-1), x/pow(2,Wl-1), y/pow(2,Wl-1), k_1/pow(2,Wl-1));
  
  // CORDIC Kernel
  // Note that for hyperbolic CORDIC-based algorithms, 
  // certain iterations (i=4,13,40,121,…,k,3k+1,…) are repeated to achieve 
  // result convergence
  uint8_t i = 1;
  int8_t d = 0;
  uint8_t i_rep = 3 * i + 1;
  int64_t x_tmp, y_tmp = 0;
  while (i<=N_iter) {
    x_tmp = x >> i;
    y_tmp = y >> i;

    z = (y<0) ? (z - atanh_lut[i-1]) : (z + atanh_lut[i-1]);
    x = (y<0) ? (x + y_tmp) : (x - y_tmp);
    y = (y<0) ? (y + x_tmp) : (y - x_tmp);

    // printf("i=%i | s=%li | x=%e | y=%e | z=%e\n",
    //        i, s, x/powf(2,Wl-1), y/powf(2,Wl-1), z/powf(2,Wl-1));

    if (i==i_rep)
      i_rep = 3 * i + 1;
    else
      i += 1;
  }

  // Post processing
  int64_t res = z << 1;
  printf("z = %016lX | res = %016lX | ln(2)=%016lX\n", z, res, ln_2);
  printf("z = %f | res = %f | ln(2)=%f\n",z/pow(2,Wl-1), res/pow(2,Wl-1), ln_2/pow(2,Wl-1));
  for (size_t i = 0; i < n; i++)
  {
    res -= ln_2;
  }

  return res;
}


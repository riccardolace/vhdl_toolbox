/* Compute Square Root using CORDIC
 *
 * Author: Daniele Giardino
 * Date: 2025.02.26
 *
 */

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>
#include <math.h>

#ifndef LIB_CORDIC_LN
#define LIB_CORDIC_LN


// Initialize the lookup table atanh(2^-i)
void init_atanh_lut(int64_t *atanh_lut, uint8_t Wl, uint8_t N_iter);

// Count the number of zeros
uint8_t countZeros(uint64_t s, uint8_t Wl);

/* CORDIC algorithm
 * This function implements the CORDIC algorithm to calculate the square root of a number.
 *   s: input number
 *   Wl: number of bit of 's'
 *   N_iter: number of iterations
 *   atanh_lut: table of the atanh values
 *   ln_2: natural logarithm of 2 represented with int64_t type
 */
int64_t cordicAlgorithm(uint64_t s, uint8_t Wl, uint8_t N_iter, int64_t *atanh_lut, int64_t ln_2);

#endif // LIB_CORDIC_LN

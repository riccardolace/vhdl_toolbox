/* Compute Square Root using CORDIC
 * 
 * Author: Daniele Giardino
 * Date: 2024.03.28
 * 
 */

#include <stdbool.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>
#include <math.h>

#ifndef LIB_CORDIC_SQRT
#define LIB_CORDIC_SQRT

// Cordic gain for the square root
float cordicSqrtGain(uint8_t N_iter);

// Count the number of zeros
uint8_t countZeros(uint64_t s, uint8_t Wl);

/* Cordic algorithm
 * This function implements the CORDIC algorithm to calculate the square root of a number.
 *   s: input number
 *   Wl: number of bit of 's'
 *   N_iter: number of iterations
 *   cordicGain: Cordic gain
 */
uint64_t cordicAlgorithm(uint64_t s, uint8_t Wl, uint8_t N_iter, float cordicGain);


#endif // LIB_CORDIC_SQRT

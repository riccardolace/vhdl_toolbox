/* Compute Square Root using CORDIC
 *
 * Author: Daniele Giardino
 * Date: 2025.02.26
 *
 * Description
 *
 *   COordinate Rotation DIgital Computer (CORDIC) implementation.
 *
 *   Note that for hyperbolic CORDIC-based algorithms,
 *   certain iterations (i = 4, 13, 40, 121, ..., k, 3k+1, ...) are repeated to achieve result convergence.
 *
 */

#include "lib_cordic_ln.h"

int main(int argc, char **argv)
{

  // Flags
  bool flag_err_flp = true;

  // FXP representation
  uint8_t Wl = 30;    // Word length
  uint8_t Fl = Wl-1;  // Fractional part

  // CORDIC iterations
  uint8_t N_iter = Wl;

  /* Create the test numbers
   * Note that:
   * - The algorithm inputs are always greater than 0
   * - Numbers are represented with Wl bits
   * - The fixed point notation is UQ1.XX where XX is the fractional part defined as 'Wl-1'
   * - Considering UQ1.XX notation, the test numbers are defined in the range [0,2-2^(-31)]
   * - Also the test numbers are defined as integer with type uint64_t, we consider the correct representation in the CORDIC algorithm
   */ 
  uint64_t s_start; // 1st value to test
  uint64_t s_end;   // last value to test

  if (argc==2)
  {
    float x = atof(argv[1]);
    s_start = (uint64_t) roundf(x * pow(2,Fl));
    s_end   = s_start;
  }
  else
  {
    s_start = 1;
    s_end = (uint64_t)(pow(2, Wl)-1); // Test all values
    // s_end = 1e5;                   // Define a max value to test
  }

  // Word length must be even
  if (s_start < 1)
  {
    printf("s_start must be greater than 0!\n");
    return -1;
  }

  printf("FIRST NUMBER - INTEGER = %lu | FLOAT = %e\n",    s_start, s_start/pow(2,Wl-1));
  printf("LAST  NUMBER - INTEGER = %lu | FLOAT = %e\n",  s_end, s_end/pow(2,Wl-1));
  printf("\nWord Length - Wl=%i\nFractional Length - Fl=%i\n\n", Wl, Fl);

  // Errors of the algorithm printed to file
  FILE *pFile;
  pFile = fopen("error_values.txt", "wb");
  uint32_t err_inc = 0;
  float max_err = 0;

  /* Time variable to estimate the execution time.
   * https://www.geeksforgeeks.org/measure-execution-time-with-high-precision-in-c-c/
   * Time function returns the time since the Epoch(jan 1 1970).
   * Returned time is in seconds.
   */
  time_t start, end;

  /* You can call it like this : start = time(NULL);
    in both the way start contain total time in seconds
    since the Epoch. */
  time(&start);

  // Print info to file
  fprintf(pFile, "First value=%li\n", s_start);
  fprintf(pFile, "Last  value=%li\n", s_end);
  fprintf(pFile, "Number of iterations=%i\n", N_iter);
  fprintf(pFile, "Wl=%02i\n", Wl);
  fprintf(pFile, "Fl=%02i\n", Wl - 1);
  fprintf(pFile, "Errors table\n");
  fprintf(pFile, "s,ln_ref,ln_cordic,err_perc\n");

#pragma omp parallel
  {
    printf("I'm process %d.\n", omp_get_thread_num());

    // Natural log 2
    int64_t ln_2 = round(log(2) * pow(2, Wl-1));

/* Causes the work done in a for loop inside a parallel region
 * to be divided among threads.
 */
#pragma omp for
    for (uint64_t s = s_start; s <= s_end; s++)
    {

      // Lookup table for atanh(2^-i)
      int64_t atanh_lut[72]; // The size is large, but it spans the range between [0, Wl]
      init_atanh_lut(atanh_lut, Wl, 72);

      // Return the square root output.
      int64_t x_cor = cordicAlgorithm(s, Wl, N_iter, atanh_lut, ln_2);

      /* The final step involves scaling the result to compensate for the multiplication with the 'cordicGain_int'.
       * The result is right-shifted by 'Wl' bits.
       */
      float x_cor_flp = (float) x_cor / pow(2,Wl-1);  // Float value
      x_cor = x_cor >> (Wl);            // uint64_t value

/* Create thread safe region.
 * Specifies that the code runs on only one thread at a time.
 */
#pragma omp critical
      {
        //////// Compare with the reference ////////
        // Float reference
        float x_ref_flp = logf( (float) s / pow(2,Wl-1));

        // Float error
        float err;
        if (flag_err_flp)
          err = (x_ref_flp - x_cor_flp) / x_ref_flp * 100;

        // Print info on the terminal
        if (flag_err_flp)
          printf("s=%12lu | x_ref_flp=%.4f | x_cor_flp=%.4f | err=%.4f%%\n",
                s, x_ref_flp, x_cor_flp, err);

        /* Print to file
         * if the absolute value of the error is greater than of 1 %,
         * the information about the considered number is printed.
         */
        if (err > 0.1 || err < -0.1)
        {
          err_inc += 1;
          max_err = (abs(err) > max_err) ? abs(err) : max_err;
          if (flag_err_flp)
            fprintf(pFile, "%03lu,%+2.8e,%+2.8e,%+2.8e%%\n", s, x_ref_flp, x_cor_flp, err);
        }

      } // #pragma omp critical end

    } // #pragram omp for end

  } // #pragma omp parallel end

  // Close the file
  fclose(pFile);

  // Print error information
  printf("Number of errors = %u\n", err_inc);
  printf("Max Error = %f\n", max_err);

  // Recording end time.
  time(&end);

  // Calculating total time taken by the program.
  double time_taken = (double)(end - start);
  printf("Time taken by program is %lf \n", time_taken);

  return 0;
}

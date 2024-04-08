/* Compute Square Root using CORDIC
* 
* Author: Daniele Giardino
* Date: 2024.03.28
* 
* Descritpion
* 
*   COordinate Rotation DIgital Computer (Cordic) implementation.
*   
*   Note that for hyperbolic CORDIC-based algorithms, such as square root, 
*   certain iterations (i = 4, 13, 40, 121, ..., k, 3k+1, ...) are repeated to achieve result convergence.
* 
*/

#include "lib_cordicSqrt.h"

int main(int argc, char **argv) {
  
  // Flags
  bool flag_err_flp = true;
  
  // FXP representation
  uint8_t Wl = 32;
  
  // Word length must be even
  if ( (Wl | 0x1) == 0x1) {
    printf("Word length must be even!");
    return -1;
  }

  // Cordic iterations
  uint8_t N_iter = Wl;
  
  // Create the input numbers
  uint64_t s_start;   // 1st value to test
  uint64_t s_end;     // last value to test
  
  s_start = 1;
  s_end = (uint64_t) (pow(2, Wl)) - 1;  // Test all values
  //s_end   = 1e7;  // Define a max value to test

  // Word length must be even
  if (s_start<1) {
    printf("s_start must be greater than 0!\n");
    return -1;
  }
  
  printf("FIRST NUMBER = %lu\n",   s_start);
  printf("LAST  NUMBER = %lu\n\n", s_end);
  
  // Errors printed to file
  FILE* pFile;
  pFile = fopen("error_values.txt","wb");
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
  
  // Cordic gain
  float cordicGain = cordicSqrtGain(N_iter);
  printf("cordicGain=%f\n\n", cordicGain);
  
  // Print info to file
  fprintf(pFile, "First value=%li\n", s_start);
  fprintf(pFile, "Last  value=%li\n", s_end);
  fprintf(pFile, "Number of iterations=%i\n", N_iter);
  fprintf(pFile, "Wl=%02i\n", Wl);
  fprintf(pFile, "Fl=%02i\n", Wl-1);
  fprintf(pFile, "cordicGain=%f\n\n", cordicGain);
  fprintf(pFile, "Errors table\n");
  fprintf(pFile, "s,sqrt_ref,sqrt_cordic,err_perc\n");
  
  #pragma omp parallel
  {
    printf("I'm process %d.\n", omp_get_thread_num());
    
    #pragma omp for
    for (uint64_t s=s_start; s<s_end; s++) {
      
      // Return the square root output.
      uint64_t x_cor = cordicAlgorithm(s, Wl, N_iter, cordicGain);
      
      /* The final step involves scaling the result to compensate for the multiplication with the 'cordicGain_int'.
       * The result is right-shifted by 'Wl' bits.
       */
      float x_cor_flp = (float) x_cor / pow(2, Wl); // Float value
      x_cor = x_cor >> (Wl);                        // uint64_t value

      //Create thread safe region.
      #pragma omp critical
      {
        //////// Compare with the reference ////////
        // Float reference
        float x_ref_flp = sqrt((float) s);
        uint64_t x_ref_int = floor(x_ref_flp);
        
        // Float error
        float err;
        if (flag_err_flp)
          err = (x_ref_flp - x_cor_flp)/x_ref_flp *100;
        else
          err = ((float) x_ref_int - (float) x_cor) / ((float) x_ref_int) * 100.0;

        // Print info on the terminal 
        // if (flag_err_flp)
        //   printf("s=%12lu | x_ref_flp=%.4f | x_cor_flp=%.4f | err=%.4f\n ", 
        //         s, x_ref_flp, x_cor_flp, err);
        // else
        //   printf("s=%12lu | x_ref=%lu | x_cor=%lu | err=%.4f\n ", 
        //         s, x_ref_int, x_cor, err);

        /* Print to file
          * if the absolute value of the error is greater than of 1 %,
          * the information about the considered number is printed.
          */
        if (err > 1 || err<-1) {
          err_inc += 1;
          max_err = (abs(err) > max_err) ? abs(err) : max_err;
          if (flag_err_flp)
            fprintf(pFile, "%03lu,%3.4f,%3.4f%f\n", s, x_ref_flp, x_cor_flp, err);
          else
            fprintf(pFile, "%03lu,%03lu,%03lu,%f\n", s, x_ref_int, x_cor, err);
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
  double time_taken = (double) (end - start);
  printf("Time taken by program is %lf \n", time_taken);
  
  return 0;
}


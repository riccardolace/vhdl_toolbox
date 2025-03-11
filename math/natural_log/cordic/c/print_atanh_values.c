#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char const *argv[])
{
  for(uint8_t j = 0; j < 64; j++)
  {
    float x = atanhf(powf(2, -j));
    printf("%1.64f\n", x);
  }

  return 0;
}

#!/bin/bash

# Compile
gcc -std=c99 -lm -fopenmp -O3 \
lib_cordic_ln.h lib_cordic_ln.c main.c \
-o script_cordic_ln

# Define the max number of threads
export OMP_NUM_THREADS=20

# Run
# ./script_sqrt

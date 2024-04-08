#!/bin/bash

# Compile
gcc -std=c99 -lm -fopenmp -O3 \
lib_cordicSqrt.h lib_cordicSqrt.c main.c \
-o script_sqrt

# Define the max number of threads
export OMP_NUM_THREADS=20

# Run
# ./script_sqrt

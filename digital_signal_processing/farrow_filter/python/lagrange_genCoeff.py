"""
 lagrange_genCoeff.py
 Author: Daniele Giardino
 Date: 2025.06.24

 Description: 
   Generates the coefficients of the Farrow filter using the Lagrange
   interpolation method.
"""
import numpy as np
from scipy.special import binom

def nchoosek(n, k):
  if k == 0:
    r = 1
  else:
    r = n/k * nchoosek(n-1, k-1)
  return round(r)

def lagrange_genCoeff(num_coeffs):
  """Generates Lagrange coefficients for the modified Farrow structure.

  Args:
    num_coeffs: The number of coefficients in the Farrow structure.

  Returns:
    Q: The matrix of Lagrange coefficients.
  """

  N = num_coeffs - 1  # Filter's order
  M = N + 1  # Number of FIR filters

  # Vandermonde matrix
  U = np.zeros((N + 1, N + 1))
  for i in range(0, N+1):
    for j in range(0, N+1):
      U[j, i] = j**i

  # Compute the inverse of the Vandermonde matrix
  Q = np.linalg.inv(U)

  # Modified Farrow structure coefficients
  T = np.zeros((N + 1, N + 1))
  for n in range(0, N + 1):
    for m in range(0, N + 1):
      if n >= m:
        #coeff_bin = np.math.factorial(n) // (np.math.factorial(m) * np.math.factorial(n - m))
        #coeff_bin = nchoosek(n, m)
        coeff_bin = binom(n, m)
        # print("(%i,%i)=%i" % (n,m,coeff_bin))
        T[n, m] = (np.floor(N / 2)**(n - m)) * coeff_bin

  # Transpose the T matrix
  # Matlab - T = T.'
  T = T.transpose()

  # Calculate the Lagrange coefficients
  # Matlab - Q = T / U
  Q = np.dot(T, np.linalg.inv(U))

  # Delete small values
  val_tol = 1e-15
  for n in range(0, N + 1):
    for m in range(0, N + 1):
      Q[n,m] = 0 if np.abs(Q[n,m])<val_tol else Q[n,m]

  return Q

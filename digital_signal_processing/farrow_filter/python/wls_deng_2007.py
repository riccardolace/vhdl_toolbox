"""
wls_deng_2007.m
Author: Daniele Giardino
Date: 2025.06.24

Description: 
  Generates the coefficients of the Farrow filter using the Weighted
  Least Square (WLS) method as shown in the paper:
      Deng, Tian-Bo. "Weighted-least-squares design of odd-order variable 
      fractional-delay filters using coefficient-symmetry."
      2007 6th International Conference on Information, 
      Communications & Signal Processing. IEEE, 2007.
"""

import numpy as np
from scipy.special import factorial
from scipy.integrate import quad

def wls_deng_2007(M, N, alpha):
    """
    Designs a set of variable fractional-delay FIR filters using WLS optimization.

    H = wls_deng_2007(M, N, ALPHA) returns a matrix H containing the coefficients
    of (M+1) symmetric and antisymmetric fractional-delay FIR filters, each of length (2*(N+1)),
    for use in a Farrow filter structure. The filters are designed using the Weighted Least Squares (WLS)
    method as described in:

        Deng, Tian-Bo. "Weighted-least-squares design of odd-order variable
        fractional-delay filters using coefficient-symmetry." 2007 6th
        International Conference on Information, Communications & Signal
        Processing. IEEE, 2007.

    INPUTS:
        M     - Number of filters minus one (total filters = M+1)
        N     - Filter order parameter (filter length = 2*(N+1))
        ALPHA - Weighting parameter for the WLS optimization

    OUTPUT:
        H     - Matrix of filter coefficients, size (M+1) x (2*N+1). Each row contains
                the coefficients of one FIR filter that composes the Farrow filter.
                The filters are symmetric and antisymmetric; users should examine the
                coefficients of each FIR filter for implementation.
    """

    print('1. COEFFICIENT SYMMETRY')
    K_1i = 10  # Number of Taylor Series Approximation. It's an arbitrary factor.
    K_6i = 10  # Number of Taylor Series Approximation. It's an arbitrary factor.
    delay = 0.5  # Delay parameter
    RelTol = 1.e-7  # Relative tolerance for numerical integration

    # Symbolic variables
    if M % 2 == 1:
        M_o = (M - 1) // 2
        M_e = M_o
    else:
        M_e = M // 2
        M_o = M_e - 1
    
    p_e = lambda p: np.power(p, np.arange(0, 2 * M_e + 1, 2)).reshape(-1, 1)
    p_o = lambda p: np.power(p, np.arange(1, 2 * M_o + 2, 2)).reshape(-1, 1)

    c = lambda omega: np.cos(omega * (np.arange(0, N + 1) + 1/2)).reshape(-1, 1)
    s = lambda omega: np.sin(omega * (np.arange(0, N + 1) + 1/2)).reshape(-1, 1)

    print('2. CLOSED-FORM ERROR FUNCTION')
    W_1 = lambda omega: 1  # Weighting function for the frequency domain
    W_2 = lambda p: 1      # Weighting function for the time domain

    # Numerical Integrals
    A_1 = 0
    for i in range(1, K_1i + 1):
        integrand_A1_t1 = lambda p: W_2(p) * (p**(2*(i-1))) * p_e(p).flatten()
        integrand_A1_t2 = lambda omega: W_1(omega) * (omega**(2*(i-1))) * c(omega).flatten()

        integral_A1_t1_val = np.array([quad(lambda p_val: integrand_A1_t1(p_val)[j], 0, delay, epsrel=RelTol)[0] for j in range(p_e(0.1).size)]).reshape(-1, 1)
        integral_A1_t2_val = np.array([quad(lambda omega_val: integrand_A1_t2(omega_val)[j], 0, alpha * np.pi, epsrel=RelTol)[0] for j in range(c(0.1).size)]).reshape(-1, 1)

        temp = ((-1)**(i-1) / factorial(2*(i-1))) * integral_A1_t1_val @ integral_A1_t2_val.T
        A_1 += temp

    integrand_A2_t = lambda p: W_2(p) * (p_e(p) @ p_e(p).T)
    A_2_shape = p_e(0.1).shape[0], p_e(0.1).shape[0]
    A_2 = np.zeros(A_2_shape)
    for row in range(A_2_shape[0]):
        for col in range(A_2_shape[1]):
            A_2[row, col] = quad(lambda p: integrand_A2_t(p)[row, col], 0, delay, epsrel=RelTol)[0]

    integrand_A3_t = lambda omega: W_1(omega) * (c(omega) @ c(omega).T)
    A_3_shape = c(0.1).shape[0], c(0.1).shape[0]
    A_3 = np.zeros(A_3_shape)
    for row in range(A_3_shape[0]):
        for col in range(A_3_shape[1]):
            A_3[row, col] = quad(lambda omega: integrand_A3_t(omega)[row, col], 0, alpha * np.pi, epsrel=RelTol)[0]

    integrand_A4_t = lambda p: W_2(p) * (p_o(p) @ p_o(p).T)
    A_4_shape = p_o(0.1).shape[0], p_o(0.1).shape[0]
    A_4 = np.zeros(A_4_shape)
    for row in range(A_4_shape[0]):
        for col in range(A_4_shape[1]):
            A_4[row, col] = quad(lambda p: integrand_A4_t(p)[row, col], 0, delay, epsrel=RelTol)[0]

    integrand_A5_t = lambda omega: W_1(omega) * (s(omega) @ s(omega).T)
    A_5_shape = s(0.1).shape[0], s(0.1).shape[0]
    A_5 = np.zeros(A_5_shape)
    for row in range(A_5_shape[0]):
        for col in range(A_5_shape[1]):
            A_5[row, col] = quad(lambda omega: integrand_A5_t(omega)[row, col], 0, alpha * np.pi, epsrel=RelTol)[0]

    A_6 = 0
    for i in range(1, K_6i + 1):
        integrand_A6_t1 = lambda p: W_2(p) * (p**(2*i-1)) * p_o(p).flatten()
        integrand_A6_t2 = lambda omega: W_1(omega) * (omega**(2*i-1)) * s(omega).flatten()

        integral_A6_t1_val = np.array([quad(lambda p_val: integrand_A6_t1(p_val)[j], 0, delay, epsrel=RelTol)[0] for j in range(p_o(0.1).size)]).reshape(-1, 1)
        integral_A6_t2_val = np.array([quad(lambda omega_val: integrand_A6_t2(omega_val)[j], 0, alpha * np.pi, epsrel=RelTol)[0] for j in range(s(0.1).size)]).reshape(-1, 1)

        temp = ((-1)**(i-1) / factorial(2*i-1)) * integral_A6_t1_val @ integral_A6_t2_val.T
        A_6 += temp

    print('3. OPTIMAL SOLUTION')

    # Cholesky factorization
    flag2, flag3, flag4, flag5 = 1, 1, 1, 1 # Initialize flags as if not positive definite

    try:
        U_2 = np.linalg.cholesky(A_2).T  # .T for upper triangular
        flag2 = 0
    except np.linalg.LinAlgError:
        pass

    try:
        U_3 = np.linalg.cholesky(A_3).T  # .T for upper triangular
        flag3 = 0
    except np.linalg.LinAlgError:
        pass

    try:
        U_4 = np.linalg.cholesky(A_4).T  # .T for upper triangular
        flag4 = 0
    except np.linalg.LinAlgError:
        pass

    try:
        U_5 = np.linalg.cholesky(A_5).T  # .T for upper triangular
        flag5 = 0
    except np.linalg.LinAlgError:
        pass

    if sum([flag2, flag3, flag4, flag5]) == 0:
        print('Matrices are positive definite, using Cholesky factorization for optimal solution')
        B_e = np.linalg.inv(U_3) @ (np.linalg.inv(U_3).T @ A_1.T @ np.linalg.inv(U_2)) @ np.linalg.inv(U_2).T
        B_o = np.linalg.inv(U_5) @ (np.linalg.inv(U_5).T @ A_6.T @ np.linalg.inv(U_4)) @ np.linalg.inv(U_4).T
    else:
        print('Matrices not positive definite, using direct method for optimal solution')
        B_e = np.linalg.inv(A_3) @ A_1.T @ np.linalg.inv(A_2)
        B_o = np.linalg.inv(A_5) @ A_6.T @ np.linalg.inv(A_4)

    print('4. COEFFICIENT SYMMETRY')
    B = np.zeros((N + 1, M_e + M_o + 2))
    B[:, ::2] = B_e
    B[:, 1::2] = B_o

    A = 0.5 * B
    A = np.vstack((np.flipud(A), A))
    A[:N + 1, 1::2] = -A[:N + 1, 1::2]

    print('Final matrix H construction')
    H = A.T
    return H
"""
main.m
Author: Daniele
Date: 2025.06.24

Description:
  This script designs and analyzes Fractional Delay (FD) FIR filters
  using the WLS algorithm (Farrow structure) approach. It computes the filter
  coefficients for different fractional delays, evaluates their frequency
  responses, and visualizes magnitude, phase, and group delay.

Dependencies:
  - wls_deng_2004.m (function to generate Farrow coefficients)
  - wls_deng_2007.m (function to generate Farrow coefficients)

Sections:
  1. Initialization & Parameters
  2. Farrow Filter Coefficient Generation
  3. FD FIR Filter Computation
  4. Frequency Response Analysis
  5. Plotting Results
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz, group_delay
# Assuming wls_deng_2004 and wls_deng_2007 are in the same directory or accessible in PYTHONPATH
from wls_deng_2004 import wls_deng_2004
from wls_deng_2007 import wls_deng_2007

def main():
    """
    This script designs and analyzes Fractional Delay (FD) FIR filters
    using the WLS algorithm (Farrow structure) approach. It computes the filter
    coefficients for different fractional delays, evaluates their frequency
    responses, and visualizes magnitude, phase, and group delay.
    """

    # 1. Initialization & Parameters
    print('1. Initialization & Parameters')
    
    # Filter order parameter
    N = 4

    # Number of the FIR filters in the Farrow structure
    M = 4  # Number of filters minus one (total filters = M+1)

    # Alpha parameter for WLS design
    # Increase alpha for wider passband, decrease for sharper transition
    # Typical values: 0.5 for moderate transition, 0.1 for sharper
    # transition, 0.01 for very sharp transition.
    # Note: The value of alpha must be less than 1.
    alpha = 0.5

    # WLS type: '2004' or '2007'
    WLS_type = '2007'  # Choose between '2004' and '2007'

    # Plotting options
    plot_mag = 1      # Plot magnitude response
    plot_phase = 0    # Plot phase response
    plot_grpDelay = 1 # Plot group delay

    # Frequency response parameters
    nFFT = 2**10      # Number of FFT points

    # 2. Farrow Filter Coefficient Generation
    print('\n2. Farrow Filter Coefficient Generation')

    # Generate Farrow filter coefficients based on WLS type
    if WLS_type == '2004':
        H_Farrow = wls_deng_2004(M, N, alpha)
    elif WLS_type == '2007':
        H_Farrow = wls_deng_2007(M, N, alpha)
    else:
        raise ValueError('Invalid WLS type. Choose either "2004" or "2007".')

    numCoeffs = H_Farrow.shape[1]  # Number of coefficients per filter
    print(f'Number of coefficients in the Farrow structure: {numCoeffs}')

    # Set the Farrow filter coefficients to zero for numerical stability
    H_Farrow[np.abs(H_Farrow) < 1e-12] = 0

    # Round the first row
    if WLS_type == '2004':
        H_Farrow[0, :] = np.round(H_Farrow[0, :])

    print('Modified Farrow Coefficients (small values set to zero):')
    print(H_Farrow)

    # 3. FD FIR Filter Computation
    print('\n3. FD FIR Filter Computation')

    # Define delay range (fractional delays)
    if WLS_type == '2004':
        delay_min = 0
    else:
        delay_min = -0.5
    
    delay_step = 1 / 8
    delay_max = delay_min + 1 - delay_step
    delay_vec = np.arange(delay_min, delay_max + delay_step/2, delay_step) # Added small offset for float precision

    # Preallocate matrix to store FD FIR filter coefficients
    h_mat = np.zeros((len(delay_vec), numCoeffs))

    # Compute FD FIR filter coefficients for each fractional delay
    for i, d_val in enumerate(delay_vec):
        d_powers = d_val ** np.arange(0, H_Farrow.shape[0])
        h_mat[i, :] = np.sum(H_Farrow * d_powers[:, np.newaxis], axis=0)

    # 4. Frequency Response Analysis
    print('\n4. Frequency Response Analysis')

    # Preallocate matrices for frequency responses
    Hf_mag_db = np.zeros((nFFT, len(delay_vec))) # Magnitude response in dB
    Hf_ph = np.zeros((nFFT, len(delay_vec)))     # Phase response
    Hf_grpDel = np.zeros((nFFT, len(delay_vec))) # Group delay response
    leg_vec = [f'd = {d:.3f}' for d in delay_vec] # Legend entries for plots

    # Compute frequency responses for each FD FIR filter
    for i in range(len(delay_vec)):
        b = h_mat[i, :]
        a = 1 # Denominator for FIR filter

        # Magnitude Response
        if plot_mag:
            w, h = freqz(b, a, nFFT, whole=False)
            Hf_mag_db[:, i] = 20 * np.log10(np.abs(h))

        # Phase Response
        if plot_phase:
            w_ph, ph = freqz(b, a, nFFT, whole=False)
            Hf_ph[:, i] = np.unwrap(np.angle(ph)) # Unwrapped phase

        # Group Delay Response
        if plot_grpDelay:
            w_gd, gd = group_delay((b, a), nFFT, whole=False)
            Hf_grpDel[:, i] = gd

    # Normalize frequency axis to pi
    w_normalized = w / np.pi

    # 5. Plotting Results
    print('\n5. Plotting Results')

    # Plot Magnitude Response
    if plot_mag:
        plt.figure('Magnitude', figsize=(10, 8))
        plt.subplot(2, 1, 1)
        plt.plot(w_normalized, Hf_mag_db)
        plt.grid(True)
        plt.legend(leg_vec, loc='upper right')
        plt.xlabel('Normalized Frequency \u00D7 \u03C0')
        plt.ylabel('Magnitude [dB]')
        plt.title('Magnitude Response (Full Band)')

        plt.subplot(2, 1, 2)
        plt.plot(w_normalized, Hf_mag_db)
        plt.grid(True)
        plt.xlabel('Normalized Frequency \u00D7 \u03C0')
        plt.ylabel('Magnitude [dB]')
        plt.xlim([0, alpha])
        plt.ylim([-0.1, 0.1])
        plt.title('Magnitude Response (Zoomed)')
        plt.tight_layout()

    # Plot Group Delay Response
    if plot_grpDelay:
        plt.figure('Group Delay', figsize=(10, 8))
        plt.subplot(2, 1, 1)
        plt.plot(w_normalized, Hf_grpDel)
        plt.grid(True)
        plt.legend(leg_vec, loc='upper right')
        plt.xlabel('Normalized Frequency \u00D7 \u03C0')
        plt.ylabel('Group Delay [samples]')
        plt.title('Group Delay')

        plt.subplot(2, 1, 2)
        # Replicate the first row of Hf_grpDel for broadcasting
        first_gd_row = Hf_grpDel[0, :][np.newaxis, :]
        plt.plot(w_normalized, Hf_grpDel - first_gd_row)
        plt.grid(True)
        plt.xlabel('Normalized Frequency \u00D7 \u03C0')
        plt.ylabel('Group Delay Error [samples]')
        plt.xlim([0, alpha])
        plt.ylim([-1, 1])
        plt.title('Group Delay Error (Zoomed)')
        plt.tight_layout()

    # Plot Phase Response
    if plot_phase:
        plt.figure('Phase', figsize=(10, 6))
        plt.plot(w_normalized, Hf_ph)
        plt.grid(True)
        plt.legend(leg_vec, loc='upper right')
        plt.xlabel('Normalized Frequency \u00D7 \u03C0')
        plt.ylabel('Phase [radians]')
        plt.title('Phase Response')
        plt.tight_layout()

    plt.show()

if __name__ == '__main__':
    main()
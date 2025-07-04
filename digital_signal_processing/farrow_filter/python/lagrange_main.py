"""
main.m
Author: Daniele
Date: 2024.06.10
Description:
  This script designs and analyzes Fractional Delay (FD) FIR filters
  using the Lagrange (Farrow structure) approach. It computes the filter
  coefficients for different fractional delays, evaluates their frequency
  responses, and visualizes magnitude, phase, and group delay.
Dependencies:
  - genLagrangeCoeff.m (function to generate Farrow coefficients)
Sections:
  1. Initialization & Parameters
  2. Farrow Filter Coefficient Generation
  3. FD FIR Filter Computation
  4. Frequency Response Analysis
  5. Plotting Results
"""
# Import libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import freqz, group_delay

# Import the function to generate Lagrange coefficients
# Ensure that genLagrangeCoeff.py is in the same directory or in the Python path
from lagrange_genCoeff import lagrange_genCoeff

'''
1. Initialization & Parameters
'''

# Number of coefficients of the Fractional Delay (FD) FIR filters
numCoeffs = 5

# Plott options
# 1: plot, 0: do not plot
# Set to 1 to plot magnitude, phase, and group delay responses
plot_mag = 1
plot_phase = 0
plot_grpDelay = 1

# Frequency Response
nFFT = 2**10

'''
2. Farrow Filter Coefficient Generation
'''

# Generate Farrow filter coefficients using Lagrange interpolation
H_Farrow = lagrange_genCoeff(numCoeffs)

# Set very small values in H_Farrow to zero for numerical stability
threshold = 1e-12
H_Farrow[np.abs(H_Farrow) < threshold] = 0.0

# Print the Farrow coefficients for debugging
print("H_Farrow")
print(H_Farrow)

'''
3. FD FIR Filter Computation
'''

# Define delay range (fractional delays)
delay_step = 1.0 / 8.0            # Step size for fractional delays
delay_min = 0                     # Minimum delay
delay_max = 1 - delay_step        # Maximum delay

# Vector of fractional delays
delay_vec = np.arange(delay_min, delay_max + delay_step, delay_step)

# Preallocate matrix to store FD FIR filter coefficients
h_mat = np.zeros((len(delay_vec), numCoeffs))

# Compute FD FIR filter coefficients for each fractional delay
# Using the Farrow structure, we compute the coefficients for each delay
# by evaluating the polynomial at the corresponding delay value.
# The coefficients are computed as a linear combination of the Farrow coefficients
# raised to the power of the delay.
# This is equivalent to evaluating the polynomial at the fractional delay.
# The outer product is used to create a matrix where each row corresponds to a delay.
# The delay vector is raised to the power of the index of the coefficients,
# and then the Farrow coefficients are multiplied by these powers.
# The result is summed across the rows to get the final coefficients for each delay.
# This approach allows us to efficiently compute the coefficients for multiple delays
for i in range(len(delay_vec)):
  # Compute powers of current delay value
  d = delay_vec[i] ** (np.arange(H_Farrow.shape[0]))
  # Apply Farrow structure to get filter coefficients
  h_tmp = H_Farrow * np.outer(d, np.ones(numCoeffs))
  # print(np.outer(d, np.ones(numCoeffs)))
  h_mat[i, :] = np.sum(h_tmp, axis=0)
print("h_mat")
print(h_mat)

'''
4. Frequency Response Analysis
'''

# Preallocate arrays for frequency response
# - Hf_mag: Magnitude response
# - Hf_ph: Phase response
# - Hf_grpDel: Group delay response
# - leg_vec: Legend vector for plotting
Hf_mag_dB = np.zeros((nFFT, len(delay_vec)))
Hf_ph = np.zeros((nFFT, len(delay_vec)))
Hf_grpDel = np.zeros((nFFT, len(delay_vec)))
leg_vec = [f'd = {d:.3f}' for d in delay_vec] # Legend entries for plots

# Compute frequency response for each delay
# - Magnitude response: Hf_mag_dB
# - Phase response: Hf_ph
# - Group delay response: Hf_grpDel
for i in range(len(delay_vec)):
  b = h_mat[i, :]
  a = 1 # Denominator for FIR filter

  # Magnitude Response
  if plot_mag:
      w, h = freqz(b, a, nFFT, whole=False)
      Hf_mag_dB[:, i] = 20 * np.log10(np.abs(h))

  # Phase Response
  if plot_phase:
      w_ph, ph = freqz(b, a, nFFT, whole=False)
      Hf_ph[:, i] = np.unwrap(np.angle(ph)) # Unwrapped phase

  # Group Delay Response
  if plot_grpDelay:
      w_gd, gd = group_delay((b, a), nFFT, whole=False)
      Hf_grpDel[:, i] = gd


'''
5. Plotting Results
'''

# Plotting the results based on the specified options
# The results are plotted using Matplotlib, with separate figures for magnitude,
# phase, and group delay responses. Each figure contains subplots for better visualization.
# The magnitude response is plotted in decibels (dB) for better visibility,
# while the phase response is plotted in radians. The group delay is plotted in samples.
# The plots include grid lines, labels, and legends for clarity.

if plot_mag == 1:
  # Plot magnitude response and its error
  # The magnitude response is plotted in decibels (dB) to show the gain
  # of the filter at different frequencies. The first subplot shows the full range,
  # while the second subplot zooms in on a specific frequency range for better visibility.
  plt.figure('Magnitude')

  plt.subplot(2, 1, 1)
  plt.plot(w/np.pi, Hf_mag_dB)
  plt.grid(True)
  plt.xlim([0, 1])
  plt.legend(leg_vec, loc='upper right')
  plt.xlabel('Normalized Frequency \u00D7 \u03C0')
  plt.ylabel('Magnitude [dB]')

  plt.subplot(2, 1, 2)
  plt.plot(w/np.pi, Hf_mag_dB)
  plt.grid(True)
  plt.xlabel('Normalized Frequency \u00D7 \u03C0')
  plt.ylabel('Magnitude [dB]')
  plt.xlim([0, 0.4])
  plt.ylim([-0.1, 0.1])

if plot_grpDelay == 1:

  # Delay offset
  # The group delay is expected to be (numCoeffs-1)/2 for a symmetric FIR filter.
  # This offset is subtracted from the group delay to center it around zero,
  # allowing for a clearer view of the variations in delay across frequencies.
  delay_offset = (numCoeffs - 1) / 2

  # Plot group delay and its error
  # The group delay is plotted in samples, showing how the delay varies with frequency.
  plt.figure('Group Delay')

  plt.subplot(2, 1, 1)
  plt.plot(w_gd/np.pi, Hf_grpDel)
  plt.grid(True)
  plt.xlim([0, 1])
  plt.legend(leg_vec, loc='upper right')
  plt.xlabel('Normalized Frequency \u00D7 \u03C0')
  plt.ylabel('Group Delay [samples]')

  plt.subplot(2, 1, 2)
  plt.plot(w_gd/np.pi, Hf_grpDel - delay_offset)
  plt.grid(True)
  plt.xlabel('Normalized Frequency \u00D7 \u03C0')
  plt.ylabel('Group Delay Error [samples]')
  plt.xlim([0, 0.4])
  plt.ylim([-1, 1] * 1)

if plot_phase == 1:
  # Plot phase response and its error
  # The phase response is plotted in radians, showing how the phase shifts with frequency.
  plt.figure('Phase')
  plt.plot(w_ph/np.pi, Hf_ph)
  plt.grid(True)
  plt.legend(leg_vec, loc='upper right')
  plt.xlabel('Normalized Frequency \u00D7 \u03C0')
  plt.ylabel('Phase [radians]')

plt.show()

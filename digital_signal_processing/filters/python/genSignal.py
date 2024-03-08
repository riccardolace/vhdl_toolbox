
"""
Author: Daniele Giardino
Date: 2024.03.08

Descritpion
The script generates a text file used in the testbench.
"""

# Import libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

# Parameters
numSps = 2048 # Length
Wl = 16     # Bit length

# Data
Fs  = 100e6
fc0 = Fs/64.0
fc1 = Fs/8.0
n = np.arange(start=0, stop=numSps, step=1)
x  = 0.25*np.cos(2*np.pi*fc0/Fs*n)
x += 0.25*np.cos(2*np.pi*fc1/Fs*n)
x += np.random.normal(0, 1e-1, size=(numSps))

# FLP to FXP
# The amplitude of the signal x is between 1 and -1,
# so simply multiply by 2**(Wl-1)-1
A = 2**(Wl-1)-1
x = A * x

# FFT
Fs = 100e6
nFFT = 2**8
w, Xf = signal.freqz(b=x, a=2**15 * np.size(x),
                      worN=nFFT,
                      whole=False)
Xf = 20*np.log10(np.abs(Xf))
w = w/np.pi * Fs/2e6

plt.figure()
plt.plot(w, Xf, '-', label='Xf')
plt.grid()
plt.legend(loc='upper right')
plt.xlabel('Frequency [MHz]')
plt.ylabel('Amplitude [dB]')

plt.show()

# Filename
fileName = "data_in.txt"

# Loop
with open(fileName, "w") as file:
  for i in range(0,np.size(x)):
    # int32 conversion
    x_tmp = int(x[i])     
    
    # Typecast negative number int to uint
    if x_tmp<0:
      x_tmp += 2**32
    
    # String binary representation
    bin_str = bin(x_tmp)
    
    # Delete "0b" chars inserted by 'bin' function
    if bin_str[0:2] == "0b":
      bin_str = bin_str[2:]
    
    # Take the last 'Wl' bits because there can be 32 bits for negative numbers
    if len(bin_str)>Wl:
      bin_str = bin_str[-Wl:]
    
    # Resize bits (like VHDL)
    # Positive numbers must be preceded by zeros
    while len(bin_str)<Wl:
      bin_str = "0" + bin_str
    
    # Write the binary number in the file
    file.write(bin_str)

    # If x_tmp is not the last, newline "\n" is written
    if i<np.size(x)-1:
      file.write("\n")

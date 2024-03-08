
"""
Author: Daniele Giardino
Date: 2024.03.08

Descritpion
The script generates a text file used in the testbench.
"""

# Import libraries
import numpy as np
import matplotlib.pyplot as plt

# Import the submodule signal of scipy to use the correlation funciton
from scipy import signal

# Parameters
Wl = 18     # Bit length

# FIR Filter
Fs  = 100e6
fc  = Fs/16
fir_ord = 63
fir_len = fir_ord+1
Wn = fc / (Fs/2)
x = signal.firwin(numtaps=fir_len,
                  cutoff=Wn,
                  window='nuttall')
print("fc = %f MHz" % (fc/1e6))
print("Fs = %f MHz" % (Fs/1e6))

# Energy normalization
x = x / np.sum(x)

# FLP to FXP
# The amplitude of the signal x is between 1 and -1,
# so simply multiply by 2**(Wl-1)-1
print("max x = %f" % (np.max(np.abs(x))))
A = 2**(Wl-1)-1
x_flp = A * x
x_fxp = np.round(x_flp)

# Figure
nFFT = 2**12
w, Xf_flp = signal.freqz(b=x_flp, a=A,
                         worN=nFFT,
                         whole=False)
w, Xf_fxp = signal.freqz(b=x_fxp, a=A,
                         worN=nFFT,
                         whole=False)
Xf_flp = 20*np.log10(np.abs(Xf_flp))
Xf_fxp = 20*np.log10(np.abs(Xf_fxp))

# Frequency normalization
w = w/np.pi*(Fs/2e6)
plt.figure()
plt.plot(w, Xf_flp, '-', label='H_{FLP}')
plt.plot(w, Xf_fxp, '-', label='H_{FXP}')
plt.grid()
plt.legend(loc='upper right')
plt.xlabel('Frequency [MHz]')
plt.ylabel('Amplitude [dB]')
plt.show()

# Filename
fileName = "coeffs_len%i_Wl%i.txt" % (fir_len,Wl)

# Loop
with open(fileName, "w") as file:
  for i in range(0,np.size(x_fxp)):
    # int32 conversion
    x_tmp = int(x_fxp[i])     
    
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
    if i<np.size(x_fxp)-1:
      file.write("\n")

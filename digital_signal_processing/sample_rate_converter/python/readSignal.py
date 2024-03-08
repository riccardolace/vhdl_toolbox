
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

# FXP parameters
Wl = 18
A  = 2**(Wl-1) - 1
K  = 2**(Wl) 

# Program to read the entire file using read() function
x = np.array([])
file = open("../testbench/data_out.txt", "r")
while True:
	# Read bin string
	content=file.readline()
	if not content:
		break
		
  # Convert bin string to int number
	x_tmp = int(content[0:Wl], base=2)
	if x_tmp>A:
		x_tmp = x_tmp - K
	
	x = np.append(x, x_tmp)
	
file.close()

# Int to Q notation
x = x / 2**(Wl-1)

# FFT
nFFT = 2**12
w, Xf = signal.freqz(b=x, a=np.min([np.size(x),nFFT]),
                      worN=nFFT,
                      whole=False)
Xf = 20*np.log10(np.abs(Xf))
w = w/np.pi

# Figure
plt.figure()

plt.subplot(2,1,1)
plt.plot(x, '-', label='x', marker='s')
plt.grid()
plt.legend(loc='upper right')
plt.xlabel('Samples')
plt.ylabel('Amplitude')

plt.subplot(2,1,2)
plt.plot(w, Xf, '-', label='Xf')
plt.grid()
plt.legend(loc='upper right')
plt.xlabel('Frequency [MHz]')
plt.ylabel('Amplitude [dB]')

plt.show()


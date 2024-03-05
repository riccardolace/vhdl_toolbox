
"""
Author: Daniele Giardino
Date: 2024.03.05

Descritpion
The script generates a text file used in the testbench.
"""

# Import libraries
import numpy as np

# Parameters
dataType = "signed"
numSps = 64 # Length
Wl = 16     # Bit length


if dataType=="signed":
  # Data
  n = np.arange(start=-numSps/2, stop=numSps/2, step=1)
  
  # Filename
  fileName = "data_signed.txt"

elif dataType=="unsigned":
  # Data
  n = np.arange(start=0, stop=numSps, step=1)
  
  # Filename
  fileName = "data_unsigned.txt"

else:
  print("You must select \"signed\" or \"unsigned\".")

print(n)

# Loop
with open(fileName, "w") as file:
  for i in range(0,np.size(n)):
    # int32 conversion
    n_tmp = int(n[i])     
    
    # Typecast negative number int to uint
    if n_tmp<0:
      n_tmp += 2**32
    
    # String binary representation
    bin_str = bin(n_tmp)
    
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

    # If n_tmp is not the last, newline "\n" is written
    if i<np.size(n)-1:
      file.write("\n")

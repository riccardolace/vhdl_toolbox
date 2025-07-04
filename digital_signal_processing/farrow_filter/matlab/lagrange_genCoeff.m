%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lagrange_genCoeff.m
% Author: Daniele Giardino
% Date: 2025.06.24
%
% Description: 
%   Generates the coefficients of the Farrow filter using the Lagrange
%   interpolation method.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Q = lagrange_genCoeff(numCoeffs)
% Generate Lagrange coefficients for Farrow structure
%
%   Q = lagrange_genCoeff(numCoeffs)
%
%   Input:
%     numCoeffs - Number of coefficients (order + 1) in the Farrow structure
%
%   Output:
%     Q - Matrix of Lagrange coefficients

%% SECTION 1: Initialization
N = numCoeffs - 1;    % Filter order
M = N + 1;            % Number of FIR subfilters

%% SECTION 2: Construct Vandermonde Matrix
% The Vandermonde matrix is used to solve for the Lagrange interpolation coefficients.
U = zeros(M, M);
for i = 0:N
  for j = 0:N
    U(j + 1, i + 1) = j^i;
  end
end

%% SECTION 3: Compute Inverse of Vandermonde Matrix
% The inverse is used to obtain the Lagrange basis coefficients.
Q = inv(U);

%% SECTION 4: Compute Modified Farrow Structure Coefficients
% T matrix contains the binomial and scaling terms for the Farrow structure.
T = ones(size(Q));
for n = 0:N
  for m = 0:N
    if n >= m
      coeff_bin = nchoosek(n, m); % Binomial coefficient
      T(n + 1, m + 1) = floor(N / 2)^(n - m) * coeff_bin;
    else
      T(n + 1, m + 1) = 0;
    end
  end
end

%% SECTION 5: Transpose T Matrix
T = T';

%% SECTION 6: Calculate Final Lagrange Coefficient Matrix
% The final coefficient matrix Q is obtained by multiplying T and inv(U).
Q = T / U;

end

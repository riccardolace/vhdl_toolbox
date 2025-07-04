%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wls_deng_2007.m
% Author: Daniele Giardino
% Date: 2025.06.24
%
% Description: 
%   Generates the coefficients of the Farrow filter using the Weighted
%   Least Square (WLS) method as shown in the paper:
%       Deng, Tian-Bo. "Weighted-least-squares design of odd-order variable
%       fractional-delay filters using coefficient-symmetry."
%       2007 6th International Conference on Information,
%       Communications & Signal Processing. IEEE, 2007.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [H] = wls_deng_2007(M,N,alpha)
% WLS_DENG_2007 Designs a set of variable fractional-delay FIR filters using WLS optimization.
%
%   H = wls_deng_2007(M, N, ALPHA) returns a matrix H containing the coefficients
%   of (M+1) symmetric and antisymmetric fractional-delay FIR filters, each of length (2*(N+1)),
%   for use in a Farrow filter structure. The filters are designed using the Weighted Least Squares (WLS)
%   method as described in:
%
%       Deng, Tian-Bo. "Weighted-least-squares design of odd-order variable
%       fractional-delay filters using coefficient-symmetry." 2007 6th
%       International Conference on Information, Communications & Signal
%       Processing. IEEE, 2007.
%
% INPUTS:
%   M     - Number of filters minus one (total filters = M+1)
%   N     - Filter order parameter (filter length = 2*(N+1))
%   ALPHA - Weighting parameter for the WLS optimization
%
% OUTPUT:
%   H     - Matrix of filter coefficients, size (M+1) x (2*N+1). Each row contains
%           the coefficients of one FIR filter that composes the Farrow filter.
%           The filters are symmetric and antisymmetric; users should examine the
%           coefficients of each FIR filter for implementation.
%
% NOTE:
%   This function was developed using the theory described in the above reference.
%
% Example:
%   M = 4;  % Number of filters = (M+1)
%   N = 5;  % Number of coefficients = (2*(N+1))
%   H = wls_deng_2007(M, N, ALPHA)

% COEFFICIENT SYMMETRY
disp('1. COEFFICIENT SYMMETRY')
K_1i = 10;          % Number of Taylor Series Approximation. It's an arbitrary factor.
K_6i = 10;          % Number of Taylor Series Approximation. It's an arbitrary factor.
delay = 0.5;        % Delay parameter
RelTol = 1.e-7;     % Relative tolerance for numerical integration

% Symbolic variables
if mod(M,2)==1
    M_o = (M-1) / 2;
    M_e = M_o;
else
    M_e = M/2;
    M_o = M_e-1;    
end
p_e = @(p) (p.^(0:2:(2*M_e))   ).';         % Even powers of p
p_o = @(p) (p.^(1:2:(2*M_o+1)) ).';         % Odd powers of p

c = @(omega) cos(omega * ((0:N)+1/2) ).';   % Cosine terms for the Taylor series
s = @(omega) sin(omega * ((0:N)+1/2) ).';   % Sine terms for the Taylor series

% CLOSED-FORM ERROR FUNCTION
disp('2. CLOSED-FORM ERROR FUNCTION')
% Change the weighting functions as needed.
% W_1 = @(omega) (omega<alpha*pi).*exp(1*omega) + (omega>=alpha*pi).*(1e-5);
% W_2 = @(p) (p<=0.5).*exp(-1*p);
% The above weighting functions are examples and can be modified based on the specific requirements of the WLS optimization.
W_1 = @(omega) 1;   % Weighting function for the frequency domain
W_2 = @(p) 1;       % Weighting function for the time domain

% Example of alternative weighting functions:
% Uncomment and modify the following lines to use different weighting functions.
% W_1 = @(omega) (omega<alpha*pi).*exp(1*omega) + (omega>=alpha*pi).*(1e-5);
% W_2 = @(p) (p<=0.5).*exp(-1*p);
% W_1 = @(omega) (omega<alpha*pi).*0.1615 + (omega>=(alpha*1.01)*pi*0.8).*1;
% W_2 = @(p) 1;
% W_2 = @(p) (p<=0.4775).*0.0469 + (p>4775).*(1);

% Numerical Integrals
% Initialize the matrices for the WLS optimization
% The matrices A_1, A_2, A_3, A_4, A_5, and A_6 will be computed based on the WLS optimization criteria.
A_1 = 0;
for i=1:K_1i
    A_1_t1 = @(p)     W_2(p) * p^(2*(i-1)) * p_e(p);
    A_1_t2 = @(omega) W_1(omega)  * omega.^(2.*(i-1)) * (c(omega).');
    temp = (((-1)^(i-1))/(factorial(2*(i-1)))) *...
          integral(A_1_t1, 0, delay,    'ArrayValued',true, 'RelTol',RelTol) * ...
          integral(A_1_t2, 0, alpha*pi, 'ArrayValued',true, 'RelTol',RelTol);
    A_1 = A_1 + temp;
end

A_2_t = @(p) W_2(p) * (p_e(p) * p_e(p).');
A_2 = integral(A_2_t, 0, delay, 'ArrayValued',true,'RelTol',RelTol );

A_3_t = @(omega) W_1(omega) * (c(omega) * c(omega).');
A_3 = integral(A_3_t, 0, alpha*pi, 'ArrayValued',true,'RelTol',RelTol );

A_4_t = @(p) W_2(p) * (p_o(p) * p_o(p).');
A_4 = integral(A_4_t, 0, delay, 'ArrayValued',true,'RelTol',RelTol );

A_5_t = @(omega) W_1(omega) * (s(omega) * s(omega).');
A_5 = integral(A_5_t, 0, alpha*pi, 'ArrayValued',true,'RelTol',RelTol );

A_6 = 0;
for i=1:K_6i
    A_6_t1 = @(p)     W_2(p) * p^(2*i-1) * p_o(p);
    A_6_t2 = @(omega) W_1(omega) * omega^(2*i-1) * (s(omega).');

    temp = (((-1)^(i-1))/(factorial(2*i-1)))*...
          integral(A_6_t1, 0, delay, 'ArrayValued',true,'RelTol',RelTol)* ...
          integral(A_6_t2, 0, alpha*pi, 'ArrayValued',true,'RelTol',RelTol );
    A_6 = A_6 + temp;
end

% OPTIMAL SOLUTION
disp('3. OPTIMAL SOLUTION')

% OPTIMAL SOLUTION USING CHOLESKY FACTORIZATION
% Cholesky factorization
[U_2, flag2] = chol(A_2);
[U_3, flag3] = chol(A_3);
[U_4, flag4] = chol(A_4);
[U_5, flag5] = chol(A_5);

% Check if the matrices are positive definite
% If any of the flags are non-zero, the matrix is not positive definite.
% If all flags are zero, the matrices are positive definite.
% If the matrices are not positive definite, we use the direct method to compute the optimal solution
% Otherwise, we use the Cholesky factorization to compute the optimal solution.
if sum([flag2,flag3,flag4,flag5]) == 0
    % If the matrices are positive definite, we use the Cholesky factorization to compute the optimal solution
    disp('Matrices are positive definite, using Cholesky factorization for optimal solution');
    B_e = inv(U_3) * (inv(U_3).' * A_1.' * inv(U_2)) * inv(U_2).';
    B_o = inv(U_5) * (inv(U_5).' * A_6.' * inv(U_4)) * inv(U_4).';

else
    % If the matrices are not positive definite, we use the direct method to compute the optimal solution
    disp('Matrices not positive definite, using direct method for optimal solution');

    % This is less efficient and not recommended for large matrices.
    % However, it is provided here for completeness and comparison purposes, as suggested by Daniele Giardino.
    B_e = (inv(A_3))*A_1.'*inv(A_2);
    B_o = (inv(A_5))*A_6.'*inv(A_4);

end

% Coefficients Symmetry
disp('4. COEFFICIENT SYMMETRY')
% Construct the final matrix H containing the coefficients of the FIR filters
% The matrix H will have (M+1) rows and (2*(N+1)) columns.
B = zeros(N+1, M_e + M_o +2 );
B(:, 1:2:2*M_e+1) = B_e;
B(:, 2:2:2*M_o+2) = B_o;

A = 0.5*B;
A = [flip(A,1) ; A];
A(1:N+1, 2:2:end) = -A(1:N+1, 2:2:end);

% The final matrix H is constructed by transposing the matrix A.
% The coefficients are arranged such that the first half of each row contains the symmetric coefficients
% and the second half contains the antisymmetric coefficients.
% The matrix H will be of size (M+1) x (2*(N+1)).
% The first row corresponds to the first FIR filter, the second row to the second FIR filter, and so on.
disp('Final matrix H construction')
H = A.';

end
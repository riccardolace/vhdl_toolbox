%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main.m
% Author: Daniele
% Date: 2025.06.24
%
% Description:
%   This script designs and analyzes Fractional Delay (FD) FIR filters
%   using the WLS algorithm (Farrow structure) approach. It computes the filter
%   coefficients for different fractional delays, evaluates their frequency
%   responses, and visualizes magnitude, phase, and group delay.
%
% Dependencies:
%   - wls_deng_2004.m (function to generate Farrow coefficients)
%   - wls_deng_2007.m (function to generate Farrow coefficients)
%
% Sections:
%   1. Initialization & Parameters
%   2. Farrow Filter Coefficient Generation
%   3. FD FIR Filter Computation
%   4. Frequency Response Analysis
%   5. Plotting Results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1. Initialization & Parameters
clc; clear;
close all;

% Filter order parameter
N = 4;

% Number of the FIR filters in the Farrow structure
M = 4;  % Number of filters minus one (total filters = M+1)

% Alpha parameter for WLS design
alpha = 0.5;

% WLS type: '2004' or '2007'
WLS_type = '2007';  % Choose between '2004' and '2007'

% Plotting options
% 1: plot, 0: do not plot
% Set to 1 to plot magnitude, phase, and group delay responses
plot_mag      = 1;    % Plot magnitude response
plot_phase    = 0;    % Plot phase response
plot_grpDelay = 1;    % Plot group delay

% Frequency response parameters
nFFT = 2^10;          % Number of FFT points

%% 2. Farrow Filter Coefficient Generation

% Generate Farrow filter coefficients based on WLS type
if strcmp(WLS_type, '2004')
  % WLS 2004 - Generate coefficients using the 2004 method
  H_Farrow = wls_deng_2004(M, N, alpha);
elseif strcmp(WLS_type, '2007')
  % WLS 2007 - Generate coefficients using the 2007 method
  H_Farrow = wls_deng_2007(M, N, alpha);
else
  error('Invalid WLS type. Choose either "2004" or "2007".');
end

% Number of coefficients in the Farrow structure
numCoeffs = size(H_Farrow, 2);  % Number of coefficients per filter

fprintf('Number of coefficients in the Farrow structure: %d\n', numCoeffs);

% Set the Farrow filter coefficients to zero for numerical stability
H_Farrow(abs(H_Farrow) < 1e-12) = 0;

% Round the first row
if strcmp(WLS_type, '2004')
  H_Farrow(1, :) = round(H_Farrow(1, :));
end

% Display the modified Farrow coefficients
disp('Modified Farrow Coefficients (small values set to zero):');
disp(H_Farrow);

%% 3. FD FIR Filter Computation

% Define delay range (fractional delays)
if strcmp(WLS_type, '2004')
  delay_min = 0;  % Minimum delay for WLS 2004
else
  delay_min = -0.5;  % Minimum delay for WLS 2007
end
delay_step = 1 / 8;                           % Step size for fractional delays
delay_max  = delay_min + 1 - delay_step;      % Maximum delay
delay_vec  = delay_min:delay_step:delay_max;  % Vector of fractional delays

% Preallocate matrix to store FD FIR filter coefficients
h_mat = zeros(length(delay_vec), numCoeffs);

% Compute FD FIR filter coefficients for each fractional delay
% Using the Farrow structure, we compute the coefficients for each delay
% by evaluating the polynomial at the corresponding delay value.
% The coefficients are computed as a linear combination of the Farrow coefficients
% raised to the power of the delay.
% This is equivalent to evaluating the polynomial at the fractional delay.
% The outer product is used to create a matrix where each row corresponds to a delay.
% The delay vector is raised to the power of the index of the coefficients,
% and then the Farrow coefficients are multiplied by these powers.
% The result is summed across the rows to get the final coefficients for each delay.
% This approach allows us to efficiently compute the coefficients for multiple delays
for i = 1:length(delay_vec)
  % Compute powers of current delay value
  d = delay_vec(i) .^ (0:size(H_Farrow, 1) - 1).';
  % Apply Farrow structure to get filter coefficients
  h_tmp = H_Farrow .* repmat(d, 1, numCoeffs);
  h_mat(i, :) = sum(h_tmp, 1);
end

%% 4. Frequency Response Analysis

% Preallocate matrices for frequency responses
Hf_mag    = zeros(nFFT, length(delay_vec)); % Magnitude response
Hf_ph     = zeros(size(Hf_mag));            % Phase response
Hf_grpDel = zeros(size(Hf_mag));            % Group delay response
leg_vec   = cell(size(Hf_ph, 2), 1);        % Legend entries for plots

% Compute frequency responses for each FD FIR filter
for i = 1:size(Hf_ph, 2)
  % Magnitude Response
  if plot_mag
    Hf_mag(:, i) = freqz(h_mat(i, :), 1, nFFT);
  end

  % Phase Response
  if plot_phase
    Hf_ph(:, i) = phasez(h_mat(i, :), 1, nFFT);
  end

  % Group Delay Response
  if plot_grpDelay
    [Hf_grpDel(:, i), w] = grpdelay(h_mat(i, :), 1, nFFT);
  end

  % Legend for current delay
  leg_vec{i} = ['d = ', num2str(delay_vec(i))];
end

% Normalize frequency axis to pi
w = w / pi;

%% 5. Plotting Results

% Plot Magnitude Response
if plot_mag
  figure('Name', 'Magnitude')
  subplot(2, 1, 1)
    plot(w, mag2db(abs(Hf_mag)))
    grid on
    legend(leg_vec, 'Location', 'northeast')
    xlabel('Normalized Frequency \times \pi')
    ylabel('Magnitude [dB]')
    title('Magnitude Response (Full Band)')
  subplot(2, 1, 2)
    plot(w, mag2db(abs(Hf_mag)))
    grid on
    xlabel('Normalized Frequency \times \pi')
    ylabel('Magnitude [dB]')
    xlim([0, alpha])
    ylim([-1, 1] * 0.1)
    title('Magnitude Response (Zoomed)')
end

% Plot Group Delay Response
if plot_grpDelay
  figure('Name', 'Group Delay')
  subplot(2, 1, 1)
    plot(w, Hf_grpDel)
    grid on
    legend(leg_vec, 'Location', 'northeast')
    xlabel('Normalized Frequency \times \pi')
    ylabel('Group Delay [samples]')
    title('Group Delay')
  subplot(2, 1, 2)
    plot(w, Hf_grpDel - repmat(Hf_grpDel(1, :), nFFT, 1))
    grid on
    xlabel('Normalized Frequency \times \pi')
    ylabel('Group Delay Error [samples]')
    xlim([0, alpha])
    ylim([-1, 1] * 1)
    title('Group Delay Error (Zoomed)')
end

% Plot Phase Response
if plot_phase
  figure('Name', 'Phase')
  plot(w, Hf_ph)
  grid on
  legend(leg_vec, 'Location', 'northeast')
  xlabel('Normalized Frequency \times \pi')
  ylabel('Phase [radians]')
  title('Phase Response')
end

% --- Step 1: File Loading and Data Extraction ---
[filename, pathname] = uigetfile({'*.xlsx;*.xls','Excel Files (*.xlsx, *.xls)'}, ...
                                 'Select the Excel Data File');
if isequal(filename,0)
    disp('User canceled file selection.');
    return;
end

fullpath = fullfile(pathname, filename);
data = readtable(fullpath);

% Extract time, voltage, and current from the table
time = data{:,1};
voltage = data{:,2};
current = -data{:,3};
%current = data{:,3};
current = current / 1000;  % Convert mA to A
% current = current / 10000;  % Convert 1e-4A to A

% Extract ROI data (assuming they start from column 4)
roi_data = data{:, 4:end};
num_rois = size(roi_data, 2);


% --- Step 2: Setup Sampling and Frequency Parameters ---
dt = mean(diff(time));  % Average time step
Fs = 1/dt;             % Sampling frequency in Hz
L = length(time);      % Length of signal
f_axis = Fs*(0:(L/2))/L; % Frequency axis for plotting


% --- Step 3: Frequency Analysis of the Driving Signal (Voltage) ---
% We will use the voltage signal to find the primary frequency of the system.
Yv = fft(voltage);
Pv = abs(Yv/L);
Pv1 = Pv(1:L/2+1);
Pv1(2:end-1) = 2*Pv1(2:end-1);

% Find the peak frequency, skipping the DC component (at index 1)
[~, idx_peak] = max(Pv1(2:end));
idx_peak = idx_peak + 1; % Adjust index to match f_axis
driving_frequency = f_axis(idx_peak);

fprintf('System Driving Frequency: %.2f Hz\n', driving_frequency);


% --- Step 4: Calculate Amplitude and Phase of Voltage and Current ---
% A more robust way to get phase is directly from the FFT angle at the peak frequency

% For Voltage
amp_voltage = Pv1(idx_peak); % Amplitude from FFT
% The phase is the angle of the complex FFT coefficient at the peak frequency
phase_voltage_rad = angle(Yv(idx_peak)); 
phase_voltage_deg = rad2deg(phase_voltage_rad);

% For Current (analyzed AT THE SAME FREQUENCY as voltage)
Yi = fft(current);
Pi = abs(Yi/L);
Pi1 = Pi(1:L/2+1);
Pi1(2:end-1) = 2*Pi1(2:end-1);
amp_current = Pi1(idx_peak); % Amplitude at the driving frequency
phase_current_rad = angle(Yi(idx_peak));
phase_current_deg = rad2deg(phase_current_rad);

% Calculate the phase shift between current and voltage
%phase_shift_v_i = phase_current_deg - phase_voltage_deg;
phase_shift_v_i = -phase_current_deg + phase_voltage_deg;
% Wrap phase to be between -180 and 180 degrees
phase_shift_v_i = mod(phase_shift_v_i + 180, 360) - 180;

fprintf('Voltage: Amplitude = %.2f, Phase = %.2f deg\n', amp_voltage, phase_voltage_deg);
fprintf('Current: Amplitude = %.2f mA, Phase = %.2f deg\n', amp_current*1000, phase_current_deg);
fprintf('Impedance Phase (Volatge - Current): %.2f deg\n', phase_shift_v_i);


% --- Step 5: Process Each ROI Signal ---
% Pre-allocate tables/arrays to store results for efficiency
roi_results = table('Size', [num_rois, 4], ...
                    'VariableTypes', {'double', 'double', 'double', 'double'}, ...
                    'VariableNames', {'ROI_Number', 'Amplitude_Derivative', 'Phase_Derivative_deg', 'Phase_Shift_vs_Voltage_deg'});

% The derivative signal will have one less point than the original.
% Adjust the time vector once for all derivative calculations.
time_deriv = time(1:end-1) + dt/2; % Shift time to the midpoint of each diff interval
L_deriv = length(time_deriv);

for i = 1:num_rois
    roi_signal = roi_data(:, i);

    % ** CRITICAL STEP: Filter the signal BEFORE differentiating **
    % This reduces noise amplification. The cutoff frequency should be
    % slightly above your driving_frequency. E.g., 1.5 * driving_frequency.
    % Requires Signal Processing Toolbox.
    cutoff_freq = driving_frequency * 1.5;
    roi_filtered = lowpass(roi_signal, cutoff_freq, Fs);

    % Calculate the time derivative
    %roi_derivative = diff(roi_filtered) / dt;
     roi_derivative = -diff(roi_filtered) / dt;
    % Perform FFT on the derivative signal
    Y_deriv = fft(roi_derivative);
    P_deriv = abs(Y_deriv / L_deriv);
    P_deriv1 = P_deriv(1:floor(L_deriv/2)+1);
    P_deriv1(2:end-1) = 2*P_deriv1(2:end-1);

    % Find amplitude and phase at the DRIVING FREQUENCY
    % We need to find the index in the derivative's frequency axis that
    % corresponds to our driving_frequency.
    [~, idx_deriv_peak] = min(abs(f_axis(1:length(P_deriv1)) - driving_frequency));
    
    amp_deriv = P_deriv1(idx_deriv_peak);
    phase_deriv_rad = angle(Y_deriv(idx_deriv_peak));
    phase_deriv_deg = rad2deg(phase_deriv_rad);

    % Calculate phase shift relative to the voltage signal
    %phase_shift_roi_v = phase_deriv_deg - phase_voltage_deg;
    phase_shift_roi_v = - phase_deriv_deg + phase_voltage_deg;
    % Wrap phase to be between -180 and 180
    phase_shift_roi_v = mod(phase_shift_roi_v + 180, 360) - 180;
    
    % Store results
    roi_results.ROI_Number(i) = i;
    roi_results.Amplitude_Derivative(i) = amp_deriv;
    roi_results.Phase_Derivative_deg(i) = phase_deriv_deg;
    roi_results.Phase_Shift_vs_Voltage_deg(i) = phase_shift_roi_v;
end

% Display the results for all ROIs
disp('--- ROI Derivative Analysis Results ---');
disp(roi_results);

% Assume amp_roi_array is a 1x96 array of amplitudes

% Step 1: Reshape into 12 rows × 8 columns
amplitude_vector = roi_results{:, 2}; % Use column 2 for 'amplitude'

% Reshape the vector into a 12x8 matrix for plotting.
amp_matrix = reshape(amplitude_vector, [8, 12])'; % 12 rows, 8 cols


% Step 2: Plot using imagesc
figure('Color', 'w');  % Set figure background to white
imagesc(amp_matrix);
colormap(hot);
colorbar;
xlabel('ROI # within row (1–8)');
ylabel('Row index (1–12)');
title('Amplitude Map');
axis equal tight;
set(gca, 'XTick', 1:8, 'YTick', 1:12);

% Step 1: Reshape into 12 rows × 8 columns
phase_shift_vector = roi_results{:, 4}; % Use column 4 for 'phase_shift_'

% Reshape the vector into a 12x8 matrix for plotting.
phase_shift_matrix = reshape(phase_shift_vector, [8, 12])'; % 12 rows, 8 cols


% Step 2: Plot using imagesc
figure('Color', 'w');  % Set figure background to white
imagesc(phase_shift_matrix);
colorbar;
xlabel('ROI # within row (1–8)');
ylabel('Row index (1–12)');
title('ROI phase_shift Map');
axis equal tight;
set(gca, 'XTick', 1:8, 'YTick', 1:12);

writetable(roi_results, '21_1Hz_ampPhaseshift.xlsx');
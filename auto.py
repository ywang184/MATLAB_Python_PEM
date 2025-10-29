"""
Automatically process excel sheet for cyclic voltammetry.

Written by Alston Tang for Dr. Yixian Wang's Research Group.
"""

import pandas as pd
import numpy as np

import argparse, os, shutil
import matplotlib.pyplot as plt

boot_to_warmup_voltage_value_threshold = 0.125
scalar_voltage_difference_threshold = 0.785
cycle_identification_window_size = 7
buffer = 4
python_excel_index_offset = 2

calculated_kernel_for_cycle = np.array([1/cycle_identification_window_size for _ in range(cycle_identification_window_size)])

def process(args):
	sheet = pd.read_excel(args.filename)

	calculated_kernel_for_actual_data = np.array([1/args.size_moving_average for _ in range(args.size_moving_average)])

	# Get dt
	time_col = sheet[args.time_col_name].to_numpy()
	dt = np.diff(time_col)

	# 1. Filter rows
	voltage = sheet[args.volt_col_name].to_numpy()
	begin_index = 0
	end_index = len(time_col) - 1

	if not args.preprocessed:
		smoothed_voltage = np.convolve(voltage, calculated_kernel_for_cycle, mode="same")
		boot_voltage = smoothed_voltage[0]

		is_warming_up = False
		
		# Do for loop from start of array
		for i in range(len(voltage) - 1 - buffer):
			val = smoothed_voltage[i]
			begin_index = i
			if not is_warming_up and val > boot_voltage + boot_to_warmup_voltage_value_threshold:
				is_warming_up = True
			elif not is_warming_up: continue

			rate_of_changes = (np.diff(smoothed_voltage[i:i+1+buffer])/dt[i:i+buffer])
			max_roc = rate_of_changes.max()

			if max_roc <= -args.voltage*scalar_voltage_difference_threshold:
				for j in range(i+buffer, 0, -1):
					if (smoothed_voltage[j] - smoothed_voltage[j-1]) < 0:
						begin_index = j
					else:
						begin_index += cycle_identification_window_size // 2
						break
				break
		
		right_cool_down = True
		shutdown_voltage = smoothed_voltage[-1]

		# Do for loop from end of array to start. This allows logic to be easier to analyze (more commonality between the two loops).
		reversed = smoothed_voltage[::-1]
		reversed_dt = dt[::-1]
		for i in range(len(voltage) - 1 - buffer - begin_index):
			val = reversed[i]
			end_index = len(voltage) - i - 1

			if right_cool_down and val > shutdown_voltage + boot_to_warmup_voltage_value_threshold:
				right_cool_down = False
			elif right_cool_down: continue

			rate_of_changes = (np.diff(reversed[i:i+1+buffer])/reversed_dt[i:i+buffer])
			max_roc = rate_of_changes.max()

			if max_roc <= -args.voltage*scalar_voltage_difference_threshold:
				for j in range(i+buffer, 0, -1):
					diff = reversed[j] - reversed[j-1]

					if diff < 0:
						end_index = len(voltage) - j - 1
					else:
						end_index -= cycle_identification_window_size // 2
						break
				break

		assert not right_cool_down, "Code failed to find transition between cool down and completed cycles"

	# Before continuing, identify precise cycle start/ends.
	smoothed_voltage = np.convolve(voltage[begin_index:end_index + 1], calculated_kernel_for_cycle, mode="same")
	smoothed_voltage = np.convolve(smoothed_voltage, calculated_kernel_for_cycle, mode="same")
	smoothed_voltage_derivative = np.diff(smoothed_voltage)[:min(len(smoothed_voltage)-1, len(dt[begin_index:end_index]))]/dt[begin_index:end_index]
	sign = -1
	started = False
	isDown = True

	true_start = 0

	cycle_end_indices = []
	for i in range(len(smoothed_voltage_derivative)):
		smoothed_voltage_point = smoothed_voltage_derivative[i]
		if abs(smoothed_voltage_point) < args.voltage * 0.125: smoothed_voltage_point = 0

		derivative_sign = np.sign(smoothed_voltage_point)

		if not started and derivative_sign != -1: continue
		elif not started: # and derivative sign is -1 (begin fall)
			true_start = i
			started = True
			sign = derivative_sign

		if derivative_sign == sign or derivative_sign == 0: continue

		sign = derivative_sign
		if isDown:
			isDown = False
		else:
			isDown = True
			cycle_end_indices.append(i)

	for i in range(len(cycle_end_indices), args.cycle_count): # In case it fails to get the last cycle or whatever
		cycle_end_indices.append((i+1) * (end_index - begin_index)//args.cycle_count)

	true_end = cycle_end_indices[-1]

	begin_index += true_start
	end_index = true_end + begin_index

	if not args.no_prints:
		print(f"Identified starting index of {begin_index + python_excel_index_offset} and ending index of {end_index + python_excel_index_offset} for file {args.filename}")

	cycle_end_indices = cycle_end_indices[-args.cycle_count:]

	# Crop voltage before continuing
	voltage = voltage[begin_index:end_index]
	voltage_chunks = np.split(voltage, cycle_end_indices)

	# 2. Get AverageROI
	index = args.index
	roi_list = []
	while True:
		col_name = args.formatted_string.format(i=index)
		if not (col_name in sheet.columns):
			break
		roi_list.append(sheet[args.formatted_string.format(i=index)].to_numpy()[begin_index:end_index+1])
		index += 1

	roi_array = np.array(roi_list)
	del roi_list

	roi_average = roi_array.mean(axis=0)

	# 3. Get moving average of dSPR/dt (first we calculate dSPR/dt before doing moving average to the result, but code does it all in one line)
	roi_derivative = np.convolve(np.diff(roi_average)/dt[begin_index:end_index], calculated_kernel_for_actual_data, mode="same")
	roi_chunks = np.split(roi_derivative, cycle_end_indices)

	# 4. Filter current
	current = sheet[args.current_col_name].to_numpy()
	current = current[begin_index:end_index]

	current_chunks = np.split(current, cycle_end_indices)

	# 5. Iterate through each chunk
	data_out = {
		"Start Index": [],
		"End Index": [],
		"Max (dSPR/dt)": [],
		"Min (dSPR/dt)": [],
		f"Max ({args.current_col_name})": [],
		f"Min ({args.current_col_name})": [],
	}

	identifiers = []

	name, _ = os.path.splitext(args.filename)

	if not args.no_save_analysis:
		os.makedirs(name, exist_ok=True)

		for item in os.listdir(name):
			item_path = os.path.join(name, item)
			if os.path.isfile(item_path):
				os.remove(item_path)
			elif os.path.isdir(item_path):
				shutil.rmtree(item_path)

	if args.debug_voltage_data:
		plt.plot(time_col[begin_index:end_index], voltage)
		plt.suptitle("Voltage Data")
		plt.xlabel(args.time_col_name)
		plt.ylabel(args.volt_col_name)

		if args.preview_figures:
			plt.show()
		
		if not args.no_save_analysis:
			plt.savefig(f"{name}/voltage_data.png", dpi=300)
		
		plt.close()

		if args.preview_figures:
			plt.plot(time_col[begin_index:end_index], np.convolve(voltage, np.array([0.01] * 100), mode="same"))
			plt.suptitle("Voltage Data")
			plt.xlabel(args.time_col_name)
			plt.ylabel(args.volt_col_name)
			plt.show()
			plt.close()

	for i, (roi_derivative_cycle, current_cycle, voltage_chunk) in enumerate(zip(roi_chunks, current_chunks, voltage_chunks)):
		if len(roi_derivative_cycle) == 0 or len(current_cycle) == 0: break # The end but just in case numpy somehow returns a blank array

		identifiers.append(f"Cycle {i+1}")

		end_cycle_index = cycle_end_indices[i]
		start_cycle_index = end_cycle_index - len(current_cycle)

		corrected_start, corrected_end = 0, 0

		for j in range(0, len(voltage_chunk)):
			if voltage_chunk[j] < args.max_volt_for_data_analysis:
				corrected_start = j
				break

		for j in range(len(voltage_chunk)-1, -1, -1):
			if voltage_chunk[j] < args.max_volt_for_data_analysis:
				corrected_end = j
				break
		
		start_cycle_index += corrected_start
		end_cycle_index -= len(voltage_chunk) - corrected_end

		if corrected_end == 0:
			roi_derivative_cycle, current_cycle, voltage_chunk = roi_derivative_cycle[corrected_start:], current_cycle[corrected_start:], voltage_chunk[corrected_start:]
		else:
			roi_derivative_cycle, current_cycle, voltage_chunk = roi_derivative_cycle[corrected_start:corrected_end], current_cycle[corrected_start:corrected_end], voltage_chunk[corrected_start:corrected_end]
		

		data_out["Start Index"].append(begin_index + start_cycle_index + python_excel_index_offset)
		data_out["End Index"].append(begin_index + end_cycle_index - 1 + python_excel_index_offset)
		data_out["Max (dSPR/dt)"].append(max(roi_derivative_cycle))
		data_out["Min (dSPR/dt)"].append(min(roi_derivative_cycle))
		data_out[f"Max ({args.current_col_name})"].append(max(current_cycle))
		data_out[f"Min ({args.current_col_name})"].append(min(current_cycle))

		if not args.preview_figures and args.no_save_analysis: continue

		fig, axes = plt.subplots(1,2, figsize=(8, 4))

		if len(voltage_chunk) == len(roi_derivative_cycle) + 1: # Derivative is inevitably going to cause size incompatability if doing pre-processed.
			roi_derivative_cycle = np.append(roi_derivative_cycle, 0)

		axes[0].plot(voltage_chunk, roi_derivative_cycle, linewidth=0.8)
		axes[0].set_xlabel(args.volt_col_name)
		axes[0].set_ylabel("dSPR/dt")

		axes[1].plot(voltage_chunk, current_cycle, linewidth=0.8)
		axes[1].set_xlabel(args.volt_col_name)
		axes[1].set_ylabel(args.current_col_name)

		plt.suptitle(f"Cycle {i+1}")
		fig.tight_layout()

		if args.preview_figures:
			plt.show()
		
		if not args.no_save_analysis:
			plt.savefig(f"{name}/Cycle{i+1}.png", dpi=300)
		plt.close()

	df = pd.DataFrame(data_out, index=identifiers)
	if not args.no_save_analysis:
		df.to_excel(f"{name}/Cycle_Data.xlsx")

	if not args.no_prints: print(f"{name}:\n", df)

	return name, df

def safe_process(args):
	try:
		return process(args)
	except Exception as e:
		print(f"{args.filename} had an error: {e}")
		return args.filename, None

parser = argparse.ArgumentParser(
	prog="auto.py",
	description="Automatically parses SPRM Excel Spreadsheet. Assumes some basic formatting rules (first row should be column names, data should be SPRM data, etc.), but otherwise tries to automatically handle the warmup and cooldown sequences and automatically does figure generation and data analysis of the cyclic voltammagram.",
)

parser.add_argument("-f", "--filename", help="The name/directory to the file you want to parse", required=True)
parser.add_argument("-v", "--voltage", help="Intended change in voltage.", type=float, required=True)
parser.add_argument("-c", "--cycle_count", help="Number of cycles expected.", type=int, required=True)
parser.add_argument("-s", "--size_moving_average", help="Number of data points for moving average.", type=int, required=True)
parser.add_argument("--time_col_name", help="Name of the time column in the sheet.", default="Time (s)")
parser.add_argument("--volt_col_name", help="Name of the voltage column in the sheet.", default="Vec (V)")
parser.add_argument("--current_col_name", help="Name of the current column in the sheet.", default="Iec (mA)")
parser.add_argument("--max_volt_for_data_analysis", help="Maximum voltage to consider for figure generation and min/max data. Note that anything at or above this value will not be considered.", type=float, default=float('inf'))
parser.add_argument("--formatted_string", help="Formatted string for the ROI columns. Example: If the column names look something like 'Roi1 (%%), Roi2 (%%), ...', then the argument would be 'Roi{i} (%%)'. Be sure to appropriately set the starting ROI index using --index [INDEX]", default="Roi{i} (%)")
parser.add_argument("--index", help="Starting index for the ROI prefix. Default is 1. Refer to --formatted_string help for details", default=1, type=int)
parser.add_argument("--preprocessed", help="Flag to determine whether the sheet has already filtered the warmup and cooldown phase.", action="store_true")
parser.add_argument("--preview_figures", help="Flag to determine whether to preview figures.", action="store_true")
parser.add_argument("--no_save_analysis", help="Flag to determine whether to NOT save the analysis done.", action="store_true")
parser.add_argument("--no_prints", help="Flag to determine whether to NOT print anything.", action="store_true")
parser.add_argument("--debug_voltage_data", help="Flag to determine whether to make plot of voltage versus time data.", action="store_true")

if __name__ == "__main__":
	args = parser.parse_args()
	process(args)
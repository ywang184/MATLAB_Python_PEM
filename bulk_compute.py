"""
Code that uses auto.py to parse a folder holding folders with excel files. Uses ProcessPoolExecutor to process files in parallel.

At the end it also makes one large excel file of all the key max/min info for each cycle in each sheet.

Written by Alston Tang for Dr. Yixian Wang's Research Group.
"""

import auto, re, sys, os
import pandas as pd
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor

# Here the data output for these specific filenames is such that we take the data from rows only if the voltage is less than 0.6
override_voltage_naught_point_six = ["7_TS_1MKNO3_0.05V_2cycles", "8_TS_1MKNO3_0.02V_1cycle", "8_TS_1MKNO3_0.05V_2cycles_T2"]

if __name__ == "__main__":
	root_path = Path(sys.argv[1])
	arguments = []

	for item in root_path.iterdir():
		if not (item.is_dir() and item.name != "__pycache__"): continue
		print(f"Processing data in subfolder: {item.name}")
		
		for file_path in item.iterdir():
			if not (file_path.is_file() and file_path.suffix == ".xlsx"): continue
			print(f"	Found file: {file_path.name}! ", end="") # Tab character to show hierarchy

			find = re.search(rf"(-?\d+\.?\d*){re.escape("vs_")}", file_path.name.lower())
			if not find:
				find = re.search(rf"(-?\d+\.?\d*){re.escape("v_")}", file_path.name.lower())
				if not find:
					print("Could not infer voltage from name! Skipping...")
					continue

			voltage = float(find.group(1))

			find = re.search(rf"(-?\d+){re.escape("cycle")}", file_path.name.lower())
			if not find:
				print("Assuming cycle is 1. ", end="")
				cycles = 1
			else:
				cycles = int(find.group(1))

			isManual = (file_path.name.lower().find("manual_preprocessed_filtered") != -1)

			config_dict = {
				"filename": file_path,
				"voltage": voltage,
				"cycle_count": cycles,
				"size_moving_average": 10,
				"no_prints": None,
				"debug_voltage_data": None
			}

			if isManual:
				print("Assumed that the data is preprocessed. ", end="")
				config_dict["preprocessed"] = None

			for prefix in override_voltage_naught_point_six:
				if file_path.name.find(prefix) != -1:
					print("Triggered to set max voltage info to 0.6! ", end="")
					config_dict["max_volt_for_data_analysis"] = 0.6
					break

			args_list = []
			for key, value in config_dict.items():
				args_list.append(f"--{key}")
				if value is not None: args_list.append(str(value))

			args = auto.parser.parse_args(args_list)
			arguments.append(args)
			print("Added!")

	dataframes = {}

	with ProcessPoolExecutor(max_workers=max(os.cpu_count() - 1, 1)) as executor:
		results = executor.map(auto.safe_process, arguments)

		for (name, final_data_frame) in results:
			if final_data_frame is not None:
				print(f"Processed {name}!")
				dataframes[name] = final_data_frame

	combined = pd.concat(dataframes, axis=0)
	combined = combined.reset_index()
	combined = combined.rename(columns={"level_0": 'Original_Sheet', "level_1": "Cycle"})

	is_first_ref_to_df_name = combined['Original_Sheet'].shift() != combined['Original_Sheet']
	combined['Original_Sheet'] = combined['Original_Sheet'].where(is_first_ref_to_df_name, other="")

	combined.to_excel(f"{str(root_path.resolve(True))}/Cycle_Data.xlsx")
	print(combined)
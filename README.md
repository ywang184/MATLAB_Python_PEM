# Auto Cycle Analysis
Automatically take in Excel spreadsheet, finds cycle start/end indices, and generate figures and extract min/max data for the current data and the region of interest data.

## Requirements
Python 3.13
- This is the version used when running the code on the author's machine on Windows 11. Note that a lower version of Python will most likely work (probably even as low as Python 3.9), though the newest version is recommended.

Pandas, Numpy, and Matplotlib
- Run the following command to install in one go: `pip install pandas numpy matplotlib`

## Usage
### auto.py
To parse a single spreadsheet, use the following command:
- `python auto.py [-h] -f FILENAME -v VOLTAGE -c CYCLE_COUNT -s SIZE_MOVING_AVERAGE [--time_col_name TIME_COL_NAME] [--volt_col_name VOLT_COL_NAME] [--current_col_name CURRENT_COL_NAME] [--max_volt_for_data_analysis MAX_VOLT_FOR_DATA_ANALYSIS] [--formatted_string FORMATTED_STRING] [--index INDEX] [--preprocessed] [--preview_figures] [--no_save_analysis] [--no_prints] [--debug_voltage_data]`
    - Any argument surrounded in brackets are optional and are not strictly needed for analysis.
    - Example usage: `python auto.py -f 1_MS_07192024_2MKNO3_0.1vs_8cycles.bi.xlsx -v 0.1 -c 8 -s 10`
        - Here we specify that the change in voltage with respect to time should be 0.1, that there are 8 cycles, and that the moving average size to be applied to the dSPR/dt data is 10.

For more details on the options/input parameters, see here:
```
  -h, --help            show this help message and exit
  -f, --filename FILENAME
                        The name/directory to the file you want to parse
  -v, --voltage VOLTAGE
                        Intended change in voltage.
  -c, --cycle_count CYCLE_COUNT
                        Number of cycles expected.
  -s, --size_moving_average SIZE_MOVING_AVERAGE
                        Number of data points for moving average.
  --time_col_name TIME_COL_NAME
                        Name of the time column in the sheet.
  --volt_col_name VOLT_COL_NAME
                        Name of the voltage column in the sheet.
  --current_col_name CURRENT_COL_NAME
                        Name of the current column in the sheet.
  --max_volt_for_data_analysis MAX_VOLT_FOR_DATA_ANALYSIS
                        Maximum voltage to consider for figure generation and min/max data. Note that anything at or above this value will not be considered.
  --formatted_string FORMATTED_STRING
                        Formatted string for the ROI columns. Example: If the column names look something like 'Roi1 (%), Roi2 (%), ...', then the argument would be 'Roi{i} (%)'. Be sure to appropriately set the starting ROI index using --index [INDEX]
  --index INDEX         Starting index for the ROI prefix. Default is 1. Refer to --formatted_string help for details
  --preprocessed        Flag to determine whether the sheet has already filtered the warmup and cooldown phase.
  --preview_figures     Flag to determine whether to preview figures.
  --no_save_analysis    Flag to determine whether to NOT save the analysis done.
  --no_prints           Flag to determine whether to NOT print anything.
  --debug_voltage_data  Flag to determine whether to make plot of voltage versus time data.
```
- Remark: `-f/--filename` must be the path to the file. Exact path is recommended (like `C:\Users\...`).
- Remark 2: `--formatted_string` must be a Python formatted string literal (f-string).
- Remark 3: `-v/--voltage` should be specified as the expected voltage change in *1 second* (change in voltage with respect to time).

The output of the code first makes a new folder that has the same name as the input sheet (without the extension), then inside the folder it includes the cycle data, the cycle figures, and optionally, the voltage data.

--- 

Sometimes, however, you may have a lot of Excel files you wish to parse. Provided that the file naming conventions are well-structured (like "1_MS_07192024_2MKNO3_0.1vs_8cycles.bi.xlsx"), you may wish to use `bulk_compute.py`

---

### bulk_compute.py
To parse a folder of folders containing spreadsheets, run `python bulk_compute.py [PATH_TO_FOLDER]`
- Example: `python bulk_compute.py C:\Path\To\Your\Data`

The root folder should look something like the following:
```
Your_Data_Folder
├───Folder_1
│   ├───Some_Name_0.02Vs_2cycles
│   ├───Some_Other_Name_0.05Vs_4cycles
│   └───Descriptive_Thing_0.05Vs_4cycles
├───Folder_2
    ├───Name_0.05Vs_4cycles
    └───Anything_0.05Vs_4cycles_Anything_after
```

Notice the well-structured naming convention, where the voltage data and the cycle information is obvious.

After running the code, you will notice another excel file within the root folder of folders. That contains all the key data information (min/max information) aggregated to include data from all sheets. This can be helpful if you do not wish to view through many excel files associated with each data point/sheet.

Since the code for bulk_compute.py was mainly for data analysis for Dr. Yixian Wang's research group, you may wish to edit the file to suit your lab's naming conventions.
import sys
import glob
import re
import os
import pandas as pd
import time

# sys.argv[0] is the script name, sys.argv[1] is the first argument
if len(sys.argv) > 1:
    argument = sys.argv[1]  # Get the first argument
    print(f"\nYou passed: {argument}\n")
else:
    print("No directory provided!")
    sys.exit(1)

    
# Check if you are in the correct directory
directory = argument

if not os.path.exists(directory):
    print(f"Error: Directory '{directory}' does not exist.")
    sys.exit(1)

if directory.endswith("nb_analysis"):
    print("You are in the nb_analysis subdirectory.\n")
else:
    print("You are NOT in nb_analysis. Change the directory.")
    sys.exit(1)


# Get all matching files
os.chdir(directory)  # Change to the subdirectory
files = glob.glob(os.path.join(directory,"avg-*-*.dat"))

if len(files) < 19701:
    print("Error: Not enough files! Exiting script.")
    sys.exit(1)  # Exit with a non-zero status (indicating an error)
else:
    print("Correct number of files. Proceeding with script...\n")
    

def extract_residue(name):
    return name.split('_')[1].split('@')[0]

pairwise_all = pd.DataFrame(columns=['res_pair','EVDW', 'EELEC'])
pairwise_inter = pd.DataFrame(columns=['res_pair','EVDW', 'EELEC'])

# Iterate through all pairwise nonbonded files (19701 files total)
for file in files:
   # Read file
    with open(file, "r") as f:
        lines = f.readlines()

        # Create DataFrame from the lines
        data = [line.strip().split() for line in lines]  # Adjust split logic if needed
        avg_df = pd.DataFrame(data)

        # Drop unnecessary columns (2, 5, 6, 8 are dropped here, adjust if necessary)
        avg_df = avg_df.drop(avg_df.columns[[2, 5, 6, 8]], axis=1)
        avg_df.columns = ['name1', 'atom1', 'name2', 'atom2', 'EVDW', 'EELEC']

        # Remove the first row and reset index
        avg_df = avg_df.iloc[1:]  # Keeps all rows except the first
        avg_df.reset_index(drop=True, inplace=True)  # Resets the index

        avg_df["EVDW"] = pd.to_numeric(avg_df["EVDW"], errors='coerce')
        avg_df["EELEC"] = pd.to_numeric(avg_df["EELEC"], errors='coerce')

        # Assuming extract_residue is defined elsewhere
        avg_df["res1"] = avg_df["name1"].apply(extract_residue)
        avg_df["res2"] = avg_df["name2"].apply(extract_residue)
        avg_df["res_pair"] = avg_df.apply(lambda row: f"v{row['res1']}-v{row['res2']}", axis=1)
        
        # Assuming df is your DataFrame
        filtered_sum = avg_df[avg_df["res1"] != avg_df["res2"]].copy()
        filtered_sum["res_pair"] = filtered_sum.apply(lambda row: f"v{row['res1']}-v{row['res2']}", axis=1)
        # Sum the values while keeping the res_pair information
        filtered_result = filtered_sum.groupby("res_pair")[["EVDW", "EELEC"]].sum().reset_index()
        
        pairwise_inter = pd.concat([pairwise_inter, filtered_result], ignore_index=True)
        
        #print(avg_df[["EVDW","EELEC"]]).mean()
        
        avg_values = pd.DataFrame(avg_df[["EVDW","EELEC"]].sum()).transpose()
        res_pair = pd.DataFrame(filtered_result["res_pair"])
        res_pair.columns = ["res_pair"]  # Explicitly set column name

        final_avg_values = pd.concat([res_pair, avg_values], axis=1)#, ignore_index=True)
        pairwise_all = pd.concat([pairwise_all, final_avg_values], ignore_index=True)

pairwise_inter.set_index("res_pair", inplace=True)
pairwise_inter = pairwise_inter.sort_values(by="res_pair")
pairwise_inter.to_csv("pairwise_inter.csv")
pairwise_all.set_index("res_pair", inplace=True)
pairwise_all = pairwise_inter.sort_values(by="res_pair")
pairwise_all.to_csv("pairwise_all.csv")


final_dir = os.getcwd()

print(f"Done.\n") 

print(f"csv files written to {final_dir}\n") 


#This code takes a pdb as input, remove SO4, change the ligand name and chain to "LIG C", and change the water chain (HOH or WAT) to "Z". Then sort the block of inputs alphabetically. Finally, after applying pdb4amber, save the complex with adding a "p" at the end of the name and save the ligand as lig.pdb. Use it as ./prep.sh input.pdb


#!/bin/bash

# Check if the script was provided with exactly one argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 input.pdb"
    exit 1
fi

# Assign the input PDB file to a variable
input_file="$1"

# Generate the output file name based on the input file name
output_file="${input_file%.pdb}-p.pdb"

# Use awk to process the input PDB file and filter/modify the contents
awk '
    # Print lines that start with "ATOM" unchanged
    /^ATOM/ {
        print
    }

    # Process lines that start with "HETATM" and are not "SO4", "HOH", or "WAT"
    /^HETATM/ && substr($0, 18, 3) != "SO4" && substr($0, 18, 3) != "HOH" && substr($0, 18, 3) != "WAT" && substr($0, 18, 3) != "PO4" && substr($0, 18, 3) != "ACT" && substr($0, 18, 3) != "BME" && substr($0, 18, 2) != "CL" && substr($0, 18, 3) != "GOL" {
        print substr($0, 1, 17) "LIG C" substr($0, 23)
    }

    # Process lines that start with "HETATM" and are "HOH" or "WAT"
    /^HETATM/ && (substr($0, 18, 3) == "HOH" || substr($0, 18, 3) == "WAT") {
        print substr($0, 1, 17) "HOH Z" substr($0, 23)
    }
' "$input_file" > "$output_file"  # Redirect output to the output file

# Extract lines containing "LIG C" from the output file and save them in lig.pdb
grep "LIG C" "$output_file" > lig.pdb

# Create a temporary file name
temp_file="$output_file-temp"

# Split the output file into separate files based on the chain identifier (column 5, which is character 22)
awk '/^(ATOM|HETATM)/ { print >> substr($0, 22, 1)".pdb" }' "$output_file"

# Loop through chain files and append them to the temporary file
for chain_file in [A-Z].pdb; do
    if [ -e "$chain_file" ]; then
        cat "$chain_file" >> "$temp_file"
        rm "$chain_file"
    fi
done

# Run the pdb4amber command on the temporary file and save the output to the output file
pdb4amber -i "$temp_file" -o "$output_file" 

# Remove the temporary file
rm -f "$temp_file" "${output_file%.pdb}_sslink" "${output_file%.pdb}-temp" "${output_file%.pdb}_nonprot.pdb" "${output_file%.pdb}_renum.txt"

# Print a message indicating the completion of the modifications
echo "Modified pdb file saved as: $output_file and ligand saved as lig.pdb"




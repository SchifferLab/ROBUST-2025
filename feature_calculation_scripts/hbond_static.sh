#This code calculates the pairwise vdw and electrostatic interactions within a range of residues. It outputs 2 csv files called vdw-interactions.csv and elec-interactions.csv. The trajectory must have box information not removed. 
#provide topology, trajectory, first and last residue number as input (Usage: ./hbond_LI.sh <topology_file> <trajectory_file>). for example: ./hbond_LI.sh comp.prmtop 11md-2.dcd
#To analyze a single pdb structure, you need to prepare comp.prmtop and comp.inpcrd out of it : ./nonbonded.sh comp.prmtop comp.inpcrd 1 5

#!/bin/bash

# Check if all required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <topology_file> <trajectory_file>"
    exit 1
fi

# Read command-line arguments
topology_file=$1
trajectory_file=$2

mkdir hbond_analysis_static -p

hbond_command="hbond all_hbonds out hbond_analysis_static/hbond.dat avgout hbond_analysis_static/hbond_avg.dat \
solventacceptor :WAT@O solventdonor :WAT \
solvout hbond_analysis_static/solvent_avg.dat bridgeout hbond_analysis_static/bridge.dat \
series uuseries hbond_analysis_static/uuhbonds.agr uvseries hbond_analysis_static/uvhbonds.agr"
 
 
echo -e "parm $topology_file\ntrajin $trajectory_file\n$hbond_command" | cpptraj && echo "Cpptraj completed successfully."



echo -e "\n\nHbond analysis completed."
echo -e "\n\n"


#This code calculates the pairwise vdw and electrostatic interactions within a range of residues. It outputs 2 csv files called vdw-interactions.csv and elec-interactions.csv. The trajectory must have box information not removed. 
#provide topology, trajectory, first and last residue number as input (Usage: ./nonbonded.sh <topology_file> <trajectory_file> <start_res> <end_res>). for example: ./nonbonded.sh comp.prmtop 11md-2.dcd 1 5
#To analyze a single pdb structure, you need to prepare comp.prmtop and comp.inpcrd out of it : ./nonbonded.sh comp.prmtop comp.inpcrd 1 5

#!/bin/bash

start=`date +%s`

# Check if all required arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 <topology_file> <trajectory_file> <start_res> <end_res>"
    exit 1
fi


# Read command-line arguments
topology_file=$1
trajectory_file=$2
start_res=$3
end_res=$4


mkdir nb_analysis/lig_interactions -p

nb_analysis_dir="$(pwd)/nb_analysis"

# Run Python script
echo "Checking path to input files..."

python3 /home/dexter/Desktop/lauren/MASTER_amber/transformers/check_files.py $nb_analysis_dir

echo "Path confirmed."

# Generate cpptraj commands
cpptraj_commands=""
for ((i=$start_res; i<=$end_res-1; i++)); do
  for ((j=$i+1; j<=$end_res; j++)); do
    pairwise_outfile="nb_analysis/.pairwise-${i}-${j}.txt"
    avg_outfile="nb_analysis/avg-${i}-${j}.dat"
    vmap_outfile="nb_analysis/.map.elec.${i}-${j}.gnu"
    emap_outfile="nb_analysis/.map.vdw.${i}-${j}.gnu"
    cpptraj_commands+="pairwise :$i,$j out $pairwise_outfile avgout $avg_outfile vmapout $vmap_outfile emapout $emap_outfile printmode or cuteelec 0.0 cutevdw 0.0\n"

  done
done

echo -e $cpptraj_commands > cpptraj_commands.out

echo -e "parm $topology_file\ntrajin $trajectory_file\n$cpptraj_commands" | cpptraj && echo "Cpptraj completed successfully."
wait


# Run Python script
echo "\nRunning Python script..."

python3 /home/dexter/Desktop/lauren/MASTER_amber/transformers/nb_analysis.py $nb_analysis_dir

echo "Python script execution complete."
wait

cd nb_analysis/

# Move files containing "199" in the name
mv *199*.dat lig_interactions/

# Delete all other .dat files
rm .pairwise*txt
rm avg*dat
rm .map*


end=`date +%s`

runtime=$((end-start))

echo -e "\nIntermediate files deleted. Ligand pairwise interations moved to lig_interactions sub directory."

echo -e "\nTime to complete nonbonded analysis: ${runtime}\n\n"

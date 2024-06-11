set polymer_path ../PES-185/PES-185/Cooling
set script_path ../../../../Gyr_radius/   ;#relative to Cool_p_i folder
# Set the number of polymer chains
set N 8
set pressures {14000 26000 38000 44000}
set I 3    ; #number of calculations at each pressure + 1
set out_name PES_185 

# Function to get atomic weights
proc get_atomic_weight {element} {
	switch -- $element {
		"H" { return 1.008 }
		"C" { return 12.011 }
		"N" { return 14.007 }
		"O" { return 15.999 }
		"P" { return 30.974 }
		"S" { return 32.06 }
		default { return 0.0001 }
	}
}

# List to store data
set results {}

foreach pressure $pressures {
    for {set i 1} {$i < $I} {incr i} {
		cd $polymer_path
        cd Cool_${pressure}_${i}/
        topo readlammpsdata cooling_${pressure}_${i}.data full

		# List to store gyration radii for all chains in the current frame
		set gyration_radii_list {}

		# Output the results
		cd $script_path

		# Iterate over all chains
		for {set chain 0} {$chain < $N} {incr chain} {
			# Create a selection for the current chain
			set sel [atomselect top "residue $chain"]

			# Get the elements of the atoms in the selection
			set elements [$sel get element]

			# Create a list of atomic weights
			set weights {}
			foreach element $elements {
				lappend weights [get_atomic_weight $element]
			}

			# Calculate the radius of gyration with weights
			set rg [measure rgyr $sel weight $weights]

			# Append the radius of gyration to the list
			lappend gyration_radii_list $rg
			
			# Delete the selection
			$sel delete
		}	
		
		# Create a string with pressure, i, and the radii separated by tabs
		set result_str "$pressure\t$i\t[join $gyration_radii_list "\t"]"
		
		# Append the result string to the results list
		lappend results $result_str
	}
}

# Write all results to the output file
set outfile [open "$out_name.dat" "w"]
puts $outfile "Pressure\tNum_sim\tChains"
foreach result $results {
	puts $outfile $result
}
close $outfile


set id [molinfo list]
foreach id $id {
	mol delete $id
}
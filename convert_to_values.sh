tail -n +2 $1 | \
while read line
do
	sc=$(echo $line | cut -f1 -d,)
	min=$(echo $line | cut -f2 -d,)
	max=$(echo $line | cut -f3 -d,)
	echo '	SSREPI_value "'$sc'" \
		--contained_in=figure3.pdf \
		--variable=$var_scenario_id' 
	echo '	SSREPI_value '$min' \
		--contained_in=figure3.pdf \
		--variable=$var_min_incentive_id' 
	echo '	SSREPI_value '$max' \
		--contained_in=figure3.pdf \
		--variable=$var_max_incentive_id' 
done


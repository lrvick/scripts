#!/bin/bash

# Yellow Pages 2 CSV V2
#
# This was written after YellowPages overhauled their site in 2008. This mar or may not work with their current site but it worked for a client I had at the time.
#
# Consider it here for reference. I also can not condone using this script as it mar or may not violate laws or TOS or something else to make people unhappy.
#
# Written by me (Lance Reagan Vick) with some regex ninja-ing help from David T. Pflug.

category="Food"

search_terms="mcdonalds"

states="AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY"

for state in $states ; do
    lastpage=$(elinks -dump "http://anywho.yellowpages.com/${state}/${category}?search_terms=${search_terms}&page=1" | sed -ne 's/.*page\=\([[:digit:]]\+\).*/\1/p' | tail -n 1)
    echo "Last page for state ${state} is ${lastpage}."
    for ((page=1;page<=${lastpage};page+=1)) ; do
        sleeptime=$(($RANDOM % 15))
        echo "Beginning sleep for ${sleeptime}."
	sleep $sleeptime
	echo "Starting page ${page} for state ${state}."
        elinks -dump "http://anywho.yellowpages.com/${state}/${category}?search_terms=${earch_terms}&page=$page" | egrep -B5 '\([[:digit:]]{3}\) ' | sed '/^\w*$/d' | tr '\n' ' ' | sed -e '/Map/!d' -e 's#--#\n#g' -e 's/        /, /g' | grep -v "Serving the" | sed -e 's/ *\[[[:digit:]]\+\]\(.*\) \[[[:digit:]]\+\]Map,    \* \(.*$\)/\1, \2/' | grep -v "*" | sed "s/${state}/${state},/g" >> addresses_${state}.csv
    done
done

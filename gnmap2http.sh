#!/bin/bash

inputFile=$(realpath $1)
webtmp1="./.webtmp1"
webtmp2="./.webtmp2"
webtmp3="./.webtmp3"
csvfile="./.csvfile"

if ! test -f $inputFile; then
    echo "File does not exist."
    exit 0
fi

while read line; do
    checkport=$(echo $line | grep -e '/open/' -e '/closed')
    if [ "$checkport" != "" ]; then
        host=$(echo $line | awk '{print $2}')
        lineports=$(echo $line | awk '{$1=$2=$3=$4=""; print $0}')
        if [ -f $webtmp1 ]; then rm $webtmp1; fi
        echo "$lineports" | tr "," "\n" | sed 's/^ *//g' >> $webtmp1
        while read templine; do
            checkport2=$(echo $templine | grep -e '/open/' -e '/closed')
            if [ "$checkport2" != "" ]; then
                port=$(echo $templine | awk -F '/' '{print $1}')
                status=$(echo $templine | awk -F '/' '{print $2}')
                protocol=$(echo $templine | awk -F '/' '{print $3}')
                service=$(echo $templine | awk -F '/' '{print $5}')
                version=$(echo $templine | awk -F '/' '{print $7}')
                echo "$host,$port,$status,$protocol,$service,$version" >> $webtmp2
            fi
        done < $webtmp1
    fi
done < $inputFile

cat $webtmp2 | sort -u | sort -t"," -n -k1 | sort -V >> $csvfile
sed -i '/,closed,/d' $csvfile

for line in $(cat $csvfile); do
    host=$(echo $line | awk -F ',' '{print $1}')
    port=$(echo $line | awk -F ',' '{print $2}')
    service=$(echo $line | awk -F ',' '{print $5}')
    version=$(echo $line | awk -F ',' '{print $6}')

    if [ "$port" = "80" ]; then echo "${host}:$port" >> $webtmp3; fi
    if [ "$port" = "443" ]; then echo "${host}:$port" >> $webtmp3; fi
    if [ "$port" = "8080" ]; then echo "${host}:$port" >> $webtmp3; fi
    if [ "$port" = "8443" ]; then echo "${host}:$port" >> $webtmp3; fi
    if [ "$service" = "http" ]; then echo "${host}:$port" >> $webtmp3; fi
    if [[ "$service" == *"ssl"* ]]; then echo "${host}:$port" >> $webtmp3; fi
    if [[ "$version" == *"Web"* ]]; then echo "${host}:$port" >> $webtmp3; fi
    if [[ "$version" == *"web"* ]]; then echo "${host}:$port" >> $webtmp3; fi
done

sort -u $webtmp3

rm -f $csvfile $webtmp3 $webtmp2 $webtmp1 > /dev/null 2>&1

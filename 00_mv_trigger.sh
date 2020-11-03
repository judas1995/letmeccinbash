#!/bin/bash
# Author:Henry
#Date & Time: 2020-11-03 19:11:00
#Description:

######計時用######
TIME_ELAPSE_a=$(date --date="now" +%s)
######計時用######

data_path=../data
tmp_path=../tmp
output_path=../output

whereweare=$(pwd)

dir=test
tmp_01=00.01.tmp

###紀錄事件數量以及特徵名字###
ls $data_path/$dir/*.bp | gawk -F"." '{print $7"."$8"."$9"."$10"."$11}' | sort | uniq -c >$tmp_path/$tmp_01

ENDZ_loop=$(gawk 'END{print NR}' $tmp_path/$tmp_01)
Z_loop=$(gawk '{print NR}' $tmp_path/$tmp_01)
for z in $Z_loop; do

    event_name=$(gawk 'NR=='$z'{print $2}' $tmp_path/$tmp_01)

    cp $data_path/$dir/*$event_name $data_path/

    echo "bash ./new-version-clear.sh"
    #bash ./new-version-clear.sh

    echo "$z/$ENDZ_loop"

    rm $data_path/*bp
done

######計時用######
TIME_ELAPSE_b=$(date --date="now" +%s)
TIME_ELAPSE=$(($TIME_ELAPSE_b - $TIME_ELAPSE_a))
echo "花費時間: $TIME_ELAPSE 秒"
######計時用######

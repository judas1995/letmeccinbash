#!/bin/bash
# Author:Henry
#Date & Time: 2020-09-28 11:11:20
#Description:

######計時用######
TIME_ELAPSE_a=$(date --date="now" +%s)
######計時用######

whereweare=$(pwd)

data_path=../data     
tmp_path=../tmp
output_path=../output
output_file_01=Moon_out.txt

tmp_file01=tmp_file01_tmp.txt
tmp_file02=tmp_file02_tmp.txt
tmp_file03=tmp_file03_tmp.txt
tmp_file04=tmp_file04_tmp.txt
tmp_file05=tmp_file05_tmp.txt


#定義資料位置(bp是建立在我拿的資料如果已經band pass過後)
#這是測試2號
ls $data_path/*bp >$tmp_path/$tmp_file04

#tr
#ls $data_path/waveform_test/tremor/tremor/ -d >  $tmp_path/$tmp_file04

#1 before10_10 2 clean_EQ 3 noise 4 noise_EQ 5 tremor
#Z_loop=`gawk 'NR==1{print NR}' $tmp_path/$tmp_file04`
Z_loop=$(gawk 'NR==3{print NR}' $tmp_path/$tmp_file04)
for z in $Z_loop; do
    log_tmp_01=$(gawk -F"/" 'NR=='$z'{print $5}' $tmp_path/$tmp_file04)
    path_01=$(gawk 'NR=='$z'{print $1"*"}' $tmp_path/$tmp_file04)
    #ls $path_01 |gawk -F"." '{print $10"."$11"  '$log_tmp_01'"}'|sort|uniq
    ls $path_01 | gawk -F"." '{print $10"."$11"  '$log_tmp_01'"}' | sort | uniq >$tmp_path/$tmp_file05

    Y_loop=$(gawk 'NR==3{print NR}' $tmp_path/$tmp_file05)
    #Y_loop=`gawk '{print NR}' $tmp_path/$tmp_file05`
    for y in $Y_loop; do
        event_number=$(gawk 'NR=='$y'{print $1}' $tmp_path/$tmp_file05)

        echo "cp $path_01$event_number $data_path $log_tmp_01"

        cp $path_01$event_number $data_path

        if [ 1 == 1 ]; then

            ########以下程式碼勿動letmebashcc main code########

            #ls $data_path/*300sec > $tmp_path/$tmp_file01

            #sac
            echo "r $data_path/*bp ; rtr; rmean; envelope; lp co 0.2 p 2; w append .lp; q;" | sac >/dev/null 2>&1

            echo "r $data_path/*bp ; rtr; rmean; envelope; lp co 0.2 p 2; sqr; w append .sqr; q;" | sac >/dev/null 2>&1

            saclst B DEPMEN DEPMAX f $data_path/*.lp >$tmp_path/$tmp_file02

            saclst B DEPMEN DEPMAX f $data_path/*.sqr >$tmp_path/$tmp_file02.sqr

            ls $data_path/*.sqr >$tmp_path/$tmp_file01.sqr

            ls $data_path/*.lp >$tmp_path/$tmp_file01
            cp $tmp_path/$tmp_file01 $tmp_path/$tmp_file01.copy

            sed -i 's/\//\\\//g' $tmp_path/$tmp_file01

            moa_tmp=mmttmp.txt
            rm $tmp_path/$moa_tmp

            A_loop=$(gawk '{print NR}' $tmp_path/$tmp_file02)
            for a in $A_loop; do
                file_sac_name=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02)
                file_sac_name_sqr=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02.sqr)
                file_name_no_path=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02 | gawk -F"/" '{print $3}')
                file_sac_B=$(gawk 'NR=='$a'{print $2}' $tmp_path/$tmp_file02)
                file_depmen=$(gawk 'NR=='$a'{print $3}' $tmp_path/$tmp_file02)
                file_depmax=$(gawk 'NR=='$a'{print $4}' $tmp_path/$tmp_file02)
                moa=$(echo $file_depmax $file_depmen | gawk '{printf("%.2f \n" , $1/$2)}')

                echo $moa >>$tmp_path/$moa_tmp
                #echo " sac2xy $file_sac_name $file_sac_name.xy 0"
                sac2xy $file_sac_name $file_sac_name.xy 0

                gawk '{if ($2>='$file_depmen') print $1" 1"; else print $1" 0"}' $file_sac_name.xy >$tmp_path/$file_name_no_path.01.txt

                rm $file_sac_name.xy

                echo "r $file_sac_name; ch a $file_sac_B; wh; q;" | sac >/dev/null 2>&1

                echo "r $file_sac_name_sqr; ch a $file_sac_B; wh; q;" | sac >/dev/null 2>&1

            done

            ls $tmp_path/*.01.txt >$tmp_path/$tmp_file03

            C_loop_tmp=mytry.txt
            rm $tmp_path/$C_loop_tmp
            C_loop=$(gawk '{print NR}' $tmp_path/$tmp_file03)
            for c in $C_loop; do

                txt01_file=$(gawk 'NR=='$c'{print $1}' $tmp_path/$tmp_file03)

                one_how_many=$(gawk '{print $2}' $txt01_file | uniq | sort | uniq -c | gawk '$2==1{print $1}')

                #0=$1  1=$2
                How_long_1=$(gawk '{print $2}' $txt01_file | sort | uniq -c | gawk '{printf("%d  ",$1)}' | gawk '{printf("%2.2f",$2*100/($2+$1))}')

                #0  1
                How_long_1_npts=$(gawk '{print $2}' $txt01_file | sort | uniq -c | gawk '{printf("%d  ",$1)}')

                moa=$(gawk 'NR=='$c'{print $1+0}' $tmp_path/$moa_tmp)

                #decide tremor or not

                echo $txt01_file $one_how_many $How_long_1 $How_long_1_npts $moa >>$tmp_path/$C_loop_tmp

            done

            rm $tmp_path/*01.txt

            nwaveform=$(gawk 'END{print NR}' $tmp_path/$C_loop_tmp)
            D_loop=$(gawk '{print NR}' $tmp_path/$C_loop_tmp)

            neq=0
            ntremor=0
            nnoise=0
            nmoa=0

            for d in $D_loop; do

                every_data_path=$(gawk 'NR=='$d'{print $1}' $tmp_path/$C_loop_tmp)
                every_data_name=$(gawk -F"[/ ]" 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp | gawk -F".lp.01.txt" '{print $1}')
                event_name=$(gawk -F"[/ ]" 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp | gawk -F"." '{print $5"."$6"."$7"."$8}')

                nwave_packet=$(gawk 'NR=='$d'{print $2}' $tmp_path/$C_loop_tmp)
                duration_percentage=$(gawk 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp)
                duration_npts=$(gawk 'NR=='$d'{print $5 }' $tmp_path/$C_loop_tmp)
                moa=$(gawk 'NR=='$d'{print $6+0 }' $tmp_path/$C_loop_tmp)

                # && [ $duration_npts -lt 6000 ]
                if [ $nwave_packet -le 4 ]; then

                    neq=$(($neq + 1))

                    echo "$every_data_path $every_data_name  1" >>$tmp_path/$event_name.txt.tmp.tmp

                elif [ $duration_npts -lt 4000 ]; then

                    neq=$(($neq + 1))
                    echo "$every_data_path $every_data_name  2" >>$tmp_path/$event_name.txt.tmp.tmp

                elif [ $nwave_packet -ge 20 ] && [ $(echo "$duration_percentage > 40" | bc) -eq 1 ]; then

                    nnoise=$(($nnoise + 1))
                    echo "$every_data_path $every_data_name  3" >>$tmp_path/$event_name.txt.tmp.tmp
                    #elif [ $nwave_packet -ge 15 ] && [ `echo "$duration_percentage > 40"|bc` -eq 1 ];then

                    #       nnoise=$[$nnoise+1]

                elif [ $(echo "$moa > 10" | bc) -eq 1 ]; then
                    echo "$every_data_path $every_data_name  4" >>$tmp_path/$event_name.txt.tmp.tmp
                    neq=$(($neq + 1))
                    nmoa=$(($nmoa + 1))
                else

                    ntremor=$(($ntremor + 1))
                    echo "$every_data_path $every_data_name  tremor" >>$tmp_path/$event_name.txt

                fi

            done

            echo "$nwaveform $neq $ntremor $nnoise $nmoa $event_number $log_tmp_01"
            echo "$nwaveform $neq $ntremor $nnoise $nmoa $event_number $log_tmp_01" >>$output_path/$output_file_01

            tremorDetect=0
            if [ $(echo "$neq >= $nwaveform*0.4" | bc) -eq 1 ]; then

                echo "1 this event looks like earthquake."
                rm $tmp_path/$event_name.txt

            elif [ $(echo "$nmoa/$ntremor > 7" | bc) -eq 1 ]; then

                echo "3 this event looks like teleseismic."
                rm $tmp_path/$event_name.txt

            elif [ $(echo "$nmoa > 7" | bc) -eq 1 ]; then

                echo "1 this event looks like earthquake."
                rm $tmp_path/$event_name.txt

            else

                echo "Maybe is TRRRRRR"

                tremorDetect=1

            fi

            if [ 1 == $tremorDetect ]; then

                #cp $tmp_path/$event_name.txt $tmp_path/$event_name.txt.copy

                #sed -i 's/\//\\\//g' $tmp_path/$event_name.txt

                if [ 1 == 2 ]; then
                    ##########使用lp檔##########
                    cat $tmp_path/$event_name.txt | gawk -F".01.txt" '{print $1}' | gawk -F"tmp" '{print $1"data"$2}' >$tmp_path/tmp1_delt.txt
                    rm $tmp_path/$event_name.txt
                    mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt
                    #cat $tmp_path/$event_name.txt.copy | gawk -F".01.txt" '{print $1}'|gawk -F"tmp" '{print $1"data"$2}' $tmp_path/tmp1_delt.txt
                    #rm $tmp_path/$event_name.txt.copy
                    #mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt.copy

                    cp $tmp_path/$event_name.txt $tmp_path/$event_name.txt.copy

                    sed -i 's/\//\\\//g' $tmp_path/$event_name.txt
                ##########使用lp檔##########
                fi

                ##########使用sqr檔##########
                cat $tmp_path/$event_name.txt | gawk -F".lp.01.txt" '{print $1}' | gawk -F"tmp" '{print $1"data"$2".sqr"}' >$tmp_path/tmp1_delt.txt
                mv $tmp_path/$event_name.txt $tmp_path/$event_name.txt.tmp
                mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt
                #cat $tmp_path/$event_name.txt.copy | gawk -F".01.txt" '{print $1}'|gawk -F"tmp" '{print $1"data"$2}' $tmp_path/tmp1_delt.txt
                #rm $tmp_path/$event_name.txt.copy
                #mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt.copy

                cp $tmp_path/$event_name.txt $tmp_path/$event_name.txt.copy

                sed -i 's/\//\\\//g' $tmp_path/$event_name.txt
                ##########使用lp檔##########

                B_loop=$(gawk '{print NR}' $tmp_path/$event_name.txt)
                #B_loop=`gawk 'NR==1{print NR}' $tmp_path/$event_name.txt`
                for b in $B_loop; do

                    one_tenet=$(gawk 'NR=='$b'{print $1}' $tmp_path/$event_name.txt)
                    two_tenet=$(gawk 'NR=='$b'{print $1}' $tmp_path/$event_name.txt.copy)
                    echo "$two_tenet" >$tmp_path/tmp.$b.tmp.txt

                    sed -e '/'$one_tenet'/d' $tmp_path/$event_name.txt.copy >>$tmp_path/tmp.$b.tmp.txt

                    cat $tmp_path/tmp.$b.tmp.txt | scc -C0.6 -T900 -W0/990 >$tmp_path/scc.$b.scc.tmp

                    #rm $tmp_path/tmp.$b.tmp.txt

                done

            fi

            rm $data_path/*lp
            rm $data_path/*sqr
        #rm $tmp_path/*
        #ls $tmp_path/tmp.*.tmp.txt > $tmp_path/list.tmp

        #cat $tmp_path/$tmp_file01|scc -C0.001 -T90  -W0/90  > try.tmp

        ########以上程式碼勿動letmebashcc main code########

        fi

        rm $data_path/*bp
        #Y_loop_done
    done
    #Z_loop_done
done

######計時用######
TIME_ELAPSE_b=$(date --date="now" +%s)
TIME_ELAPSE=$(($TIME_ELAPSE_b - $TIME_ELAPSE_a))
echo "花費時間: $TIME_ELAPSE 秒"
######計時用######

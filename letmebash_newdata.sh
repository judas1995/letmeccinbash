#!/bin/bash
# Author:Henry
#Date & Time: 2020-09-28 11:11:20
#Description:

######計時用######
TIME_ELAPSE_a=$(date --date="now" +%s)
######計時用######

data_path=../data
tmp_path=../tmp
output_path=../output

#####偵測資料夾路徑是否存在#####
dirTest() {
    if [ -d "$1" ]; then
        # 目錄 /path/to/dir 存在
        dir_test=$[1+0]
    else
        # 目錄 /path/to/dir 不存在
        dir_test=$[0+0]
    fi
}
##############################

#######偵測檔案是否存在########
fileTest() {
    if [ -f "$1" ]; then
        # 檔案 /path/to/dir/filename 存在
        file_test=$[1+0]
    else
        # 檔案 /path/to/dir/filename 不存在
        file_test=$[0+0]
    fi
}
############################

whereweare=$(pwd)
output_file_01=Moon_out.txt
tmp_file01=tmp_file01_tmp.txt
tmp_file02=tmp_file02_tmp.txt
tmp_file03=tmp_file03_tmp.txt
tmp_file04=tmp_file04_tmp.txt
tmp_file05=tmp_file05_tmp.txt

########以下程式碼勿動letmebashcc main code########

#定義資料位置(bp是建立在我拿的資料如果已經band pass過後)
ls $data_path/*.bp >$tmp_path/$tmp_file01

##sac 前置處理  胞絡化  低通濾波0.2Hz##
echo "r $data_path/*bp ; rtr; rmean; envelope; lp co 0.2 p 2; w append .lp; q;" | sac >/dev/null 2>&1
#####################################

##sac 前置處理  胞絡化  低通濾波0.2Hz 波形平方##
echo "r $data_path/*bp ; rtr; rmean; envelope; lp co 0.2 p 2; sqr; w append .sqr; q;" | sac >/dev/null 2>&1
#############################################

##把低通濾波後的SAC資料的 B(波形p1的起始點) DEPMEN(平均振幅) DEPMAX(最大振幅) 抓出來##
saclst B DEPMEN DEPMAX f $data_path/*.lp >$tmp_path/$tmp_file02
#################################################################################

##把波形平方後的SAC資料的 B(波形p1的起始點) DEPMEN(平均振幅) DEPMAX(最大振幅) 抓出來##
saclst B DEPMEN DEPMAX f $data_path/*.sqr >$tmp_path/$tmp_file02.sqr
#################################################################################

#定義sqr資料位置
ls $data_path/*.sqr >$tmp_path/$tmp_file01.sqr
#定義lp資料位置
ls $data_path/*.lp >$tmp_path/$tmp_file01

##轉成SCC可以讀的資料格式，先複製一個備份##
cp $tmp_path/$tmp_file01 $tmp_path/$tmp_file01.copy
#把"/"取代成"/\"
sed -i 's/\//\\\//g' $tmp_path/$tmp_file01
########################################

moa_tmp=mmttmp.txt

###檢測 moa_tmp 檔案是否存在###
fileTest $tmp_path/$moa_tmp
#echo file_test

if [ $file_test == 1 ]; then
    # 檔案 /path/to/dir/filename 存在
    rm $tmp_path/$moa_tmp
fi
#############################

###針對每個SAC檔案微調檔頭###
A_loop=$(gawk '{print NR}' $tmp_path/$tmp_file02)
for a in $A_loop; do
    #低通濾波後SAC檔檔名(含相對路徑)
    file_sac_name=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02)
    #平方後sac檔檔名(含相對路徑)
    file_sac_name_sqr=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02.sqr)
    #低通濾波後SAC檔-純檔名
    file_name_no_path=$(gawk 'NR=='$a'{print $1}' $tmp_path/$tmp_file02 | gawk -F"/" '{print $3}')
    #低通濾波後SAC檔-B的時間點
    file_sac_B=$(gawk 'NR=='$a'{print $2}' $tmp_path/$tmp_file02)
    #低通濾波後SAC檔-平均振幅
    file_depmen=$(gawk 'NR=='$a'{print $3}' $tmp_path/$tmp_file02)
    #低通濾波後SAC檔-最大振幅
    file_depmax=$(gawk 'NR=='$a'{print $4}' $tmp_path/$tmp_file02)
    #Max Over Average
    moa=$(echo $file_depmax $file_depmen | gawk '{printf("%.2f \n" , $1/$2)}')

    echo $moa >>$tmp_path/$moa_tmp
    #echo " sac2xy $file_sac_name $file_sac_name.xy 0"
    #將SAC檔轉成xy值，不進行正規化
    sac2xy $file_sac_name $file_sac_name.xy 0
    #高於平均振幅之數值記為1，反之記為0
    gawk '{if ($2>='$file_depmen') print $1" 1"; else print $1" 0"}' $file_sac_name.xy >$tmp_path/$file_name_no_path.01.txt
    #刪除xy檔
    rm $file_sac_name.xy
    #將低通濾波後的SAC檔標註AMARKER  後續scc會用到
    echo "r $file_sac_name; ch a $file_sac_B; wh; q;" | sac >/dev/null 2>&1
    #將平方後的SAC檔標註AMARKER  後續scc會用到
    echo "r $file_sac_name_sqr; ch a $file_sac_B; wh; q;" | sac >/dev/null 2>&1

done
#############################

#######針對0-1檔案做統計######

#做出01.txt list 用於定義檔案位置 以及檔名
ls $tmp_path/*.01.txt >$tmp_path/$tmp_file03

C_loop_tmp=mytry.txt

###檢測 C_loop_tmp 檔案是否存在###
fileTest $tmp_path/$C_loop_tmp
#echo file_test
if [ $file_test == 1 ]; then
    # 檔案 /path/to/dir/filename 存在
    rm $tmp_path/$C_loop_tmp
fi
#############################

C_loop=$(gawk '{print NR}' $tmp_path/$tmp_file03)
for c in $C_loop; do
    #01.txt檔名(含相對路徑)
    txt01_file=$(gawk 'NR=='$c'{print $1}' $tmp_path/$tmp_file03)
    #統計1的波胞有幾個
    one_how_many=$(gawk '{print $2}' $txt01_file | uniq | sort | uniq -c | gawk '$2==1{print $1}')
    #統計持續秒數(0的總秒數用$1  1的總秒數用$2)
    How_long_1=$(gawk '{print $2}' $txt01_file | sort | uniq -c | gawk '{printf("%d  ",$1)}' | gawk '{printf("%2.2f",$2*100/($2+$1))}')
    #統計持續NPTS  依序列出 0  1 的NPTS
    How_long_1_npts=$(gawk '{print $2}' $txt01_file | sort | uniq -c | gawk '{printf("%d  ",$1)}')
    #Max Over Average(利用兩個list排序方式一樣才可以這樣抓)
    moa=$(gawk 'NR=='$c'{print $1+0}' $tmp_path/$moa_tmp)

    #decide tremor or not
    #輸出資料 用於決定tremor與否
    echo $txt01_file $one_how_many $How_long_1 $How_long_1_npts $moa >>$tmp_path/$C_loop_tmp

    #輸出log檔，用做統計

done
#############################

#刪除不需要的01.txt
rm $tmp_path/*01.txt

#輸出總波形數量
nwaveform=$(gawk 'END{print NR}' $tmp_path/$C_loop_tmp)
#統計單一事件，各測站的可能性
D_loop=$(gawk '{print NR}' $tmp_path/$C_loop_tmp)
#將D_loop內用到的變數歸零

#統計認為是地震的測站數量
neq=0
#統計認為是tremor的測站數量
ntremor=0
#統計認為是雜訊的測站數量
nnoise=0
#統計最大振幅大於平均振幅10倍的測站數量
nmoa=0

for d in $D_loop; do

    #01.txt檔案位置
    every_data_path=$(gawk 'NR=='$d'{print $1}' $tmp_path/$C_loop_tmp)
    #最原始的檔案名稱
    every_data_name=$(gawk -F"[/ ]" 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp | gawk -F".lp.01.txt" '{print $1}')
    #用來定義事件的名稱
    event_name=$(gawk -F"[/ ]" 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp | gawk -F"." '{print $5"."$6"."$7"."$8}')
    #振幅等於1之波胞數量
    nwave_packet=$(gawk 'NR=='$d'{print $2}' $tmp_path/$C_loop_tmp)
    #振幅等於1之波胞所佔據之時間比例
    duration_percentage=$(gawk 'NR=='$d'{print $3}' $tmp_path/$C_loop_tmp)
    #振幅等於1之NPTS數量
    duration_npts=$(gawk 'NR=='$d'{print $5 }' $tmp_path/$C_loop_tmp)
    #Max Over Average(利用兩個list排序方式一樣才可以這樣抓)
    moa=$(gawk 'NR=='$d'{print $6+0 }' $tmp_path/$C_loop_tmp)

    # && [ $duration_npts -lt 6000 ]
    #波胞低於(含)4個以下定義為地震-(戴心如)
    if [ $nwave_packet -le 4 ]; then

        neq=$(($neq + 1))
        #紀錄因為甚麼原因被定義成地震
        echo "$every_data_path $every_data_name  1" >>$tmp_path/$event_name.txt.tmp.tmp

    elif [ $duration_npts -lt 4000 ]; then

        neq=$(($neq + 1))
        #紀錄因為甚麼原因被定義成地震
        echo "$every_data_path $every_data_name  2" >>$tmp_path/$event_name.txt.tmp.tmp

    elif [ $nwave_packet -ge 20 ] && [ $(echo "$duration_percentage > 40" | bc) -eq 1 ]; then

        nnoise=$(($nnoise + 1))
        #紀錄因為甚麼原因被定義成雜訊
        echo "$every_data_path $every_data_name  3" >>$tmp_path/$event_name.txt.tmp.tmp
        #elif [ $nwave_packet -ge 15 ] && [ `echo "$duration_percentage > 40"|bc` -eq 1 ];then

        #       nnoise=$[$nnoise+1]

    elif [ $(echo "$moa > 10" | bc) -eq 1 ]; then
        #紀錄因為甚麼原因被定義成地震
        echo "$every_data_path $every_data_name  4" >>$tmp_path/$event_name.txt.tmp.tmp
        neq=$(($neq + 1))
        nmoa=$(($nmoa + 1))
    else
        #紀錄因為甚麼原因被定義成tremor
        ntremor=$(($ntremor + 1))
        echo "$every_data_path $every_data_name  tremor" >>$tmp_path/$event_name.txt

    fi

done

echo "$nwaveform $neq $ntremor $nnoise $nmoa $event_number"
#記錄該事件各測站的統計(總波形數量 地震波形數量 tremor波形數量 雜訊波形數量 MaxOverAverage波形數量 事件編號)
echo "$nwaveform $neq $ntremor $nnoise $nmoa $event_number" >>$output_path/$output_file_01

tremorDetect=0
if [ $(echo "$neq >= $nwaveform*0.4" | bc) -eq 1 ]; then

    echo "1 this event looks like earthquake."
    rm $tmp_path/$event_name.txt

elif [ $(echo "$nmoa/$ntremor > 7" | bc) -eq 1 ]; then

    echo "3 this event looks like teleseismic."
    rm $tmp_path/$event_name.txt

elif [ $(echo "$nmoa > 7" | bc) -eq 1 ]; then

    echo "4 this event looks like earthquake."
    rm $tmp_path/$event_name.txt

else

    echo "Maybe is tremor"

    tremorDetect=1

fi

###第二階段tremor&noise 嘗試分開###
if [ 1 == $tremorDetect ]; then

    #cp $tmp_path/$event_name.txt $tmp_path/$event_name.txt.copy

    #sed -i 's/\//\\\//g' $tmp_path/$event_name.txt

    #單純當開關用
    if [ 1 == 2 ]; then
        ##########使用lp檔##########

        #僅留下lp檔案名稱(含相對路徑)
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

    #單純當開關用
    if [ 1 == 1 ]; then
        ##########使用sqr檔##########
        #僅留下lp檔案名稱(含相對路徑)
        cat $tmp_path/$event_name.txt | gawk -F".lp.01.txt" '{print $1}' | gawk -F"tmp" '{print $1"data"$2".sqr"}' >$tmp_path/tmp1_delt.txt
        mv $tmp_path/$event_name.txt $tmp_path/$event_name.txt.tmp
        mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt
        #cat $tmp_path/$event_name.txt.copy | gawk -F".01.txt" '{print $1}'|gawk -F"tmp" '{print $1"data"$2}' $tmp_path/tmp1_delt.txt
        #rm $tmp_path/$event_name.txt.copy
        #mv $tmp_path/tmp1_delt.txt $tmp_path/$event_name.txt.copy

        cp $tmp_path/$event_name.txt $tmp_path/$event_name.txt.copy

        sed -i 's/\//\\\//g' $tmp_path/$event_name.txt
        ##########使用sqr檔##########
    fi

    #倆倆測站進行cross correlation
    #B_loop=$(gawk '{print NR}' $tmp_path/$event_name.txt)
    B_loop=$(gawk 'NR==1{print NR}' $tmp_path/$event_name.txt)
    for b in $B_loop; do

        #給SCC用的路徑
        one_tenet=$(gawk 'NR=='$b'{print $1}' $tmp_path/$event_name.txt)
        echo $one_tenet
        #給我看用的路徑
        two_tenet=$(gawk 'NR=='$b'{print $1}' $tmp_path/$event_name.txt.copy)
        echo #two_tenet
        echo "$two_tenet" >$tmp_path/tmp.$b.tmp.txt

        sed -e '/'$one_tenet'/d' $tmp_path/$event_name.txt.copy >>$tmp_path/tmp.$b.tmp.txt

        cat $tmp_path/tmp.$b.tmp.txt | scc -C0.6 -T900 -W0/990 >$tmp_path/scc.$b.scc.tmp

        #rm $tmp_path/tmp.$b.tmp.txt

    done

fi
rm $tmp_path/$event_name.txt
rm $tmp_path/$event_name.txt.copy
rm $data_path/*lp
rm $data_path/*sqr


######計時用######
TIME_ELAPSE_b=$(date --date="now" +%s)
TIME_ELAPSE=$(($TIME_ELAPSE_b - $TIME_ELAPSE_a))
echo "花費時間: $TIME_ELAPSE 秒"
######計時用######

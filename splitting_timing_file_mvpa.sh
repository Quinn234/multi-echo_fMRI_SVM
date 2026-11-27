#!/bin/bash
# MVPA step 3 getting 1D label file

#separate the timing file for block decision, block anticipation, block feedback, event decision and event anticipation phases
# block decision: risky reward (RED), non-risk reward (WHITE), neutral (GRAY)
# block anticipation: risky reward (RED), non-risk reward (WHITE), neutral (GRAY)
# block feedback: risky reward positive_feedback & negative_feedback (RED), non-risk reward (WHITE), neutral (GRAY)
# event decision: risky reward (RED), non-risk reward (WHITE), neutral (GRAY)
# event anticipation: risky reward (RED), non-risk reward (WHITE), neutral (GRAY)


task='BART'
behavior_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/BART_behavior
raw_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw
file_dir=${behavior_dir}/timing_files_block_event
split_dir=${behavior_dir}/spliting_files_mvpa

for i in {01..69};do
  for j in {1..2};do
    if [ -d ${raw_dir}/DevC_P0${i} ] && [ -f ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt ]
    then
    echo "For DevC_P0${i}_task-${task}_run-${j}, currently spliting the timing file for MVPA analysis "
 
    #block decision

    awk -v threshold=621.4 '/RED_block_decision/ && $3 + $4 < threshold {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.txt
    # awk '/RED_block_decision/ {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.txt
    awk '{print $1}' ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.txt | paste -s -d ' ' > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA_transposed.txt

    awk -v threshold=621.4 '/WHITE_block_decision/ && $3 + $4 < threshold {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.txt
    # awk '/WHITE_block_decision/ {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.txt
    awk '{print $1}' ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.txt | paste -s -d ' ' > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA_transposed.txt


    awk -v threshold=621.4 '/GRAY_block_decision/ && $3 + $4 < threshold {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.txt
    # awk '/GRAY_block_decision/ {print $3":"$4}' ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.txt
    awk '{print $1}' ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.txt | paste -s -d ' ' > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA_transposed.txt


    # #convert the txt file to 1D file
    # cat ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.1D
    # cat ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.1D
    # cat ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.txt > ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.1D

    # wc -l ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_RED_block_MVPA.txt >> ${split_dir}/task-${task}_run-${j}_RED_Ntrial_MVPA.1D
    # wc -l ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_WHITE_block_MVPA.txt >> ${split_dir}/task-${task}_run-${j}_WHITE_Ntrial_MVPA.1D
    # wc -l ${split_dir}/DevC_P0${i}_task-${task}_run-${j}_GRAY_block_MVPA.txt >> ${split_dir}/task-${task}_run-${j}_GRAY_Ntrial_MVPA.1D

    # awk '{sum += $1} END {print sum}' task-${task}_run-${j}_RED_Ntrial_MVPA.txt 
    # RED 650 630
    # WHITE 630 633
    # GRAY 414 416 

    else
    echo "there is no DevC_P0${i}_task-${task}_run-${j} folder or timing_event file"
    fi
  done

    if [ -d ${raw_dir}/DevC_P0${i} ] && [ -f ${file_dir}/DevC_P0${i}_task-${task}_run-${j}_events.txt ]
    then
    echo "two runs timing file is merged for DevC_P${i}"
    pr -t -s' ' ${split_dir}/DevC_P0${i}_task-${task}_run-1_RED_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-2_RED_block_MVPA_transposed.txt > ${split_dir}/DevC_P0${i}_task-${task}_RED_block_MVPA.1D
    pr -t -s' ' ${split_dir}/DevC_P0${i}_task-${task}_run-1_WHITE_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-2_WHITE_block_MVPA_transposed.txt > ${split_dir}/DevC_P0${i}_task-${task}_WHITE_block_MVPA.1D
    pr -t -s' ' ${split_dir}/DevC_P0${i}_task-${task}_run-1_GRAY_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-2_GRAY_block_MVPA_transposed.txt > ${split_dir}/DevC_P0${i}_task-${task}_GRAY_block_MVPA.1D

    rm ${split_dir}/DevC_P0${i}_task-${task}_run-1_RED_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-1_WHITE_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-1_GRAY_block_MVPA_transposed.txt
    rm ${split_dir}/DevC_P0${i}_task-${task}_run-2_RED_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-2_WHITE_block_MVPA_transposed.txt ${split_dir}/DevC_P0${i}_task-${task}_run-2_GRAY_block_MVPA_transposed.txt

    else
    echo "there is no DevC_P0${i}_task-${task} folder or timing_event file"
    fi
done



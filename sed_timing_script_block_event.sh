#!/bin/bash

#this script is for creating the timing_file_script for every participants.
# it includes info for block decision,block anticipation, block feedback, event decision and event anticipation phases
behavior_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/BART_behavior
raw_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw
template_dir=${behavior_dir}/timing_scripts_block_event
file_dir=${behavior_dir}/timing_files_block_event
timing_dir=${behavior_dir}/behavior_timing
for i in {01..69};do
  for j in {1..2};do
    func_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/DevC_P0${i}/func/BART
    run_dir=${func_dir}/run-${j}
    if [ -d ${raw_dir}/DevC_P0${i} ] && [ -f ${timing_dir}/DevC_P0${i}_bart_project__Run0${j}.csv ]
    then 
        if [ -f ${file_dir}/DevC_P0${i}_task-BART_run-${j}_events.txt ]
        then
          echo "DevC_P0${i}_run-${j}_events.txt file have already been created in DevC_PO${i} folder "
        else 
          echo "DevC_P0${i}_run-${j}_events.txt file is created now in DevC_PO${i} folder"
          # sed alter contents
          sed "s/DevC_P010_bart_project__Run01/DevC_P0${i}_bart_project__Run0${j}/g" ${template_dir}/template_split_timing_block_event.py > ${template_dir}/DevC_P0${i}_task-BART_run-${j}_split_timing.py
          #run each script for each subject
          python ${template_dir}/DevC_P0${i}_task-BART_run-${j}_split_timing.py
          mv ${file_dir}/task-BART_events.txt ${file_dir}/DevC_P0${i}_task-BART_run-${j}_events.txt
          fi
    else 
         echo "there is no DevC_P0${i} folder"
         fi
  done
done
#!/bin/bash
# MVPA Step 5 Generating separated data per trial and condition
# Based on 1D timing file for each condition, we got sub-brick data set for each trial per condition.
# e.g., trial_1_RiskyReward, trial_2_NonriskReward, etc.

read -p 'Participant(s): ' subjects
read -p 'Task: ' task
read -p 'Run number: ' run

if [[ ${task} == '' ]];
then
    task='BART'
fi

if [[ ${run} == '' ]];
then
    run='1'
fi

if [[ ${subjects} == '' ]];
then 
    subjects=$(cat /mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/locations/task-${task}_run-${run}_PTP.txt)
fi


base_folder=/mnt/LifeHistoryLab/BIC_Data/1902008564_data
preproc_folder=${base_folder}/analysis/MVPA/PREPROC
preproc_output=${preproc_folder}/preproc_output
preproc_script=${preproc_folder}/preproc_script
tedana_dir=${preproc_folder}/tedana
all_run_dir=${preproc_output}/${task}/all_runs
run_1_dir=${preproc_output}/${task}/run-1
run_2_dir=${preproc_output}/${task}/run-2
behavior_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/BART_behavior
raw_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw
file_dir=${behavior_dir}/timing_files_block_event
split_dir=${behavior_dir}/spliting_files_mvpa
deconvolve_dir=${base_folder}/analysis/MVPA/DECONVOLVE



for sub in $subjects
do
    if [[ -f ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii ]]
    then
    # to know the number of riskyreward and nonriskreward trials
        3dinfo -verb ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii > ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_bucket_3dinfo.txt
        
        if [[ -f ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_bucket_3dinfo.txt ]]
        then
            RiskyReward_trial_num=$(grep -c "At sub-brick #.* 'RiskyReward#.*_Coef'" ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_bucket_3dinfo.txt)
            NonriskReward_trial_num=$(grep -c "At sub-brick #.* 'NonriskReward#.*_Coef'" ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_bucket_3dinfo.txt)
            NonriskReward_trial_num_start=$((RiskyReward_trial_num + 1))
            NonriskReward_trial_num_end=$((RiskyReward_trial_num + NonriskReward_trial_num))
            echo "for ${sub}_task-${task}_MVPA, RiskyReward_trial_num: $RiskyReward_trial_num, NonriskReward_trial_num: $NonriskReward_trial_num"
            
            for num in $(seq 1 $RiskyReward_trial_num); 
            do
                3dTcat -prefix ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_RiskyReward.trial-$num.nii \
                            ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii[${num}]
            done

            for num in $(seq $NonriskReward_trial_num_start $NonriskReward_trial_num_end)
            do
                b=$((num - RiskyReward_trial_num))
                # (( b=`expr $num - $RiskyReward_trial_num` ))
                3dTcat -prefix ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_NonriskReward.trial-$b.nii \
                            ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii[${num}]
            done
        else
            echo "cannot generate ${sub}_task-${task}_bucket_3dinfo.txt"
        fi
    else
        echo "there is no ${sub}_task-${task}_MVPA.BLOCK.nii"
    fi
done

# for a in $(seq 1 8); do 3dTcat -prefix cars.$a.nii MVPA.BLOCK.nii[${a}]; done
# for a in $(seq 9 16); do (( b=`expr $a - 8` )); 3dTcat -prefix faces.$b.nii MVPA.BLOCK.nii[${a}]; done
# for a in $(seq 17 24); do (( b=`expr $a - 16` )); 3dTcat -prefix houses.$b.nii MVPA.BLOCK.nii[${a}]; done
# for a in $(seq 25 32); do (( b=`expr $a - 24` )); 3dTcat -prefix shoes.$b.nii MVPA.BLOCK.nii[${a}]; done
# 3dinfo -verb /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE/DevC_P006_task-BART_MVPA.results/DevC_P006_task-BART_MVPA.BLOCK.nii > /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE/DevC_P006_task-BART_MVPA.results/DevC_P006_task-BART_bucket_3dinfo.txt
# grep -c "At sub-brick #.* 'RiskyReward#.*_Coef'" 3dinfo_bucket.txt
# grep -c "At sub-brick #.* 'NonriskReward#.*_Coef'" 3dinfo_bucket.txt

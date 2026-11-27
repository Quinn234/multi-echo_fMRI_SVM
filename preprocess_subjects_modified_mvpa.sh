#!/bin/bash -l

# MVPA step 2 running preprocessing script

#This script actually runs the output of afni_proc_generator.py on the compute node to do all preprocessing for each subject.
#Written by Nick Cicero and Lissa Riley
#

# # load afni
# module load afni

base_folder=/mnt/LifeHistoryLab/BIC_Data/1902008564_data
preproc_folder=${base_folder}/analysis/MVPA/PREPROC
preproc_output=${preproc_folder}/preproc_output
preproc_script=${preproc_folder}/preproc_script

# activate virtual python environment and load necessary packages
# enviornment is python2 because tedana.py is written for python2

# source /home/shared/aclab-fmri/Studies/33_MOTIP2018/scripts/preprocess/py_venv/bin/activate
# source base_folder/analysis/SCRIPTS/py_venv/bin/activate

#####need to change 'task' and 'run' numbers manually before running [user-input with the compute node may not be feasible...]
# task='BART'
# run='1'

read -p 'Participant(s): ' subjects
read -p 'Task: ' task
read -p 'Run number: ' run
read -p 'Overwrite? y/n: ' overwrite

# # load list of subjects for specific task and run number
# # or choose specific subjects you want by editing here
# subjects=$(cat /mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/locations/task-${task}_run-${run}_PTP.txt)

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

for sub in $subjects
do
    # # delete existing results folder and reporting output if it already exists
    if [[ ! -d ${preproc_output}/${task}/run-${run}/${sub}_task-${task}_run-${run}.results ]];
    then
    #     sudo rm -R ${preproc_output}/${task}/run-${run}/${sub}_task-${task}_run-${run}.results
    # fi

    # if [[ -f ${preproc_output}/${task}/run-${run}/output.proc.${sub}_task-${task}_run-${run} ]];
    # then
    #    rm ${preproc_output}/${task}/run-${run}/output.proc.${sub}_task-${task}_run-${run}
    # fi

    # cd ${preproc_output}/${task}/run-${run}

    # run file created from afni_proc_generator.sh run
    tcsh -xef ${preproc_script}/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} 2>&1 |& tee ${preproc_output}/${task}/run-${run}/output.proc.${sub}_task-${task}_run-${run}

    fi
    ### add reporting to .txt file keep track of when a sub, task, and run were most recently and successfully processed
    if [[ -f ${preproc_output}/${sub}_task-${task}_run-${run}.results/tedana_r01/TED.r01/dn_ts_OC.nii ]];
    then
        date=$(date)
        echo "${sub} ${task} ${run} $date" >> ${preproc_output}/preproc_reporting.txt
    fi
    

done


echo "job finished executing"
# exit 0

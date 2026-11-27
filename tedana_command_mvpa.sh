#!/bin/bash
#tedana command line

#change the task and run information below.
task='BART'
run='1'

result_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/preproc_output/${task}/run-${run}
tedana_dir=/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/tedana/${task}/run-${run}

subjects=$(cat /mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/locations/task-${task}_run-${run}_PTP.txt)

# subjects = 'DevC_P006 DevC_P043'

# get specific echo times for specific task TE
if [[ ${task} == "BART" ]];
then
    tes='13.4 35.8 58.5'
elif [[ ${task} == "CBALL" ]];
then
    tes='12.2 26.0 40.0'
elif [[ ${task} == "STROOP" ]];
then
    tes='12.2 30.0 47.0'
fi

# # # this is for running the command line on the server, avoiding permission problems.
# for sub in $subjects
# do  
#     if [ ! -f ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask/desc-optcomDenoised_bold.nii.gz ]
#     then
#   echo "tedana folder for ${sub}_task-${task}_run-${run}_mask is creating"
#     sudo mkdir ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask
#     sudo chmod ugo+rwx ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask
#     else
#     echo "tedana folder has generated already"
#     fi
# done

for sub in $subjects
do  
    if [ -d ${result_dir}/${sub}_task-${task}_run-${run}.results ] && [ -d ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask ]
    then      
        #check if we have the tedana results successfully or run the tedana command line based on volume registration data for three echoes
        #remember open the tedana_env conda environment "conda activate tedana_env"
        if [ ! -f ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask/desc-optcomDenoised_bold.nii.gz ]
        then
            echo "starting the combination for three echoes for ${sub}_task-${task}_run-${run}!"
            tedana \
            -d ${result_dir}/${sub}_task-${task}_run-${run}.results/pb03.${sub}.r01.e01.volreg+orig.BRIK.gz ${result_dir}/${sub}_task-${task}_run-${run}.results/pb03.${sub}.r01.e02.volreg+orig.BRIK.gz ${result_dir}/${sub}_task-${task}_run-${run}.results/pb03.${sub}.r01.e03.volreg+orig.BRIK.gz \
            -e ${tes} \
            --out-dir ${tedana_dir}/${sub}_task-${task}_run-${run}_tedana_mask \
            --mask ${result_dir}/${sub}_task-${task}_run-${run}.results/mask_epi_anat.${sub}+orig.BRIK.gz
        else
            echo "All tedana outputs for ${sub}_task-${task}_run-${run}_masked.nii.gz files already exists."
        fi

    else 
        echo "there is no ${sub} 's OC result folder."

    fi
done
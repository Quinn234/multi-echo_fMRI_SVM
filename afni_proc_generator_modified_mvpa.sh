#!/bin/bash -l

# MVPA Step 1 Generating preprocessing script


##########################
# This script creates an afni_proc script for specific subjects, tasks, and run numbers that the user of this script inputs.
# The script relies on scan location files that indicate the scan number for a subject's specific task and run number.
# The script also relies on a scan location file indication where the subject's MPRAGE is located.
# The script was updated in January 2022 to locate files in both the pre-pandemic and post-pandemic file structures automaticallys
#
# WRITTEN AND MAINTAINED BY:
    # Lissa Riley (er482)
    # Nick Cicero (ngc26)
##########################

# The following two lines of code ask the user for subject(s), task name, and run number
    # if doing multiple subjects, input each subject with a space between the next
    # if no subjects are entered, the script will look for all subjects who have that task and run number
#### EXAMPLE ####
#   $ bash afni_proc.generator.sh
#   Subject(s) [optional]:   101
#   Task [required]:         ABE
#   Run number [required]:   1
#   Overwrite? [required] y/n: y

#################
read -p 'Participant(s): ' subjects
read -p 'Task: ' task
read -p 'Run number: ' run
read -p 'Overwrite? y/n: ' overwrite

# directories that will de-clutter code below
# base_folder=/home/shared/aclab-fmri/Studies/33_MOTIP2018
base_folder=/mnt/LifeHistoryLab/BIC_Data/1902008564_data
# prepro_folder=${base_folder}/scripts/preprocess
prepro_folder=${base_folder}/analysis/MVPA/PREPROC
# data_folder=${base_folder}/MRI_data
data_folder=${base_folder}/raw

# preproc_output=${base_folder}/MRI_data/PREPROCESSED/processing_scripts
preproc_output=${base_folder}/analysis/MVPA/PREPROC

# load scan location file for $task and $run
# scan_loc=${data_folder}/locations/${task}${run}_loc.txt
# subject_folder=${data_folder}/locations/${task}${run}_subjects.txt
scan_loc=${data_folder}/locations/task-${task}_run-${run}_loc.txt
subject_folder=${data_folder}/locations/task-${task}_run-${run}_PTP.txt

# get scan location file for subject's MPRAGE
# anat_scan_loc=${data_folder}/locations/MPRAGE_loc.txt
# anat_subject_folder=${data_folder}/locations/MPRAGE_subjects.txt
anat_scan_loc=${data_folder}/locations/MPRAGE_loc.txt
anat_subject_folder=${data_folder}/locations/MPRAGE_PTP.txt

# if no subjects were entered by the user, look for all subjects who have that task and run number
if [[ ${subjects} == '' ]];
then
    subjects=$(cat ${data_folder}/locations/task-${task}_run-${run}_PTP.txt)
fi

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



#STROOP 12.2 26 40
#CBALL 12.2ms 26 40
#BART 13.4 ms  35.8 58.5

# loop through all subjects that you input above
for sub in $subjects
do
    # get exact scan number for this specific subject, task, and run number (from $scan_loc)
    sub_position_in_scan_file=$(grep -n ${sub} $subject_folder | cut -d : -f 1)
    scan_num=$(sed -n ${sub_position_in_scan_file}p $scan_loc)
    echo $scan_num

    # get exact scan number for anatomical dataset (from $anat_scan_loc)
    sub_position_in_anat_scan_file=$(grep -n ${sub} $anat_subject_folder | cut -d : -f 1)
    anat_scan_num=$(sed -n ${sub_position_in_anat_scan_file}p $anat_scan_loc)
    echo $anat_scan_num

    #check if afni_proc script already exists for that subject, task, and run
    # if [[ -f ${preproc_output}/proc.${sub}_${task}_${run} ]] && [[ ${overwrite} == 'n' ]];
    if [[ -f ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} ]] && [[ ${overwrite} == 'n' ]]
    then
        echo "Preprocessing script already exists"
    #     if [[ -f ${preproc_output}/proc.${sub}_task-${task}_run-${run} ]];
	# then 
	# 	rm ${preproc_output}/proc.${sub}_task-${task}_run-${run}
	# fi
    elif [[ -f ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} ]] && [[ ${overwrite} == 'y' ]]
    then
        echo "Recreating a script..."
        rm ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run}
	elif [[ ! -f ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} ]]
    then
        echo "Creating a script..."
        #check if data is located/formated in the 2021+ way
    fi

    ## 
    ##create afni_proc script for specific subject, task, and run
    modern_files=$(ls ${data_folder}/${sub}/${anat_scan_num}/mprage*+orig.BRIK | wc -l) 
    echo $modern_files
    if [[ $modern_files -gt 0 ]] 
    then
        echo "Writing the script using BRIK data structure..."
            afni_proc.py \
                    -subj_id ${sub} \
                    -script ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} \
                    -out_dir ${preproc_output}/preproc_output/${task}/run-${run}/${sub}_task-${task}_run-${run}.results \
                    -copy_anat ${data_folder}/${sub}/${anat_scan_num}/mprage*+orig.BRIK \
                    -anat_has_skull yes \
                    -dsets_me_run ${data_folder}/${sub}/${scan_num}/run*.nii \
                    -echo_times ${tes} \
                    -blocks despike tshift align volreg mask combine scale \
                    -radial_correlate_blocks tcat volreg \
                    -volreg_align_to MIN_OUTLIER \
                    -volreg_align_e2a \
                    -mask_epi_anat yes \
                    -combine_method OC \
                    -find_var_line_blocks NONE \
                    -html_review_style pythonic
    else
        echo "Writing the script using nii data structure..."
            afni_proc.py \
                    -subj_id ${sub} \
                    -script ${preproc_output}/preproc_script/${task}/run-${run}/proc.${sub}_task-${task}_run-${run} \
                    -out_dir ${preproc_output}/preproc_output/${task}/run-${run}/${sub}_task-${task}_run-${run}.results \
                    -copy_anat ${data_folder}/${sub}/${anat_scan_num}/mprage*.nii \
                    -anat_has_skull yes \
                    -dsets_me_run ${data_folder}/${sub}/${scan_num}/run*.nii \
                    -echo_times ${tes} \
                    -blocks despike tshift align volreg mask combine scale \
                    -radial_correlate_blocks tcat volreg \
                    -volreg_align_to MIN_OUTLIER \
                    -volreg_align_e2a \
                    -mask_epi_anat yes \
                    -combine_method OC \
                    -find_var_line_blocks NONE \
                    -html_review_style pythonic
    fi


done


## in case we need to look in old folders structured the old way to find the raw multi echo data (see the dsets and copy_anat line)
# elif [[ $modern_files -gt 0 ]] && [[ -f ${data_folder}/DevC_P${sub}/${anat_scan_num}/mprage_scan* ]]
# then
# elif [[ $modern_files -gt 0 ]] | [[ ! -f ${data_folder}/DevC_P${sub}/${anat_scan_num}/mprage*+orig.BRIK ]]

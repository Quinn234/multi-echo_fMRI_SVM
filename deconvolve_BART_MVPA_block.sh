#!/bin/bash
# MVPA Step 4 Extracting deconvolved datasets for each ptp

# Based on 1D timing file for two conditions (riskyreward & nonriskreward
# deconvolve ptps' data to bucket dataset

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

#Deconvolve BART RED WHITE GRAY Condition

for sub in $subjects
do
    if [[ ! -d ${deconvolve_dir}/${sub}_task-${task}_MVPA.results ]]
    then
        mkdir ${deconvolve_dir}/${sub}_task-${task}_MVPA.results
    else
        echo "The deconvolution folder for ${sub}_task-${task} already exists"
    fi
    # #Concatenate sub-bricks from input datasets into one big 3D+time dataset.
    # 3dTcat -prefix ${all_run_dir}/${sub}_task-${task}_scale+orig_allruns ${run_1_dir}/${sub}_task-${task}_run-1.results/pb05.${sub}.r01.scale+orig.BRIK.gz ${run_2_dir}/${sub}_task-${task}_run-2.results/pb05.${sub}.r01.scale+orig.BRIK.gz \
    #        -tr 2.6 \
    #        -verb

    if [[ -f ${run_1_dir}/${sub}_task-${task}_run-1.results/pb05.${sub}.r01.scale+orig.BRIK.gz && \
    -f ${run_2_dir}/${sub}_task-${task}_run-2.results/pb05.${sub}.r01.scale+orig.BRIK.gz ]]
    then
        if [[ ! -f ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii ]]
        then
            echo "deconvolving ${sub}_task-${task}_run-${run}_preprocessed data "
            # compute tighter run-1 mask by intersecting with run-2 mask
            3dmask_tool -input ${run_1_dir}/${sub}_task-${task}_run-1.results/mask_epi_anat.${sub}+orig.BRIK.gz ${run_2_dir}/${sub}_task-${task}_run-2.results/mask_epi_anat.${sub}+orig.BRIK.gz \
                        -inter -prefix ${all_run_dir}/${sub}_task-${task}_mask_anat+orig.BRIK.gz

            # chmod -R ugo+rwx ${all_run_dir}/${sub}_task-${task}_mask_anat+orig_allruns*

            # compute overlaps between anat and EPI masks
            3dABoverlap -no_automask ${run_1_dir}/${sub}_task-${task}_run-1.results/mask_epi_anat.${sub}+orig.BRIK.gz ${run_2_dir}/${sub}_task-${task}_run-2.results/mask_epi_anat.${sub}+orig.BRIK.gz \
                        |& tee ${all_run_dir}/out.mask_ae_overlap.txt

            # 3dTcat -prefix ${all_run_dir}/${sub}_task-${task}_mask_anat+orig_allruns ${run_1_dir}/${sub}_task-${task}_run-1.results/mask_epi_anat.${sub}+orig.BRIK.gz ${run_2_dir}/${sub}_task-${task}_run-2.results/mask_epi_anat.${sub}+orig.BRIK.gz
            # 3dDeconvolve -input ${all_run_dir}/${sub}_task-${task}_scale+orig_allrun \
            #*+ WARNING: Input polort=1; Longest run=624.0 s; Recommended minimum polort=5
            3dDeconvolve -input ${run_1_dir}/${sub}_task-${task}_run-1.results/pb05.${sub}.r01.scale+orig.BRIK.gz ${run_2_dir}/${sub}_task-${task}_run-2.results/pb05.${sub}.r01.scale+orig.BRIK.gz \
            -mask ${all_run_dir}/${sub}_task-${task}_mask_anat+orig.BRIK.gz \
            -polort 5 \
            -local_times \
            -GOFORIT 1 \
            -num_stimts 2 \
            -stim_times_IM 1 ${behavior_dir}/spliting_files_mvpa/${sub}_task-${task}_RED_block_MVPA.1D 'dmUBLOCK' -stim_label 1 RiskyReward \
            -stim_times_IM 2 ${behavior_dir}/spliting_files_mvpa/${sub}_task-${task}_WHITE_block_MVPA.1D 'dmUBLOCK(1)' -stim_label 2 NonriskReward \
            -bucket ${deconvolve_dir}/${sub}_task-${task}_MVPA.results/${sub}_task-${task}_MVPA.BLOCK.nii \
            -jobs 8
        else
            echo "${sub}_task-${task}_MVPA.BLOCK.nii already exists"
        fi
    else    
        echo "there is no preprocessed data for ${sub}_task-${task}"
    fi
done

# USUALLY WE SHOULD LET '-GOFORIT 1' AS DEFAULT
# Here I use -GOFORIT 3 because  Any single event that is just slightly into the TR might lead to this. They are not exactly collinear, but close. 
# I follow the suggestion from https://discuss.afni.nimh.nih.gov/t/tent-in-3ddeconvolve/6788/3 and from https://discuss.afni.nimh.nih.gov/t/error-while-running-3ddeconvolve-with-stim-times-im/3797/6
# A single beta is estimated from just a few time points, and motion generally censors multiple time points per motion event. In some cases censoring might leave a regressor with only 1 non-zero time 
# point (which will model the data (and noise) exactly) or 0 non-zero time points (leading to a GOFORIT warning and to beta=0, since there is no data to model). Censoring can indeed have a large effect when regressors only have a few non-zero time points, and the difference may be driven by spiky noise, since the subject was presumably moving at those time points.


#choosing dmUBLOCK is that the pump number (duration of a RED trial) indeed influence their brain response due to risk of popping. 
#choosing dmUBLOCK(1) is that the pump number (duration of a WHITE trial) does not influence their brain response due to no risk
# DevC_P006_task-BART_mask_anat+orig_allruns.BRIK.gz
# DevC_P043_task-BART_mask_anat+orig_allruns.BRIK.gz

# Potential change I may make
    # -stim_times 1 ${behavior_dir}/spliting_files_mvpa/${sub}_task-${task}_RED_block_MVPA.1D 'dmUBLOCK(1)' -stim_label 1 RiskyReward \
    # -stim_times 3 ${sub}_task-${task}_GRAY_block_MVPA.1D 'dmUBLOCK(1)' -stim_label 3 Neutral \
    # -mask ${preproc_output}/${task}/all_runs/${sub}_task-${task}__mask_anat+orig_allruns \
    # -concat .1D \
    # -concat ${all_run_dir}/allruns_timepoints.1D \
    # -x1D stdout: | \
    # 1dplot -stdin -thick \
    #     -ynames 'dmUB_Risky_Reward' 'dmUB(1)_NonriskReward'



############ Notes from AFNI Website #################
# [-stim_times_AM1 k tname Rmodel]                                       
#    Similar, but generates an amplitude modulated response model.       
#    The 'tname' file should consist of 'time*amplitude' pairs. 

# [-stim_times_AM2 k tname Rmodel]   Parametric modulation                                    
#   Similar, but generates 2 response models: one with the mean         
#    amplitude and one with the differences from the mean.

#  -stim_times_AM1 and -stim_times_AM2 now take files with more          
#    than 1 amplitude attached to each time; for example,                
#      33.7*9,-2,3                                                       
#    indicates a stimulus at time 33.7 seconds with 3 amplitudes         
#    attached (9 and -2 and 3).  In this example, -stim_times_AM2 would  
#    generate 4 response models: 1 for the constant response case        
#    and 1 scaled by each of the amplitude sets.

#  -stim_times_AM1 and -stim_times_AM2 now have 1 extra response model   
#  function available:                                                   
#    dmBLOCK (or dmBLOCK4 or dmBLOCK5)                                   
#  where 'dm' means 'duration modulated'.  If you use this response      
#  model, then the LAST married parameter in the timing file will        
#  be used to modulate the duration of the block stimulus.  Any          
#  earlier parameters will be used to modulate the amplitude,            
#  and should be separated from the duration parameter by a ':'          
#  character, as in '30*5,3:12' which means (for dmBLOCK):               
#    a block starting at 30 s,                                           
#    with amplitude modulation parameters 5 and 3,                       
#    and with duration 12 s.

# If you are NOT doing amplitude modulation at the same time     
#         (and so you only have 1 'married' parameter per time), use     
#         '-stim_times_AM1' with dmBLOCK.  If you also want to do        
#         amplitude modulation at the same time as duration modulation   
#         (and so you have 2 or more parameters with each time), use     
#         '-stim_times_AM2' instead.

#  *N.B.: You can also use dmBLOCK with -stim_times_IM, in which case    
#         each time in the 'tname' file should have just ONE extra       
#         parameter -- the duration -- married to it, as in '30:15',   
                                                                       
# [-stim_times_IM k tname Rmodel]                                        
#    Similar, but each separate time in 'tname' will get a separate      
#    regressor; 'IM' means 'Individually Modulated' -- that is, each     
#    event will get its own amplitude estimated.  Presumably you will    
#    collect these many amplitudes afterwards and do some sort of        
#    statistics or analysis on them.                                     
#  *N.B.: Each time in the 'tname' file will get a separate regressor.   
#         If some time is outside the duration of the imaging run(s),    
#         or if the response model for that time happens to hit only     
#         censored-out data values, then the corresponding regressor     
#         will be all zeros.  Normally, 3dDeconvolve will not run        
#         if the matrix has any all zero columns.  To carry out the      
#         analysis, use the '-allzero_OK' option.  Amplitude estimates   
#         for all zero columns will be zero, and should be excluded      
#         from any subsequent analysis.  (Probably you should fix the    
#         times in the 'tname' file instead of using '-allzero_OK'.)     
           
# 3dDeconvolve -nodata 350 1 -polort -1 -num_stimts 5 \
#              -stim_times_AM1 1 /mnt/LifeHistoryLab/BIC_Data/1902008564_data/q.1D 'dmUBLOCK' \
#              -stim_times_AM1 2 /mnt/LifeHistoryLab/BIC_Data/1902008564_data/q.1D 'dmUBLOCK(1)' \
#              -stim_times_AM1 3 /mnt/LifeHistoryLab/BIC_Data/1902008564_data/q.1D 'dmUBLOCK(-4)' \
#              -stim_times_IM 4 /mnt/LifeHistoryLab/BIC_Data/1902008564_data/q.1D 'dmBLOCK' \
#              -stim_times_AM1 5 /mnt/LifeHistoryLab/BIC_Data/1902008564_data/q.1D 'dmBLOCK(1)' \
#              -x1D stdout: | \
# 1dplot -stdin -thick \
#        -ynames 'dmUBLOCK' 'dmUB(1)' 'dmUB(-4)' 'dmB' 'dmB(1)'


############# Notes from Lissa's script devconvolve #################

# 3dDeconvolve -input run1.preproc.nii run2.preproc.nii run3.preproc.nii run4.preproc.nii run5.preproc.nii run6.preproc.nii run7.preproc.nii run8.preproc.nii \
#             -polort 1 \
#             -local_times \
#             -censor allRuns.censor.1D \
#             -num_stimts 4 \
#             -stim_times_IM 1 cars.block.onsets.1D 'BLOCK(9,1)' -stim_label 1 cars \
#             -stim_times_IM 2 faces.block.onsets.1D 'BLOCK(9,1)' -stim_label 2 faces \
#             -stim_times_IM 3 houses.block.onsets.1D 'BLOCK(9,1)' -stim_label 3 houses \
#             -stim_times_IM 4 shoes.block.onsets.1D 'BLOCK(9,1)' -stim_label 4 shoes \
#             -bucket MVPA.BLOCK.nii \



# ++ Wrote matrix values to file stdout:.xmat.1D
# ++ ========= Things you can do with the matrix file =========
# ++ (a) Linear regression with ARMA(1,1) modeling of serial correlation:

# 3dREMLfit -matrix stdout:.xmat.1D \
#  -input "/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/preproc_output/BART/run-1/DevC_P006_task-BART_run-1.results/pb05.DevC_P006.r01.scale+orig.BRIK.gz /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/preproc_output/BART/run-2/DevC_P006_task-BART_run-2.results/pb05.DevC_P006.r01.scale+orig.BRIK.gz" \
#  -mask /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/preproc_output/BART/all_runs/DevC_P006_task-BART_mask_anat+orig.BRIK.gz \
#  -Rbuck /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE/DevC_P006_task_BART_MVPA.results/DevC_P006_task-BART_MVPA.BLOCK_REML -Rvar /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE/DevC_P006_task_BART_MVPA.results/DevC_P006_task-BART_MVPA.BLOCK_REMLvar -verb
 
# ++ N.B.: 3dREMLfit command above written to file /mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE/DevC_P006_task_BART_MVPA.REML_cmd
# ++ (b) Visualization/analysis of the matrix via ExamineXmat.R
# ++ (c) Synthesis of sub-model datasets using 3dSynthesize

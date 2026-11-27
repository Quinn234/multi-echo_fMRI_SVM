####### MVPA Analaysis #########
# ### Xinyi ###### 
# MVPA Step 9 By using training set, generate a model and test it in testing set for each ptp 
# k-fold=5, cross validation; 1000 permutation testing

# Using nilearn decoding toolbox
# RiskReward = Red Balloon lable as 1; NonriskReward = White Balloon label as 2

import numpy as np
import pandas as pd
import nilearn
from nilearn.image import index_img, load_img
from nilearn.decoding import Decoder
from pathlib import Path
from sklearn.model_selection import permutation_test_score
from sklearn.model_selection import cross_val_predict
from sklearn.metrics import accuracy_score
import nibabel as nib
from sklearn.model_selection import StratifiedKFold


# ==============================================================================
# 1. PATH CONFIGURATIONS
# ==============================================================================
subjects = input("Participant(s): ").strip().split()
task = input('Task: ').strip().split()
run = input('Run number: ').strip().split()
masks = input('ROI mask: ').strip().split()  
k_fold_num = input("K Fold number: ")

k_fold_num = int(k_fold_num) if k_fold_num else 5
task = task[0] if task else 'BART'
run = run[0] if run else '1'

if not subjects:
    subjects_file = Path("/Volumes/onemodern/redcloud082724/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/locations") / f"task-{task}_run-{run}_PTP_N44.txt"
    subjects = subjects_file.read_text().strip().split('\n')
if not masks:
    masks_file = Path("/Volumes/onemodern/redcloud082724/mnt/LifeHistoryLab/BIC_Data/1902008564_data/raw/locations") / f"ROI_mask_for_MVPA.txt"
    masks = masks_file.read_text().strip().split('\n')

num_participants = len(subjects)
print("Number of participants:", num_participants)

deconvolve_dir = Path("/Volumes/onemodern/redcloud082724/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/DECONVOLVE")
roi_mask_dir = Path("/Volumes/onemodern/redcloud082724/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/PREPROC/preproc_output/BART/ROI_mask")
group_dir = Path(f"/Volumes/onemodern/redcloud082724/mnt/LifeHistoryLab/BIC_Data/1902008564_data/analysis/MVPA/GROUPLEVEL/BART_GroupN_{num_participants}")

group_dir.mkdir(parents=True, exist_ok=True)

# ==============================================================================
# 2. NILEARN PERMUTATION DECODER LOOP
# ==============================================================================

Details_Group_Results = []

for sub in subjects:
    sub_deconvolve_dir = deconvolve_dir / f"{sub}_task-{task}_MVPA.results"    

    if sub_deconvolve_dir.exists() and sub_deconvolve_dir.is_dir():
        print(f"\n=========================================")
        print(f"Processing Participant: {sub}")
        print(f"=========================================")

        block_img_path = sub_deconvolve_dir / f"{sub}_task-{task}_MVPA.BLOCK.nii"
        block_info_path = sub_deconvolve_dir / f"{sub}_task-{task}_bucket_3dinfo.txt"

        if block_info_path.exists():
            bucket_text = block_info_path.read_text()
            n_risky = bucket_text.count("RiskyReward#")
            n_nonrisk = bucket_text.count("NonriskReward#")
        else:
            raise FileNotFoundError(f"Missing 3dinfo file for {sub} at {block_info_path}")

        print(f"Detected sub-bricks -> RiskyReward (1): {n_risky} | NonriskReward (2): {n_nonrisk}")

        conditions = np.array([1] * n_risky + [2] * n_nonrisk)
        total_trials = n_risky + n_nonrisk

        img_5d = nib.load(block_img_path)
        if len(img_5d.shape) == 5:
            print(f" Safely squeezing 5D image {img_5d.shape} down to 4D...")
            data_4d = img_5d.get_fdata()[:, :, :, 0, :]
            fmri_images_full = nib.Nifti1Image(data_4d, img_5d.affine) 
        else:
            fmri_images_full = img_5d

        fmri_images = index_img(fmri_images_full, slice(1, total_trials + 1))
        
        for mask in masks:
            sub_csv_path = group_dir / f"{sub}_mask-{mask}_decoding_results.csv"
            if sub_csv_path.exists():
                print(f"   --> Skipping mask {mask} for {sub}: Result CSV already exists.")
                continue

            print(f"\n--- Running ROI: {mask} for participant {sub} ---")
            mask_file_path = roi_mask_dir / f"{sub}_task-{task}_roi_mask" / f"{sub}_task-{task}_bilateral_{mask}_mask_1.5mm.nii"
            
            if not mask_file_path.exists():
                print(f"Warning: Mask file not found at {mask_file_path}. Skipping this mask.")
                continue
            
            roi_mask = nilearn.image.load_img(mask_file_path)

            cv_s=StratifiedKFold(
                n_splits=5,
                shuffle=True,
                random_state=42
            )


            decoder = Decoder(
                estimator='svc',             
                mask=roi_mask,               
                standardize="zscore_sample", 
                cv=cv_s,               
                scoring='roc_auc',  # Explicitly set scoring to ROC AUC       
                n_jobs=1
            )

            # decoder = Decoder(
            #     estimator='svc',             
            #     mask=roi_mask,               
            #     standardize="zscore_sample", 
            #     cv=k_fold_num,               
            #     scoring='roc_auc',  # Explicitly set scoring to ROC AUC       
            #     n_jobs=1
            # )

            # Fit decoder
            print(f"Computing true {k_fold_num}-fold CV metrics for {sub}...")
            decoder.fit(fmri_images, conditions)

            # Extract the 5 AUC scores for the folds (Assuming class 1 is your target)
            # Nilearn returns a dictionary. We index with condition '1'
            fold_auc_scores = decoder.cv_scores_[1]
            true_cv_auc = np.mean(fold_auc_scores)
            
            print(f"AUC for each fold: {fold_auc_scores}")
            print(f"Successfully computed true {k_fold_num}-fold CV Mean AUC: {true_cv_auc:.4f}")

            fmri_masked = decoder.masker_.transform(fmri_images)

            # Accuracy score prediction
            predicted_conditions = cross_val_predict(
                decoder.estimator, 
                fmri_masked, 
                conditions, 
                cv=k_fold_num
            )
            true_cv_accuracy = accuracy_score(conditions, predicted_conditions)
            
            # Permutation Analysis
            print(f"Running 1000 label permutations...")
            true_score, null_cv_scores, empirical_p_value = permutation_test_score(
                decoder.estimator,    
                fmri_masked,           
                conditions,
                cv=cv_s,         
                n_permutations=1000,   
                n_jobs=-1, 
                scoring='roc_auc'  # Optimize for AUC
            )

            # true_score, null_cv_scores, empirical_p_value = permutation_test_score(
            #     decoder.estimator,    
            #     fmri_masked,           
            #     conditions,
            #     cv=k_fold_num,         
            #     n_permutations=1000,   
            #     n_jobs=-1, 
            #     scoring='roc_auc'  # Optimize for AUC
            # )

            empirical_chance_level = null_cv_scores.mean()

            print(f"[{sub}] True Mean 5-Fold AUC: {true_cv_auc:.4f}")
            print(f"[{sub}] True Mean 5-Fold Accuracy: {true_cv_accuracy * 100:.2f}%")
            print(f"[{sub}] Empirical Chance Level: {empirical_chance_level:.4f}")
            print(f"[{sub}] Permutation p-value: {empirical_p_value:.4f}")

            # Append the data. Notice we are adding the individual folds now.
            sub_results = pd.DataFrame({
                "Participants": sub,
                "mask": mask,
                "Fold_1_AUC": fold_auc_scores[0],
                "Fold_2_AUC": fold_auc_scores[1],
                "Fold_3_AUC": fold_auc_scores[2],
                "Fold_4_AUC": fold_auc_scores[3],
                "Fold_5_AUC": fold_auc_scores[4],
                "Mean_AUC_score": true_cv_auc,
                "Accuracy_score": true_cv_accuracy,
                "AUC_Empirical_Chance": empirical_chance_level, 
                "AUC_Permutation_p": empirical_p_value          
            }, index=[0])
            
            sub_results.to_csv(sub_csv_path, index=False)
            Details_Group_Results.append(sub_results)

# ==============================================================================
# 3. AGGREGATE RESULTS
# ==============================================================================
if Details_Group_Results:
    Details_Group_Results_total = pd.concat(Details_Group_Results, ignore_index=True)
    group_file_path = group_dir / f"RRvsGR_MVPA_N{num_participants}_Results_1000Permutation_5kfold08202026.csv"
    Details_Group_Results_total.to_csv(group_file_path, index=False)
    print(f"\nGroup results successfully saved to: {group_file_path}")
else:
    print("No subjects were processed.")



# # ####### Optional #############
# # 1. Gather all individual mask CSV files
# csv_files = list(group_dir.glob("*_mask-*_decoding_results.csv"))

# if not csv_files:
#     print(f"No individual mask CSV files found in {group_dir}")
# else:
#     # 2. Read all files into a list of DataFrames
#     all_data_list = [pd.read_csv(f) for f in csv_files]
    
#     # 3. Concatenate all rows together (keeps the exact same format/columns)
#     df_combined = pd.concat(all_data_list, ignore_index=True)

#     # 4. Save out your master group summary file with your requested name
#     output_master_path = group_dir / f"RRvsGR_MVPA_N{num_participants}_Results_1000Permutation_5kfold08202026.csv"
#     df_combined.to_csv(output_master_path, index=False)

#     print(f"\nSuccess! Concatenated {len(csv_files)} files row-by-row.")
#     print(f"Master group file saved to: {output_master_path}")
    
#     # Show a quick preview to confirm the format
#     print("\nGenerated Columns Preview:")
#     print(df_combined.head(5))


# if not csv_files:
#     print(f"No individual mask CSV files found in {group_dir}")
# else:
#     # 2. Read and combine all files into one long dataframe
#     all_data_list = [pd.read_csv(f) for f in csv_files]
#     df_long = pd.concat(all_data_list, ignore_index=True)

#     # 3. Pivot the dataframe from long format to your exact wide format
#     df_wide = df_long.pivot(
#         index="Participants", 
#         columns="mask", 
#         values=["AUC_score", "AUC_Empirical_Chance", "AUC_Permutation_p"]
#     )

#     # 4. Flatten the multi-level column names to match your exact requested style: {mask}_{metric}
#     df_wide.columns = [f"{mask}_{metric}" for metric, mask in df_wide.columns]
    
#     # Reset index so 'Participants' becomes a standard column again
#     df_wide = df_wide.reset_index()

#     # 5. Save out your master group summary file
#     output_master_path = group_dir / "BART_MVPA_Master_GroupN44_Results_Wide.csv"
#     df_wide.to_csv(output_master_path, index=False)

#     print(f"\n Success! Combined {len(csv_files)} files into wide format.")
#     print(f"Master group file saved to: {output_master_path}")
    
#     # Show a quick preview of what the columns look like
#     print("\nGenerated Columns Preview:")
#     print(df_wide.head(2))

spec=human # or chimp or macaque
hemi=L # or R

tmpdir=$(mktemp -d "/tmp/qc.XXXXXXXXXX")

# use a threshold of 30 % for the tractogram
threshold=0.3

# species-specific overhead
if [ $spec == 'human' ]; then
  subs=('sub-01' 'sub-02' 'sub-03') # etc
  n=`echo ${#subs[@]}`
fi
  tract_list="af cst ifo ilf mdlf slf3 vof_l"

for s in $(seq 1 $n); do
  subj=${subs[$s-1]}
  OD=/subject/output/folder

  for m in $tract_list; do
    echo $spec $hemi $subj${m}
    # tractogram in species standard space
    tractogram=$OD/tracts/${m}/density_cert.nii.gz
    # threshold tractogram
    fslmaths ${tractogram} -thr $threshold ${tmpdir}/tractogram_t.nii.gz

    # quantify dispersion within thresholded tractogram for the 3 dyads
    for dyad in dyads1 dyads2 dyads3; do
      mean_dispersion=`fslstats ${OD}/${dyad}_dispersion_std.nii.gz -k ${tmpdir}/tractogram_t.nii.gz -m`
      echo ${mean_dispersion} > ${tmpdir}/mean_dispersion_${dyad}.txt
    done

    # quantify tract complexity for the three pairs of dyads
    # dyad1, dyad2
    fslmaths ${OD}/dyads1_std.nii.gz -mul ${OD}/dyads2_std.nii.gz -Tmean -mul 3 -abs -cos -mul -1 -add 1 ${tmpdir}/complex1_2.nii.gz
    # dyad2, dyad3
    fslmaths ${OD}/dyads2_std.nii.gz -mul ${OD}/dyads3_std.nii.gz -Tmean -mul 3 -abs -cos -mul -1 -add 1 ${tmpdir}/complex2_3.nii.gz
    # dyad1, dyad3
    fslmaths ${OD}/dyads1_std.nii.gz -mul ${OD}/dyads3_std.nii.gz -Tmean -mul 3 -abs -cos -mul -1 -add 1 ${tmpdir}/complex1_3.nii.gz

    for pair in "complex1_2" "complex2_3" "complex1_3"; do
      mean_complexity=`fslstats ${tmpdir}/${pair}.nii.gz -k ${tmpdir}/tractogram_t.nii.gz -m`

      echo ${mean_complexity} > ${tmpdir}/mean_${pair}.txt
      # write out each subject's value for complexity for each dyad pair
      echo ${mean_complexity} >> ~/scratch/MSMstuff/complexity_${spec}_${hemi}_${m}_${pair}.txt
    done

    # write out each subject's average dispersion measure across the three dyads
    dispersion_dyad1=$(head -n 1 ${tmpdir}/mean_dispersion_dyads1.txt)
    dispersion_dyad2=$(head -n 1 ${tmpdir}/mean_dispersion_dyads2.txt)
    dispersion_dyad3=$(head -n 1 ${tmpdir}/mean_dispersion_dyads3.txt)
    dispersion_mean=`echo "($dispersion_dyad1 + $dispersion_dyad2 + $dispersion_dyad3)/3" | bc -l`
    echo ${dispersion_mean} >> ~/scratch/MSMstuff/dispersion_${spec}_${hemi}_${m}.txt

    # write out each subject's average complexity measure across the three dyads
    complex_dyad1_2=$(head -n 1 ${tmpdir}/mean_complex1_2.txt)
    complex_dyad2_3=$(head -n 1 ${tmpdir}/mean_complex2_3.txt)
    complex_dyad1_3=$(head -n 1 ${tmpdir}/mean_complex1_3.txt)
    complexity_mean=`echo "($complex_dyad1_2 + $complex_dyad2_3 + $complex_dyad1_3)/3" | bc -l`
    echo ${complexity_mean} >> ~/scratch/MSMstuff/complexity_${spec}_${hemi}_${m}.txt

  done # m
done # subj

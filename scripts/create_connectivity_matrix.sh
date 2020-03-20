#! /bin/sh

spec='human'
hemi=L

rootdir='/myPath/'
if [ $spec == 'human' ];  then
    subs=('sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05')
    stdbrain=MNI152_T1_2mm_brain.nii.gz
elif [ $spec == 'chimp' ];  then
    subs=('C1' 'C1' 'C1' 'C1' 'C1')
    stdbrain=ChimpYerkes29_AverageT1w_restore
elif [ $spec == 'macaque' ];  then
    subs=('M1' 'M2' 'M3' 'M4' 'M5')
    stdbrain=T1w_brain_10space.nii.gz
fi


for subj in $subs; do
    echo "Working on $subj"
    bpxdir=$rootdir/data/human/tractography/sub-$subj/dwi.bedpostX
    std2diff=$rootdir/data/human/tractography/sub-$subj/standard_to_diffusion_warp
    diff2std=$rootdir/data/human/tractography/sub-$subj/diffusion_to_standard_warp
    mt=$rootdir/data/human/tractography/sub-$subj/sub-${subj}.${hemi}.midthickness.20k_fs_LR.surf.gii

    outdir=$rootdir/sub-${subj}_surfseed_${hemi}
    mkdir -p $outdir

    o=" --xfm=$std2diff --invxfm=$diff2std"
    o=" $o --seed=$mt --omatrix2 --target2=$stdbrain -P 10000 --seedref=$stdbrain"

    echo "$bpxdir $outdir $o"
    quicktrack_gpu $bpxdir $outdir $o

done

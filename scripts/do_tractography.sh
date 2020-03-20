#! /bin/sh
#### ------------------
# adapt this section
rootdir=/home/fs0/neichert/scratch/project_msm
#### ------------------

spec='human'
for subj in 01 02; do
    echo "run for sub-$subj"
    # input files
    bpxdir=$rootdir/data/${spec}/tractography/sub-$subj/dwi.bedpostX
    std2diff=$rootdir/data/${spec}/tractography/sub-$subj/dwi/standard_to_diffusion_warp
    diff2std=$rootdir/data/${spec}/tractography/sub-$subj/diffusion_to_standard_warp
    structureList=$rootdir/data/${spec}/tractography/structureList
    protocols=$rootdir/data/${spec}/tractography
    outdir=$rootdir/data/${spec}/tractography/sub-$subj

    # root directory for output files/folders
    mkdir -p $outdir

    # Run autoPtx (included in FSL)
    fsl_autoPtx -bpx $bpxdir \
    -out $outdir \
  	-str $structureList \
    -p $protocols \
  	-stdwarp $std2diff $diff2std -res 2
done

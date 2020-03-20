#!/usr/bin/env bash

for spec in human macaque chimp; do
  echo "do " $spec

  if [ $spec == 'human' ]
  then
  	subs=('sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05' 'sub-06' 'sub-07' 'sub-08' 'sub-09' 'sub-10' 'sub-11' 'sub-12' 'sub-13' 'sub-14' 'sub-15' 'sub-16' 'sub-17' 'sub-18' 'sub-19' 'sub-20')
  	n=`echo ${#subs[@]}`
  elif [ $spec == 'chimp' ]
  then
    subs=('Bo' 'Cheeta' 'Lulu' 'Wenka' 'Foxy' 'group')
    #subs=('group')
    n=`echo ${#subs[@]}`
    ref=ChimpYerkes29_AverageT1w_restore_brain_15mm.nii.gz
    mat=$rootdir/std_08_to_15mm.mat
  elif [ $spec == 'macaque' ]
  then
  	subs=('hilary' 'oddie' 'rolo' 'umberto''decresp')
    n=`echo ${#subs[@]}`
  fi
  tract_list="af_l cst_l ifo_l ilf_l mdlf_l slf3_l      af_r cst_r ifo_r ilf_r mdlf_r slf3_r"


  for m in $tract_list; do
    echo "do tract " $m

    if [ $spec == 'chimp' ]
    then
      for s in $(seq 1 $n); do
      	subj=${subs[$s-1]}
        for img in density densityNorm density_lengths; do
          if [ `fslval $rootdir/$subj/tracts/${m}/${img}.nii.gz pixdim1` == 0.800000 ]; then
            echo "warp to 15mm"
            applywarp -i $rootdir/$subj/tracts/${m}/${img}.nii.gz -r $ref -o $rootdir/$subj/tracts/${m}/${img}.nii.gz --premat=$mat --interp=spline
          fi
        done
      done
    fi

    # log normalize the tract density and store as density_cert
    for s in $(seq 1 $n); do
    	subj=${subs[$s-1]}
      fslmaths $rootdir/$subj/tracts/${m}/density.nii.gz -log $rootdir/$subj/tracts/${m}/density_cert.nii.gz
      fslmaths $rootdir/$subj/tracts/${m}/density_cert.nii.gz  -div `fslstats $rootdir/$subj/tracts/${m}/density_cert.nii.gz -R | awk '{print $2}'` $rootdir/$subj/tracts/${m}/density_cert.nii.gz
    done # s

    # group-level results
    rm -r $OD/${m}
    mkdir $OD/${m}
    fsladd $OD/${m}/density -m $rootdir/*/tracts/${m}/density.nii.gz
    fsladd $OD/${m}/density_cert -m $rootdir/*/tracts/${m}/density_cert.nii.gz
    fsladd $OD/${m}/densityNorm -m $rootdir/*/tracts/${m}/densityNorm.nii.gz
    fsladd $OD/${m}/density_add -m $rootdir/*/tracts/${m}/density.nii.gz

  done # m
done # spec

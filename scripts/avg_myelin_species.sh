#! /bin/sh
s
usage() {
cat <<EOF
******************************************************************************
bash avg_myelin_species.sh --resample
bash avg_myelin_species.sh --avg0
bash avg_myelin_species.sh --MSMsulc
bash avg_myelin_species.sh --MSMmyelin # 1 h
bash avg_myelin_species.sh --avg1
EOF
}

# ------------------------------ #
# subfunction to parse the input arguments
# ------------------------------ #
getoption() {
  sopt="--$1"
  shift 1
  for fn in $@ ; do
  	if [[ -n $(echo $fn | grep -- "^${sopt}=") ]] ; then
      echo $fn | sed "s/^${sopt}=//"
      return 0
    elif [[ -n $(echo $fn | grep -- "^${sopt}$") ]] ; then
      echo "TRUE" # if not string is given, set it the value of the option to TRUE
      return 0
  	fi
  done
}
# if no arguments are given, or help is requested, return the usage
if [[ $# -eq 0 ]] || [[ $(getoption "help" "$@") = "TRUE" ]] ; then usage; exit 0; fi


#### ------------------
rootdir=/myPath/
MSMDIR=/msmPath/
#### ------------------

#### set defaults
spec_list='human chimp macaque'
hemi_list='L'
configdir=$rootdir/data/configdir

for spec in $spec_list; do
    OD=${rootdir}/data/${spec}
    for hemi in $hemi_list; do

        # species-specific settings
        if [ $spec == 'human' ];  then
            subs=('sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05')
            native_sphere=$OD/human.${hemi}.sphere.32k_fs_LR.surf.gii
        elif [ $spec == 'chimp' ];  then
            subs=('C1' 'C1' 'C1' 'C1' 'C1')
            native_sphere=$OD/ChimpYerkes29.${hemi}.sphere.20k_fs_LR.surf.gii
        elif [ $spec == 'macaque' ];  then
            subs=('M1' 'M2' 'M3' 'M4' 'M5')
            native_sphere=$OD/MacaqueOxford5.${hemi}.sphere.164k_fs_LR.surf.gii
        fi

        # input files
        n_subs=`echo ${#subs[@]}`
        my_sphere=$rootdir/data/20k.${hemi}.sphere.surf.gii
        avg_0_sulc=$OD/${spec}.${hemi}.sulc.avg_0.func.gii
        avg_0_myelin=$OD/${spec}.${hemi}.myelin.avg_0.func.gii
        avg_1_sulc=$OD/${spec}.${hemi}.sulc.avg_1.func.gii
        avg_1_myelin=$OD/${spec}.${hemi}.myelin.avg_1.func.gii

        # initialize counter and command string for averages
        no=1
        cmd_str_sulc_0=''
        cmd_str_myelin_0=''
        cmd_str_sulc_1=''
        cmd_str_myelin_1=''

        for sub in $(seq 1 $n_subs); do
            subj=${subs[$sub-1]}

            if [ $spec == 'human' ];  then
                native_myelin=$OD/${subj}.${hemi}.MyelinMap_BC.32k_fs_LR.func.gii
                native_sulc=$OD/${subj}.${hemi}.sulc.32k_fs_LR.shape.gii
            elif [ $spec == 'chimp' ];  then
                native_myelin=$OD/${subj}.${hemi}.MyelinMap_BC.20k_fs_LR.func.gii
                native_sulc=$OD/${subj}.${hemi}.sulc.20k_fs_LR.shape.gii
            elif [ $spec == 'macaque' ];  then
                native_myelin=$OD/${subj}.${hemi}.MyelinMap_BC.func.gii
                native_sulc=$OD/${subj}.${hemi}.sulc.func.gii
            fi

            # resample native maps to common 20k sphere
            if [[ $(getoption "resample" "$@") = "TRUE" ]] ; then
                echo $spec $subj $hemi " resample to 20k sphere"
                myelin_20k=$OD/$subj.${hemi}.MyelinMap_BC.20k_fs_LR_res.func.gii
                sulc_20k=$OD/${subj}.${hemi}.sulc.20k_fs_LR_res.shape.gii
                wb_command -metric-resample $native_myelin $native_sphere $my_sphere BARYCENTRIC $myelin_20k
                wb_command -metric-resample $native_sulc $native_sphere $my_sphere BARYCENTRIC $sulc_20k

            # create initial average map of all subjects maps
            elif [[ $(getoption "avg0" "$@") = "TRUE" ]] ; then
                cmd_str_sulc_0="$cmd_str_sulc -metric $OD/${subj}.${hemi}.sulc.20k_fs_LR_res.shape.gii"
                cmd_str_sulc_0="$cmd_str_sulc -metric $OD/${subj}.${hemi}.MyelinMap_BC.20k_fs_LR_res.func.gii"

            # create initial average map of maps that were registered using MSM
            elif [[ $(getoption "avg1" "$@") = "TRUE" ]] ; then
                cmd_str_sulc_1="$cmd_str_sulc -metric $OD/${subj}.${hemi}.sulc.transformed_and_reprojected.func.gii"
                cmd_str_sulc_1="$cmd_str_sulc -metric $OD/${subj}.${hemi}.myelin.transformed_and_reprojected.func.gii"

            # run MSM based on maps of suclcal depth
            elif [[ $(getoption "MSMsulc" "$@") = "TRUE" ]] ; then
                # compose MSM-command
                cat <<EOF > $rootdir/data/$spec/MSM_command_sulc.txt
                $MSMDIR/msm --inmesh=$my_sphere \
                --indata=$OD/${subj}.${hemi}.sulc.20k_fs_LR_res.shape.gii --refdata=$avg_0_sulc \
                --conf=$configdir/sulc_species --levels=4 -o $OD/${subj}.${hemi}.sulc.
EOF
                # final command
                cmd=`cat $rootdir/data/$spec/MSM_command_sulc.txt`
                echo "running MSM_sulc for subj $subj $hemi hemi"
                $cmd

            # run MSM based on maps of cortical myelin
            elif [[ $(getoption "MSMmyelin" "$@") = "TRUE" ]] ; then
                # compose MSM-command
                cat <<EOF > $rootdir/data/$spec/MSM_command_myelin.txt
                $MSMDIR/msm --inmesh=$my_sphere \
                --indata=$OD/${subj}.${hemi}.MyelinMap_BC.20k_fs_LR_res.func.gii --refdata=$avg_0_myelin \
                --conf=$configdir/myelin_species --levels=3 -o $OD/${subj}.${hemi}.myelin. \
                --trans=$OD/${subj}.${hemi}.sulc.sphere.reg.surf.gii
EOF
                # final command
                cmd=`cat $rootdir/data/$spec/MSM_command_myelin.txt`
                echo "running MSM_myelin for subj $subj $hemi hemi"
                $cmd
            fi
        done # subj

        # average 0 maps
        if [[ $(getoption "avg0" "$@") = "TRUE" ]] ; then
            echo "average 0"
            wb_command -metric-merge $avg_0_sulc $cmd_str_sulc_0
            wb_command -metric-reduce $avg_0_sulc -MEAN $avg_0_sulc
            wb_command -metric-merge $avg_0_myelin $cmd_str_myelin_0
            wb_command -metric-reduce $avg_0_myelin -MEAN $avg_0_myelin

        # average 1 maps
        elif [[ $(getoption "avg1" "$@") = "TRUE" ]] ; then
            echo "average 1"
            wb_command -metric-merge $avg_1_sulc $cmd_str_sulc_1
            wb_command -metric-reduce $avg_1_sulc -MEAN $avg_1_sulc
            wb_command -metric-merge $avg_1_myelin $cmd_str_myelin_1
            wb_command -metric-reduce $avg_1_myelin -MEAN $avg_1_myelin
        fi
    done
done

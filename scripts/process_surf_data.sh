#! /bin/sh

rootdir='myPath'

do_preprocessing=1 # if 0: only warping

# order: AF, CST, IFO, ILF, MDLF, SLF3 VOF
thr_list=(0.75 0.6 0.75 0.7 0.7 0.85 0.6)
for spec in human chimp macaque; do
    echo "do $spec"
    ### -------
    # species specific settings
    ### ------
    for hemi in R; do
        echo "do ${hemi}H"

        if [ $spec == 'human' ];  then
            subs=('sub-01' 'sub-02' 'sub-03' 'sub-04' 'sub-05' 'sub-06' 'sub-07' 'sub-08' 'sub-09' 'sub-10' 'sub-11' 'sub-12' 'sub-13' 'sub-14' 'sub-15' 'sub-16' 'sub-17' 'sub-18' 'sub-19' 'sub-20', 'group')
            n=`echo ${#subs[@]}`
            kernel=4
            colour=fsl_red
            human_sphere=$rootdir/${hemi}.sphere.32k_fs_LR.surf.gii
            insula=$rootdir/h_insula_${hemi}_inv.func.gii
            MW=$rootdir/h_MW_${hemi}_inv.func.gii
            PC=$rootdir/h_PC3_${hemi}.func.gii

        elif [ $spec == 'chimp' ]; then
            subs=('C1' 'C2' 'C3' 'C4' 'C5' 'group')
            n=`echo ${#subs[@]}`
            kernel=3
            surf_sm=~/scratch/MrCat-dev/data/chimpanzee/Chimplate/fsaverage_LR20k/ChimpYerkes29.${hemi}.midthickness.20k_fs_LR.surf.gii
            colour=fsl_blue
            chimp_sphere=~/scratch/MrCat-dev/data/chimpanzee/Chimplate/fsaverage_LR20k/ChimpYerkes29.${hemi}.sphere.20k_fs_LR.surf.gii
            insula=$rootdir/c_insula_${hemi}_inv.func.gii
            MW=$rootdir/c_MW_${hemi}_inv.func.gii

        elif [ $spec == 'macaque' ]; then
            subs=('M1' 'M2' 'M3' 'M4' 'M5' 'group')
            n=`echo ${#subs[@]}`
            kernel=2
            surf_sm=$rootdir/macaque.20k.midthickness.${hemi}.surf.gii
            insula=$rootdir/m_insula_${hemi}_inv.func.gii
            MW=$rootdir/m_MW_${hemi}_inv.func.gii
            colour=fsl_green
        fi

        if [ $hemi == 'L' ]; then
            tract_list=('af_l' 'cst_ne_l' 'ifo_l' 'ilf_l' 'mdlf_l' 'slf3_l' 'vof_l')
        elif [ $hemi == 'R' ]; then
            tract_list=('af_r' 'cst_ne_r' 'ifo_r' 'ilf_r' 'mdlf_r' 'slf3_r' 'vof_r')
        fi

        sphere_20k=$rootdir/human_20k.$hemi.sphere.surf.gii
        h_insula=$rootdir/h_insula_${hemi}_inv.func.gii
        h_MW=$rootdir/h_MW_${hemi}_inv.func.gii
        n_tracts=`echo ${#tract_list[@]}`

        for i in $(seq 1 $n_tracts); do
            m=${tract_list[$i-1]}
            echo "do tract $m"
            thr=${thr_list[$i-1]}

            if [ $do_preprocessing -eq 1 ]; then
                ### -------
                # resampling
                ### ------
                for s in $(seq 1 $n); do
                    subj=${subs[$s-1]}
                    if [ $spec == 'chimp' ]; then
                        if ! [ `wb_command -file-information $rootdir/$subj/surf/${m}/densityNorm_D.func.gii -only-map-names` = 'on_new_sphere' ]; then
                            echo "resample chimp"
                            mv $rootdir/$subj/surf/${m}/densityNorm_D.func.gii $rootdir/$subj/surf/${m}/densityNorm_D_old.func.gii
                            wb_command -metric-resample $rootdir/$subj/surf/${m}/densityNorm_D_old.func.gii $chimp_sphere $sphere_20k BARYCENTRIC $rootdir/$subj/surf/${m}/densityNorm_D.func.gii
                            wb_command -set-map-names $rootdir/$subj/surf/${m}/densityNorm_D_old.func.gii -map 1 'on_old_sphere'
                            wb_command -set-map-names $rootdir/$subj/surf/${m}/densityNorm_D.func.gii -map 1 'on_new_sphere'
                        else
                            echo "chimp already resampled"
                        fi
                    fi
                done # for subj

                ### -------
                # smoothing
                ### ------
                for s in $(seq 1 $n); do
                    echo "do smoothing"
                    subj=${subs[$s-1]}
                    input=$rootdir/$subj/surf/${m}/densityNorm_D.func.gii
                    out_S=$rootdir/$subj/surf/${m}/densityNorm_D_S.func.gii
                    # use individual surface for humans
                    if [ $spec == 'human' ]; then
                        surf_sm=~/scratch/LarynxRepresentation/derivatives/$subj/MNINonLinear/fsaverage_LR32k/${subj}.${hemi}.midthickness.20k_fs_LR.surf.gii
                        if [ $subj == 'group' ]; then
                            surf_sm=~/scratch/LarynxRepresentation/derivatives/sub-01/MNINonLinear/fsaverage_LR32k/sub-01.${hemi}.midthickness.20k_fs_LR.surf.gii
                        fi
                    fi
                    wb_command -metric-smoothing $surf_sm $input $kernel $out_S
                done # for subj

                ### -------
                # log norm individual maps
                ### ------
                tmpdir=$(mktemp -d "/tmp/chimp.XXXXXXXXXX")
                for s in $(seq 1 $n); do
                    echo "do logNorm"
                    subj=${subs[$s-1]}
                    out_S=$rootdir/$subj/surf/${m}/densityNorm_D_S.func.gii
                    out_N=$rootdir/$subj/surf/${m}/densityNorm_D_S_logNorm.func.gii
                    out_t=$rootdir/$subj/surf/${m}/densityNorm_D_S_logNorm_t.func.gii
                    wb_command -metric-math "(log(x+1))" $tmpdir/log.func.gii -var "x" $out_S
                    max=`wb_command -metric-stats $tmpdir/log.func.gii -reduce MAX`
                    wb_command -metric-math "(x/$max)" $tmpdir/norm.func.gii -var x $tmpdir/log.func.gii
                    wb_command -metric-math "(x>$thr)" $tmpdir/mask.func.gii -var x $tmpdir/norm.func.gii
                    wb_command -metric-mask $tmpdir/norm.func.gii $tmpdir/mask.func.gii $tmpdir/norm_t.func.gii
                    # initialize output file with first map and then add other files as map in output file
                    wb_command -metric-math "(x)" $out_N -var x $tmpdir/norm.func.gii
                    wb_command -metric-math "(x)" $out_t -var x $tmpdir/norm_t.func.gii
                done # for subj

                ### -------
                # creage average map
                ### ------
                echo "make average map"
                mkdir $rootdir/group/surf/${m}
                avg=$rootdir/group/surf/${m}/densityNorm_D.func.gii
                avg_S=$rootdir/group/surf/${m}/densityNorm_D_S.func.gii

                wb_command -metric-math "(x)" $avg -var x $rootdir/${subs[0]}/surf/${m}/densityNorm_D.func.gii
                wb_command -metric-math "(x)" $avg_S -var x $rootdir/${subs[0]}/surf/${m}/densityNorm_D_S.func.gii
                for s in $(seq 2 $n); do
                    subj=${subs[$s-1]}
                    wb_command -metric-math "(x+y)" $avg -var x $avg -var y $rootdir/$subj/surf/${m}/densityNorm_D.func.gii
                    wb_command -metric-math "(x+y)" $avg_S -var x $avg_S -var y $rootdir/$subj/surf/${m}/densityNorm_D_S.func.gii
                done
                wb_command -metric-math "x/$n" $avg -var x $avg
                wb_command -metric-math "x/$n" $avg_S -var x $avg_S

                # log normalize smoothed average map
                echo "lognorm average"
                avg_S_ln=$rootdir/group/surf/${m}/densityNorm_D_S_logNorm.func.gii
                avg_S_ln_t=$rootdir/group/surf/${m}/densityNorm_D_S_logNorm_t.func.gii

                wb_command -metric-math "(log(x+1))" $tmpdir/log.func.gii -var "x" $avg_S
                max=`wb_command -metric-stats $tmpdir/log.func.gii -reduce MAX`
                wb_command -metric-math "(x/$max)" $tmpdir/norm.func.gii -var x $tmpdir/log.func.gii
                wb_command -metric-math "(x>$thr)" $tmpdir/mask.func.gii -var x $tmpdir/norm.func.gii
                wb_command -metric-mask $tmpdir/norm.func.gii $tmpdir/mask.func.gii $tmpdir/norm_t.func.gii

                # initialize output file with first map and then add other files as map in output file
                wb_command -metric-math "(x)" $avg_S_ln -var x $tmpdir/norm.func.gii
                wb_command -metric-math "(x)" $avg_S_ln_t -var x $tmpdir/norm_t.func.gii
                wb_command -set-map-names $avg -map 1 'on_new_sphere'
                rm -rf $tmpdir

                # assign hemisphere as structure
                echo "assign hemisphere"
                if [ $hemi == 'L' ]; then
                    wb_command -set-structure $avg CORTEX_LEFT
                    wb_command -set-structure $avg_S_ln CORTEX_LEFT
                    wb_command -set-structure $avg_S_ln_t CORTEX_LEFT
                elif [ $hemi == 'R' ]; then
                    wb_command -set-structure $avg CORTEX_RIGHT
                    wb_command -set-structure $avg_S_ln CORTEX_RIGHT
                    wb_command -set-structure $avg_S_ln_t CORTEX_RIGHT
                fi

            fi # do_preprocessing

            for s in $(seq 1 $n); do
                subj=${subs[$s-1]}
                echo $subj
                if [ $spec == 'human' ]; then
                    wb_command -metric-palette $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii MODE_AUTO_SCALE_PERCENTAGE -palette-name $colour -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE 0 $thr -disp-neg false
                    if [ $hemi == 'L' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii CORTEX_LEFT

                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_LEFT $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii
                    elif [ $hemi == 'R' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii CORTEX_RIGHT
                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_RIGHT $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii
                    fi

                    echo "mask insula and MW"
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii $insula $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii $MW $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m_m.func.gii

                elif [ $spec == 'macaque' ]; then
                    echo "warp macaque to human"
                    input=densityNorm_D_S_logNorm
                    # to chimp space
                    msmresamplemetric ~/scratch/MSMstuff/MSM_3_species/mc_wb_${hemi}.sphere.reg.surf.gii \
                    $rootdir/${subj}/surf/${m}/${input}_warped_mc_x \
                    -labels $rootdir/${subj}/surf/${m}/${input}.func.gii \
                    -project $sphere_20k -adap_bary
                    # from chimp to human space
                    msmresamplemetric ~/scratch/MSMstuff/MSM_3_species/mh_refined_${hemi}.sphere.reg.surf.gii \
                    $rootdir/${subj}/surf/$m/${input}_warped_mh_x \
                    -labels $rootdir/${subj}/surf/$m/${input}_warped_mc_x.func.gii \
                    -project $sphere_20k -adap_bary

                    wb_command -metric-palette $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x.func.gii MODE_AUTO_SCALE_PERCENTAGE -palette-name $colour -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE 0 $thr -disp-neg false

                    echo "mask insula and MW"
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii $insula $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii $MW $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m_m.func.gii

                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x.func.gii $h_insula $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x_m.func.gii
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x_m.func.gii $h_MW $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x_m_m.func.gii

                    if [ $hemi == 'L' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x_m_m.func.gii CORTEX_LEFT
                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_LEFT $rootdir/${subj}/surf/$m/${input}_warped_mh_x_m_m.func.gii
                    elif [ $hemi == 'R' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_mh_x_m_m.func.gii CORTEX_RIGHT
                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_RIGHT $rootdir/${subj}/surf/$m/${input}_warped_mh_x_m_m.func.gii
                    fi

                elif [ $spec == 'chimp' ]; then
                    echo "warp chimp to human"
                    # resample
                    input=densityNorm_D_S_logNorm
                    msmresamplemetric ~/scratch/MSMstuff/MSM_3_species/ch_wb_${hemi}.sphere.reg.surf.gii \
                    $rootdir/${subj}/surf/$m/${input}_warped_ch_x \
                    -labels $rootdir/${subj}/surf/$m/${input}.func.gii \
                    -project $sphere_20k -adap_bary

                    wb_command -metric-palette $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x.func.gii MODE_AUTO_SCALE_PERCENTAGE -palette-name $colour -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE 0 $thr -disp-neg false

                    echo "mask insula and MW"
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm.func.gii $insula $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m.func.gii $MW $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_m_m.func.gii

                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x.func.gii $h_insula $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m.func.gii
                    wb_command -metric-mask $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m.func.gii $h_MW $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m_m.func.gii

                    if [ $hemi == 'L' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m_m.func.gii CORTEX_LEFT
                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_LEFT $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m_m.func.gii
                    elif [ $hemi == 'R' ]; then
                        wb_command -set-structure $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m_m.func.gii CORTEX_RIGHT
                        wb_command -add-to-spec-file $rootdir/three_species.spec CORTEX_RIGHT $rootdir/${subj}/surf/$m/densityNorm_D_S_logNorm_warped_ch_x_m_m.func.gii
                    fi
                fi # if spec==
            done
          echo "finish $m"
        done # m
        echo "finish $hemi"
    done # hemi
    echo "finish $spec"
done # spec

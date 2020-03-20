#!/bin/sh

# This script contains multiple snippets that can be run individually from a terminal

# defaults
rootdir='myPath'
MSMDIR='msmPath'
configdir=$MRCATDIR/projects/MSM/configuration_files

hemi=L
my_sphere=$myscratch/MSMstuff/meshes/human_20k.${hemi}.sphere.surf.gii
human_myelin=$rootdir/human.${hemi}.myelin.avg_1.func.gii
chimp_myelin=$rootdir/chimp.${hemi}.myelin.avg_1.func.gii
macaque_myelin=$rootdir/macaque.${hemi}.myelin.avg_1.func.gii

#### ---------------
# macaque -> chimp 1 ROI (step: 4 -> 5)
#### ---------------
cat <<EOF > $configdir/mc_1_ROI_L_hocr
    --sigma_in=25,15,5
    --lambda=0.1,0.1,0.1
    --it=10,10,10
    --opt=DISCRETE,DISCRETE,DISCRETE
    --CPgrid=1,2,3
    --SGgrid=3,4,5
    --regoption=3
    --regexp=2
    --dopt=HOCR
    --VN
    --triclique
    --k_exponent=2
    --bulkmod=1
    --shearmod=0.2
EOF

level=1
conf=$configdir/mc_1_ROI_L_hocr

$MSMDIR/msm --inmesh=$my_sphere --refmesh=$my_sphere  \
--indata=$rootdir/m_MT_${hemi}.func.gii --refdata=$rootdir/c_MT_${hemi}.func.gii \
--levels=$level --conf=$conf -o $rootdir/mc_1_ROI_${hemi}.

msmresamplemetric $rootdir/mc_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/mc_1_ROI_${hemi}_rois_warped -labels $rootdir/m_landmarks_${hemi}.func.gii -project $my_sphere -adap_bary
msmresamplemetric $rootdir/mc_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/mc_1_ROI_${hemi}_warped -labels $macaque_myelin -project $my_sphere  -adap_bary

$MSMDIR/estimate_metric_distortion $my_sphere $rootdir/mc_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/test1 #-target $input_mesh
$MSMDIR/estimate_metric_distortion $my_sphere $rootdir/mc_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/test2 #-target $input_mesh

#### ---------------
# macaque -> chimp 3 ROIs (step: 7 -> 8)
#### ---------------
cat <<EOF > $configdir/mc_3_ROI_L_hocr
--sigma_in=25,15,5
--lambda=0.01,0.01,0.1
--it=10,10,10
--opt=DISCRETE,DISCRETE,DISCRETE
--CPgrid=1,2,3
--SGgrid=3,4,5
--regoption=3
--regexp=2
--dopt=HOCR
--VN
--triclique
--k_exponent=2
--bulkmod=1
--shearmod=0.1
EOF

level=3
conf=$configdir/mc_3_ROI_L_hocr

$MSMDIR/msm --inmesh=$my_sphere \
--indata=$rootdir/m_landmarks_${hemi}.func.gii --refdata=$rootdir/c_landmarks_${hemi}.func.gii \
--levels=$level --conf=$conf -o $rootdir/mc_3_ROI_${hemi}. --trans=$rootdir/mc_1_ROI_${hemi}.sphere.reg.surf.gii

msmresamplemetric $rootdir/mc_3_ROI_${hemi}.sphere.reg.surf.gii $rootdir/mc_3_ROI_${hemi}_warped -labels $macaque_myelin -project $my_sphere  -adap_bary

#### ---------------
# macaque -> chimp whole-brain myelin map (step: 9 -> 10)
#### ---------------
cat <<EOF > $configdir/mc_wb_L_hocr
--sigma_in=10,5,3,1
--lambda=0.1,0.1,0.1,0.01
--it=10,10,20,20
--opt=DISCRETE,DISCRETE,DISCRETE,DISCRETE
--CPgrid=2,3,4,4
--SGgrid=4,5,6,6
--IN
--excl
--regoption=3
--regexp=2
--dopt=HOCR
--triclique
--k_exponent=2
--bulkmod=1
--shearmod=0.2
EOF

level=3
conf=$configdir/mc_wb_L_hocr

$MSMDIR/msm --inmesh=$my_sphere  --refmesh=$my_sphere  \
--indata=$macaque_myelin --refdata=$chimp_myelin \
--levels=$level --conf=$conf -o $rootdir/mc_wb_${hemi}. --trans=$rootdir/mc_3_ROI_${hemi}.sphere.reg.surf.gii


#### ---------------
# chimp -> human 1 ROI (step: 4 -> 5)
#### ---------------
cat <<EOF > $configdir/ch_1_ROI_L_hocr
--sigma_in=20,15,5
--lambda=0.05,0.1,0.1
--it=10,10,10
--opt=DISCRETE,DISCRETE,DISCRETE
--CPgrid=2,3,4
--SGgrid=4,5,6
--regoption=3
--regexp=2
--dopt=HOCR
--VN
--triclique
--k_exponent=2
--bulkmod=1
--shearmod=0.2
EOF
level=3
conf=$configdir/ch_1_ROI_L_hocr

$MSMDIR/msm --inmesh=$my_sphere  \
--indata=$rootdir/c_MT_${hemi}.func.gii --refdata=$rootdir/h_MT_${hemi}.func.gii \
--levels=$level --conf=$conf -o $rootdir/ch_1_ROI_${hemi}.

msmresamplemetric $rootdir/ch_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/ch_1_ROI_${hemi}_rois_warped -labels $rootdir/c_landmarks_${hemi}.func.gii -project $my_sphere -adap_bary
msmresamplemetric $rootdir/ch_1_ROI_${hemi}.sphere.reg.surf.gii $rootdir/ch_1_ROI_${hemi}_warped -labels $chimp_myelin -project $my_sphere -adap_bary


#### ---------------
# chimp -> human 3 ROI (step: 7 -> 8)
#### ---------------
cat <<EOF > $configdir/ch_3_ROI_L_hocr
--sigma_in=25,15,5
--lambda=0.001,0.1,0.1
--it=10,10,10
--opt=DISCRETE,DISCRETE,DISCRETE
--CPgrid=2,3,4
--SGgrid=4,5,6
--regoption=3
--regexp=2
--dopt=HOCR
--VN
--triclique
--k_exponent=2
--bulkmod=1
--shearmod=0.2
EOF

level=1
conf=$configdir/ch_3_ROI_L_hocr

$MSMDIR/msm --inmesh=$my_sphere  --refmesh=$my_sphere   \
--indata=$rootdir/c_landmarks_${hemi}.func.gii --refdata=$rootdir/h_landmarks_${hemi}.func.gii \
--levels=$level --conf=$conf -o $rootdir/ch_3_ROI_${hemi}. --trans=$rootdir/ch_1_ROI_${hemi}.sphere.reg.surf.gii

msmresamplemetric $rootdir/ch_3_ROI_${hemi}.sphere.reg.surf.gii $rootdir/ch_3_ROI_${hemi}._warped -labels $chimp_myelin -project $my_sphere  -adap_bary

#### ---------------
# chimp -> human whole-brain myelin map (step: 9 -> 10)
#### ---------------
cat <<EOF > $configdir/ch_wb_L_hocr
--sigma_in=25,10,5
--lambda=0.2,0.5,0.5
--it=10,10,10
--opt=DISCRETE,DISCRETE,DISCRETE
--CPgrid=2,3,4
--SGgrid=4,5,6
--regoption=3
--regexp=2
--dopt=HOCR
--triclique
--k_exponent=2
--bulkmod=1.6
--shearmod=0.1
EOF
level=3
conf=$configdir/ch_wb_L_hocr

$MSMDIR/msm --inmesh=$my_sphere  --refmesh=$my_sphere  \
--indata=$chimp_myelin --refdata=$human_myelin \
--levels=$level --conf=$conf -o $rootdir/ch_wb_${hemi}. --trans=$rootdir/ch_3_ROI_${hemi}.sphere.reg.surf.gii


#### ---------------
# refine macaque (step: 9 -> 10)
#### ---------------
cat <<EOF > $configdir/mh_ref_L_hocr
--sigma_in=25,10,5
--sigma_ref=25,10,5
--lambda=0.1,0.1,0.1
--it=10,10,3
--opt=DISCRETE,DISCRETE,DISCRETE
--CPgrid=2,3,4
--SGgrid=4,5,6
--datagrid=4,5,6
--IN
--regoption=3
--regexp=2
--dopt=HOCR
--triclique
--k_exponent=2
--bulkmod=1.6
--shearmod=0.1
EOF
level=3
conf=$configdir/mh_ref_L_hocr

$MSMDIR/msm --inmesh=$my_sphere  --refmesh=$my_sphere  \
--indata=$rootdir/mc_wb_${hemi}.transformed_and_reprojected.func.gii --refdata=$human_myelin \
--levels=$level --conf=$conf -o $rootdir/mh_refined_${hemi}. --trans=$rootdir/ch_wb_${hemi}.sphere.reg.surf.gii


#### ---------------
# flip ROI-derived spheres once obtained to RH
#### ---------------
wb_command -surface-flip-lr $rootdir/mc_1_ROI_L.sphere.reg.surf.gii $rootdir/mc_1_ROI_R.sphere.reg.surf.gii
wb_command -surface-flip-lr $rootdir/mc_3_ROI_L.sphere.reg.surf.gii $rootdir/mc_3_ROI_R.sphere.reg.surf.gii
wb_command -surface-flip-lr $rootdir/ch_1_ROI_L.sphere.reg.surf.gii $rootdir/ch_1_ROI_R.sphere.reg.surf.gii
wb_command -surface-flip-lr $rootdir/ch_3_ROI_L.sphere.reg.surf.gii $rootdir/ch_3_ROI_R.sphere.reg.surf.gii

#### ---------------
# derive distortion map
#### ---------------
for hemi in L R; do
    my_sphere=$myscratch/MSMstuff/meshes/human_20k.${hemi}.sphere.surf.gii
    wb_command -surface-distortion $my_sphere $rootdir/mc_wb_${hemi}.sphere.reg.surf.gii $rootdir/distortion_mc_${hemi}.func.gii -local-affine-method
    wb_command -surface-distortion $my_sphere $rootdir/ch_wb_${hemi}.sphere.reg.surf.gii $rootdir/distortion_ch_${hemi}.func.gii -local-affine-method
    wb_command -surface-distortion $my_sphere $rootdir/mh_refined_${hemi}.sphere.reg.surf.gii $rootdir/distortion_mh_${hemi}.func.gii -local-affine-method
done

rootdir='/myPath/'

for hemis={'L', 'R'}
    hemi=hemis{1};
    fnames=cell(3,2);

    sph=readimgfile([rootdir, 'human_20k.', hemi, '.sphere.surf.gii']);

    % reference myelin
    fnames{1,1}=[rootdir, '/human.', hemi, '.myelin.avg_1.func.gii'];
    fnames{2,1}=[rootdir, '/human.', hemi, '.myelin.avg_1.func.gii'];
    fnames{3,1}=[rootdir, '/chimp.', hemi, '.myelin.avg_1.func.gii'];

    % input names
    fnames{1,2}=[rootdir, '/ch_wb_', hemi, '.transformed_and_reprojected.func.gii'];
    fnames{2,2}=[rootdir, '/mh_refined_', hemi, '.transformed_and_reprojected.func.gii'];
    fnames{3,2}=[rootdir, '/mc_wb_', hemi, '.transformed_and_reprojected.func.gii'];

    % output names
    fnames{1,3}=[rootdir, '/ch_final_correlation.', hemi, '.func.gii'];
    fnames{2,3}=[rootdir, '/mh_final_correlation.', hemi, '.func.gii'];
    fnames{3,3}=[rootdir, '/mc_final_correlation.', hemi, '.func.gii'];

    for n=1:size(fnames,1)
        ref=readimgfile(fnames{n,1});
        in=readimgfile(fnames{n,2});

        r=surflocalcorr(ref,in,sph,40);
        fprintf(['save ' fnames{n,3} '...\n'])
        saveimgfile(r,fnames{n,3},hemi);
    end

end % hemi

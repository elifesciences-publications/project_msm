%%%% ------------------
% adapt this section
rootdir='/myPath/';
% requires scipts from MrCat
%%%% ------------------

for hemis={'L'}
    hemi=hemis{1};
    fnames=cell(3,2);

    % load common sphere
    sph=gifti([rootdir, '/data/20k.',hemi,'.sphere.surf.gii']);

    % define filnames: reference myelin
    fnames{1,1}=[rootdir,'/data/myelin_registration/human.', hemi, '.myelin.avg_1.func.gii'];
    fnames{2,1}=[rootdir,'/data/myelin_registration/human.', hemi, '.myelin.avg_1.func.gii'];
    fnames{3,1}=[rootdir,'/data/myelin_registration/chimp.', hemi, '.myelin.avg_1.func.gii'];

    % define filenames: input names
    fnames{1,2}=[rootdir,'/data/myelin_registration/ch_wb_', hemi, '.transformed_and_reprojected.func.gii'];
    fnames{2,2}=[rootdir,'/data/myelin_registration/mh_refined_', hemi, '.transformed_and_reprojected.func.gii'];
    fnames{3,2}=[rootdir,'/data/myelin_registration/mc_wb_', hemi, '.transformed_and_reprojected.func.gii'];

    % define filenames: output names
    fnames{1,3}=[rootdir,'/data/myelin_registration/ch_final_correlation.', hemi, '.func.gii'];
    fnames{2,3}=[rootdir,'/data/myelin_registration/mh_final_correlation.', hemi, '.func.gii'];
    fnames{3,3}=[rootdir,'/data/myelin_registration/mc_final_correlation.', hemi, '.func.gii'];

    % loop over all files
    for n=1:size(fnames,1)
        ref=readimgfile(fnames{n,1});
        in=readimgfile(fnames{n,2});
        % perform correlation
        r=surflocalcorr(ref,in,sph,40);
        fprintf(['save ' fnames{n,3} '...\n'])
        saveimgfile(r,fnames{n,3},hemi);
    end % n
end % hemi

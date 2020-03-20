
function localcorr_dice_extension(species,tract,hemi)

rootdir='/myPath/'
tract_list={'AF', 'CST', 'IFO', 'ILF', 'MDLF', 'SLF3', 'VOF'};
species_list={'human', 'chimp', 'macaque'};
hemi_list={'L', 'R'};
ppts=cell(3,20);
ppts(1,:)= {'sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', 'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-11', 'sub-12', 'sub-13', 'sub-14', 'sub-15', 'sub-16', 'sub-17', 'sub-18', 'sub-19', 'sub-20', 'sub-21'};
ppts(2,:)= {'C1', 'C2', 'C3', 'C4', 'C5','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan'};
ppts(3,:)= {'M1', 'M2', 'M3', 'M4', 'M5','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan'};

thr_list=linspace(0,1,101);
percentages_list=linspace(0,1,101);
corr_kernel=30;

n_vertices=20252;
n_ppts=size(ppts,2);
n_thr=length(thr_list);
n_p=length(percentages_list);

% initialize matrix to store data
my_dice=nan(n_ppts,n_ppts,n_p);
my_exp=nan(n_ppts,n_ppts,n_p);
my_thrs=nan(n_ppts,n_ppts,n_p);
my_corr=nan(n_ppts,n_ppts,n_p);

tracts(:,1)={'af_l', 'cst_l', 'ifo_l', 'ilf_l', 'mdlf_l', 'slf3_l', 'vof_l'}
tracts(:,2)={'af_r', 'cst_r', 'ifo_r', 'ilf_r', 'mdlf_r', 'slf3_r', 'vof_r'}

fnames={'densityNorm_D_S_logNorm.func.gii', ...
    'densityNorm_D_S_logNorm_warped_ch_x.func.gii', ...
    'densityNorm_D_S_logNorm_warped_mh_x.func.gii'};

sp=find(ismember(species_list, species));
he=find(ismember(hemi_list, hemi));
m=find(ismember(tract_list, tract));

%% do stuff
sph=gifti(fullfile(filesep, rootdir,['human_20k.',hemi_list{he},'.sphere.surf.gii']));
% mask for insula
insula = readimgfile(fullfile(rootdir,['h_insula_', hemi_list{he}, '.func.gii']));
% mask for medial wall
MW = readimgfile(fullfile(rootdir,['h_MW_', hemi_list{he}, '.func.gii']));

% store individual tract maps
my_map=nan(n_vertices,n_ppts,n_ppts);
% loop over human subjects
for pt_h = 1:n_ppts
    ppt_h=ppts{1,pt_h};
    % ---- read in human
    data_h=readimgfile(fullfile(rootdir,'human',ppt_h,'surf',tracts{m,he},fnames{1}));
    % loop over species subjects
    for pt_sp = 1:n_ppts
        ppt_sp=ppts{sp,pt_sp};
        fprintf(['do ', species_list{sp}, ' ', ppt_h, ' ', ppt_sp, ' ', tracts{m,he}, '\n'])
        if strcmp(ppt_sp,'nan')
            fprintf('next\n');
        else
            % ---- read in species data
            data_sp=readimgfile(fullfile(rootdir,species_list{sp},ppt_sp,'surf',tracts{m,he},fnames{sp}));
            data_h(isnan(data_h))=0;
            data_sp(isnan(data_sp))=0;
            % ---- do local correlation
            corr=surflocalcorr(data_h,data_sp,sph,corr_kernel);
            % ---- mask medial wall and insula
            data_h(insula==1 | MW==1)=nan;
            data_sp(insula==1 | MW==1)=nan;
            corr(insula==1 | MW==1)=nan;
            % ---- weighting mask: multiplication of human and other tract intensities
            w=(data_h.*data_sp);
            % ---- weighted correlation
            corr_w=corr.*w;
            my_map(:,pt_h,pt_sp)=corr_w;
            % loop over percentage of coverage
            for p=1:n_p
                pr=percentages_list(p);
                for t=1:n_thr
                    thr=thr_list(t);
                    % if the threshold has been increased enough so that
                    % the human map covers x percent of the surface, then...
                    if (sum(data_h>thr) < n_vertices*pr)
                        % compute dice of thresholded maps
                        my_dice(pt_h,pt_sp,p)=dice(data_h>thr,data_sp>thr);
                        % compute expansion
                        my_exp(pt_h,pt_sp,p)=sum(data_h>thr)/sum(data_h>thr & data_sp>thr);
                        % store this threshold where the x percent of the surface was covered
                        my_thrs(pt_h,pt_sp,p)=thr;
                        % derive the correlation value, mask the correlation map by the thresholded species map
                        my_corr(pt_h,pt_sp,p)=median(corr_w(data_sp>thr), 'omitnan');
                        break
                    end % if
                end % thr
            end % pr
        end % if nan
    end %ppt_sp
end % ppt_h
my_map_gr=mean(mean(my_map,2,'omitnan'),3,'omitnan');
% average of all permutations of the correlation maps
saveimgfile(my_map_gr,fullfile(rootdir,'human','group','surf',tracts{m,he},['corr_', num2str(sp), '_w.func.gii']),hemi_list{he});


save(fullfile(rootdir,species_list{sp},'group','surf',tracts{m,he},'my_dice'),'my_dice');
save(fullfile(rootdir,species_list{sp},'group','surf',tracts{m,he},'my_exp'),'my_exp');
save(fullfile(rootdir,species_list{sp},'group','surf',tracts{m,he},'my_thrs'),'my_thrs');
save(fullfile(rootdir,species_list{sp},'group','surf',tracts{m,he},'my_corr'),'my_corr');

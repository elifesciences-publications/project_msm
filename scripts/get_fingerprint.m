%% housekeeping
rootdir='/myPath/'
tract_titles={'AF', 'CST', 'IFO', 'ILF', 'MDLF', 'SLF3', 'VOF'};
species={'human', 'chimp', 'macaque'};
hemis={'L'};
ppts=cell(3,20);
ppts(1,:)= {'sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', 'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-11', 'sub-12', 'sub-13', 'sub-14', 'sub-15', 'sub-16', 'sub-17', 'sub-18', 'sub-19', 'sub-20', 'sub-21'};
ppts(2,:)= {'Bo', 'Cheeta', 'Lulu', 'Wenka', 'Foxy','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan'};
ppts(3,:)= {'hilary', 'oddie', 'rolo', 'umberto', 'decresp','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan','nan'};
thr_list=linspace(0,1,10);
p_list=linspace(0.2,0.8,7);

vx=[14766,20231];

n_vertices=20252;
n_species=length(species);
n_ppts=size(ppts,2);
n_tracts=length(tract_titles);
n_hemis=length(hemis);
n_thr=length(thr_list);
n_p=length(p_list);
n_vx=length(vx);

% initialize matrix to store data
d=nan(n_species,n_tracts,n_ppts,n_ppts,n_hemis,n_p);

# tract folder names
tracts(:,1)={'af_l', 'cst_l', 'ifo_l', 'ilf_l', 'mdlf_l', 'slf3_l', 'vof_l'}
tracts(:,2)={'af_r', 'cst_r', 'ifo_r', 'ilf_r', 'mdlf_r', 'slf3_r', 'vof_r'}

fnames={'densityNorm_D_S_logNorm.func.gii', ...
    'densityNorm_D_S_logNorm_warped_ch_x.func.gii', ...
    'densityNorm_D_S_logNorm_warped_mh_x.func.gii'};

# initialize fingerprint
fingerprint=nan(n_species,n_hemis,n_tracts,n_vx,n_ppts);

%%
for sp=1:n_species
    for he=1:n_hemis
        for m = 1:n_tracts
            for v = 1:n_vx
                for pt = 1:n_ppts
                    if strcmp(ppts{sp,pt},'nan')
                        fprintf('next\n');
                    else
                        fprintf(['do ', species{sp}, ' ', ppts{sp,pt}, ' ', tracts{m,he}, '\n'])
                        data=readimgfile(fullfile(rootdir,species{sp},ppts{sp,pt},'surf',tracts{m,he},fnames{sp}));
                        fingerprint(sp,he,m,v,pt)=data(vx(v));
                    end
                end
            end
        end
    end
end
save(fullfile(rootdir,'my_fingerprint'),'fingerprint');

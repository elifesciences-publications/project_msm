
%%%% ------------------
% edit this section
rootdir='/myPath/';
%%%% ------------------

% this script performs a high memory task !!

species={'human'};
hemis={'L'};

for sp = 1:length(species)
    spec=species{sp};

    % species-specific settings
    switch spec
        case 'human'
            subs = {'sub-01', 'sub-02' 'sub-03' 'sub-04' 'sub-05'};
        case 'chimp'
            subs = {'C1', 'C2', 'C3', 'C4', 'C5'};
        case 'macaque'
            subs = {'M1', 'M2','M3','M4','M5'};
    end
    for he = 1:length(hemis)
        hemi=hemis{he};

        % initialize average matrix
        avgmat=0;

        for sub = 1:length(subs)
            % load individual matrix
            subj=subs{sub};
            fprintf(['load ' spec ' ' hemi 'H ' subj '...\n'])
            corrected_surfseed = [rootdir '/' subj '_surfseed_' hemi '_corrected.mat'];
            fdt_matrix2=readimgfile(corrected_surfseed);
            fdt_matrix2 = fdt_matrix2.corrected_mat;
            % add to average matrix
            avgmat = avgmat+fdt_matrix2;
        end

        % average: divide by sample size
        fprintf('average...\n')
        avgmat=avgmat/length(subs);

        % save output
        fprintf('save...\n')
        save([r '/AVG_Matrix2_' spec '_' hemi '_corrected.mat'], 'avgmat','-v7.3');
    end
end
fprintf('done \n')

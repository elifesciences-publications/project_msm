
%%%% ------------------
% edit this section
rootdir='/home/fs0/neichert/scratch/project_msm';
%%%% ------------------

% this script performs a high memory task !!

species={'human'};
hemis={'L'};

for sp = 1:length(species)
    spec=species{sp};
    DD=[rootdir, '/data/', spec, '/connectivity_matrix'];

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
        for sub = 1:length(subs)
            subj=subs{sub};

            % input matrix
            fprintf(['do ' spec ' ' hemi 'H ' subj '...\n'])
            surfseeddir = [DD '/' subj '_surfseed_' hemi];
            % define output (corrected) matrix
            corrected_surfseed = [DD '/' subj '_surfseed_' hemi '_corrected.mat'];

            % read in image for header information for conversion
            hdr=niftiinfo([surfseeddir, '/fdt_paths.nii.gz']);
            aff = hdr.Transform.T;

            % for each row (vertex) in file convert coords to voxels -> list of voxel-coordinates for each vertex
            fprintf('get coordinates for vertices...\n')
            fid = fopen([surfseeddir, '/coords_for_fdt_matrix2']);
            ind=1;
            while ~feof(fid)
                thisline = strsplit(fgetl(fid));
                [a,b,c]=thisline{(1:3)};
                scanner_coords(ind,[1,2,3])=[str2num(a), str2num(b), str2num(c)];
                ind = ind + 1;
            end
            fclose(fid);

            % do conversion from scanner to anatomical coordinates
            vertex_coords = [scanner_coords(:,1) scanner_coords(:,2) scanner_coords(:,3) ones(size(scanner_coords,1),1)]*(inv(aff));
            vertex_coords(:,4) = [];
            vertex_coords = round(vertex_coords);

            % read in tract_space_coords_for_fdt_matrix2 -> list of voxel-coordinates for each brain voxel
            fprintf('get coordinates for brain voxels...\n')
            fid = fopen( [surfseeddir, '/tract_space_coords_for_fdt_matrix2']);
            ind=1;
            while ~feof(fid)
                thisline=strsplit(fgetl(fid));
                [a,b,c]=thisline{(1:3)};
                brain_coords(ind,[1,2,3])=[str2num(a),str2num(b),str2num(c)];
                ind=ind+1;
            end
            fclose(fid);

            % calculate distance from vertices to voxels
            fprintf('multiply voxels and vertices to compute distance...\n');
            distance=pdist2(vertex_coords,brain_coords);
            % introduce offset so that no elemant is 0
            distance=distance+0.0001;

            % load fdt_matrix2
            fprintf('load fdt_matrix2 ...\n');
            fdt_matrix2=readimgfile([surfseeddir, '/fdt_matrix2.dot']);

             % divide fdt_matrix by distance matrix
            fprintf('divide fdt_matrix by distance matrix ...\n');
            corrected_mat=fdt_matrix2./distance;

            % save output
            fprintf(['save output ' corrected_surfseed '...\n']);
            save(corrected_surfseed,'corrected_mat','-v7.3');
        end % for sub
    end % for hemi
end % for species
fprintf('done');

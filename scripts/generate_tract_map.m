%%%% ------------------
% adapt this section
rootdir='/home/fs0/neichert/scratch/project_msm';
% requires scripts from MrCat
FSLDIR='/opt/fmrib/fsl';
%%%% ------------------

% this script performs a high memory task !!

real_run=1;
% if real_run = 0 : only test inputs
% if real_run = 1 : run multiplication to generate tract map

species={'human'};
hemis={'L'};

for sp = 1:length(species)
	spec=species{sp};
	for he = 1:length(hemis)
		hemi=hemis{he};

		% species-specific settings
		switch spec
			case 'human'
			subs = {'sub-01', 'sub-02'}; # etc for 20 subjects
			matrix2 = [rootdir '/AVG_Matrix2_' spec '_' hemi '_corrected.mat'];
            mask_file = ['MNI152_T1_2mm_brain.nii.gz'];
			if hemi=='L'
				tracts={'cst_l'}; # etc for other tracts
			elseif hemi=='R'
				tracts={'cst_r'};
			end
			;;
		case 'chimp'
			% adapted paths
			;;
		case 'macaque'
			% adapted paths
			;;
		end

		fprintf('MrCat:multiply_fdt: loading files...\n');
		%==================================================
		% Load fdt_matrix2 (i.e. corrected connectivity matrix)
		%==================================================
		fdt_matrix2_file=matrix2;
		if isempty(fdt_matrix2_file); error('Error in MrCat:multiply_fdt: fdt_matrix2 file not specified!'); end
		if ~exist(fdt_matrix2_file, 'file'); error('fdt_matrix2 does not exist'); end
		fprintf(['load fdt_matrix2: ',fdt_matrix2_file,'\n'])

		if real_run
			fdt_matrix2 = readimgfile(fdt_matrix2_file);
			% allow for .dot input files with the following lines
			[~,~,ext] = fileparts(fdt_matrix2_file);
			if strcmp(ext,'.mat')
				% execute this line only for .mat file and not for .dot files
				fdt_matrix2 = fdt_matrix2.avgmat;
			end
		end

		%==================================================
		% Load mask
		%==================================================
		if isempty(mask_file); error('Error in MrCat:multiply_fdt: mask file not specified!'); end
		if ~exist(mask_file, 'file'); error('mask file does not exist'); end

		fprintf(['load mask: ', mask_file,'\n'])
		mask = readimgfile(mask_file);
		mask = mask(:);

		%==================================================
		% Loop over subjects and tracts
		%==================================================
		for s = 1:length(subs)
			for m = 1:length(tracts)
				% define fdt_paths and output
				fdt_paths_file=[rootdir '/' subs{s} '/tracts/' tracts{m} '/densityNorm.nii.gz'];
				if ~exist(fullfile(rootdir, '/', subs{s}, '/surf/', tracts{m}))
					mkdir(fullfile(rootdir, '/', subs{s}, '/surf/', tracts{m}));
				end
				output_file=[rootdir '/' subs{s} '/surf/' tracts{m} '/densityNorm_D.func.gii'];
				% check files
				if isempty(fdt_paths_file), error('Error: fdt_paths file(s) not specified!'); end
				if isempty(output_file), error('Error: output file not specified!'); end
				if strcontain(output_file,'.func.gii') || strcontain(output_file,'.dtseries.nii')
					if isempty(hemi); error('Error: hemisphere not defined for output .func.gii or .dtseriies.nii!'); end % if
				end % if

				%==================================================
				% Load fdt_paths
				%==================================================
				fprintf(['load fdt_paths: ',fdt_paths_file,'\n'])
				data = readimgfile(fdt_paths_file);
				data = data(:);
				data = data(~~mask);
				fdt_paths = data; clear data;

				if real_run
					%==================================================
					% Matrix multiplication
					%==================================================
					fprintf('performing multiplication...\n');
					data = fdt_matrix2*fdt_paths;

					%==================================================
					% Save
					%==================================================
					fprintf(['saving results:" ',output_file,'\n']);
					saveimgfile(data,output_file,hemi)
        		end % if real_run
	  		end % for tract
		end % for subj
	end % for hemi
end % for spec
fprintf('done!\n');

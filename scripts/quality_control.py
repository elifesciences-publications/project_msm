import nibabel as nib
import os
import sys
import seaborn as sns
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import pearsonr
from scipy.io import loadmat

# threshold of surface coverage 40 %
percentage = 40

# define species-specific settings
tracts_df = pd.DataFrame(columns=('species', 'hemi', 'tract', 'tract_name'))
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'AF', 'af_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'CST', 'cst_l']
# etc...

# define colours for plotting
my_blue = (0.46, 0.47, 0.89)
my_green = (0.44, 0.74, 0.4)

# initialize output dataframe that stores all numerical values
output_df = pd.DataFrame(columns=('species', 'hemi', 'tract', "tract extension", "registration error", "curvature", "myelin", "dispersion", "complexity"))

for hemi in ['L', 'R']:
    # load average surface maps for curvature and myelin content human curvature maps and normalize
    human_curvature_map = nib.load(os.path.join(f'group.{hemi}.curvature.20k_fs_LR.func.gii')).darrays[0].data
    human_curvature_map = human_curvature_map / np.max(human_curvature_map)

    human_myelin_map = nib.load(os.path.join(f'human.{hemi}.myelin.avg_1.func.gii')).darrays[0].data
    human_myelin_map = human_myelin_map / np.max(human_myelin_map)

    for species in ['macaque', 'chimp']:
        if species == 'macaque':
            error_map_fname = f'corrlation_myelin_macaque_to_human.{hemi}.func.gii'
            tract_map_fname = 'tract_map_macaque_to_human.func.gii'
            my_colour = my_green
            # species specific filepaths

        elif species == 'chimp':
            error_map_fname = f'corrlation_myelin_chimp_to_human.{hemi}.func.gii'
            tract_map_fname = 'tract_map_chimp_to_human.func.gii.func.gii'
            my_colour = my_blue

        error_map = nib.load(os.path.join(error_map_fname)).darrays[0].data
        species_curvature_map = nib.load(os.path.join(curvature_map_fname)).darrays[0].data
        species_curvature_map = species_curvature_map/max(species_curvature_map)

        species_myelin_map = nib.load(os.path.join(myelin_map_fname)).darrays[0].data
        species_myelin_map = species_myelin_map/np.max(species_myelin_map)

        for tract in tracts_df.tract.unique():
            # load thresholded tract maps
            human_40pr = nib.load(os.path.join(tracts_df[(tracts_df.species == 'human') & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0],
                                               '40pr.func.gii')).darrays[0].data

            species_40pr = nib.load(os.path.join(tracts_df[(tracts_df.species == species) & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0],
                                               '40pr.func.gii')).darrays[0].data

            # exclude 0s
            error_map[error_map == 0] = np.nan
            human_40pr[human_40pr == 0] = np.nan
            species_40pr[species_40pr == 0] = np.nan

            # generate whole-brain vertex-wise 2D joint distribution plots for AF and MDLF
            if (tract == 'AF') or (tract == 'MDLF'):
                human_tract_map = nib.load(os.path.join(tracts_df[(tracts_df.species == 'human') & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0],
                                                        'tract_map.func.gii')).darrays[0].data

                species_tract_map = nib.load(os.path.join(tracts_df[(tracts_df.species == species) & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0],
                                                          'tract_map.func.gii')).darrays[0].data

                # mask out 0s
                species_tract_map[species_tract_map == 0] = np.nan
                human_tract_map[human_tract_map == 0] = np.nan

                # difference of human and species tract
                diff = human_tract_map - species_tract_map

                # plot distribution of differences (Figure S5B,C)
                hexplot = sns.jointplot(1-error_map, abs(diff), kind="hex", color=my_colour, xlim=(0, 1), ylim=(0, 1), height=3)
                hexplot.ax_joint.yaxis.set_ticks([-0, 0.5, 1])
                hexplot.ax_joint.xaxis.set_ticks([0, 0.5, 1])
                hexplot.fig.get_axes()[1].set_title(f'{tract}_{hemi}')
                plt.subplots_adjust(left=0.2, right=0.8, top=0.8, bottom=0.2)  # shrink fig so cbar is visible
                # add colour bar axis
                cbar_ax = hexplot.fig.add_axes([.7, .6, .05, .2])  # x, y, width, height
                plt.colorbar(cax=cbar_ax)

                # get pearson
                # mask out nans
                error_map_ma = np.ma.masked_invalid(error_map)
                diff_ma = np.ma.masked_invalid(diff)
                msk = (~error_map_ma.mask & ~diff_ma.mask)
                [r, p] = pearsonr(1 - error_map_ma[msk], abs(diff_ma[msk])) # if r<0.3 : no linear relationship
                print(f'{tract}, {hemi}, r = {r}, p = {p}')
                # add to plot
                hexplot.fig.get_axes()[0].text(0.1, 0.9, f'r={np.round(r, 2)}')

            plt.show()

            # load tract extension ratio
            my_vals = loadmat(os.path.join(tracts_df[(tracts_df.species == species) & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0],
                                           'extension_ratios'))['extension_ratios']

            # determine the tract extension ratio at the surface coverage of 40 %
            extension = np.nanmean(my_vals[:, :, percentage + 1])

            # get species ratio for registration error map
            human_error = 1 - np.nanmean(error_map[human_40pr > 0])
            species_error = 1 - np.nanmean(error_map[species_40pr > 0])
            error = human_error/species_error

            # get species ratio for surface curvature
            human_curvature = np.nanmean(human_curvature_map[human_40pr > 0])
            species_curvature = np.nanmean(species_curvature_map[species_40pr > 0])
            curvature = human_curvature/species_curvature

            # get species ratio for myelin content
            human_myelin = np.nanmean(human_myelin_map[human_40pr > 0])
            species_myelin = np.nanmean(species_myelin_map[species_40pr > 0])
            myelin = human_myelin/species_myelin

            # initialize dyad dispersion and tract complexity measures
            dyad_measures = np.array([0, 0], dtype='float32')
            pair_measures = np.array([0, 0, 0], dtype='float32')

            for i, dyad_measure in enumerate(['dispersion', 'complexity']):
                # read in file that contains all subject's dispersion or complexity measures
                human_dyads_fname = os.path.join(f'{dyad_measure}_human_{hemi}_{tracts_df[(tracts_df.species == "human") & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0]}.txt')
                with open(human_dyads_fname) as f:
                    mylist = f.read().splitlines()
                human_dyad_mean = np.mean([np.float(i) for i in mylist])

                # read in file that contains all the species dispersion or complexity measures
                species_dyads_fname = os.path.join(myscratch, 'MSMstuff', f'{dyad_measure}_{species}_{hemi}_{tracts_df[(tracts_df.species == species) & (tracts_df.tract == tract) & (tracts_df.hemi == hemi)].tract_name.values[0]}.txt')
                with open(species_dyads_fname) as f:
                    mylist = f.read().splitlines()
                species_dyad_mean = np.mean([np.float(i) for i in mylist])

                # get species ratio for dispersion and complexity
                dyad_measures[i] = human_dyad_mean/species_dyad_mean

            # add all numerical values to dataframe
            output_df.loc[len(output_df)] = [species, hemi, tract, extension, error, curvature, myelin, dyad_measures[0], dyad_measures[1]]

# create plot for Figure S5A
measures = ['curvature', 'dispersion', 'complexity', 'registration error', 'myelin']
plots = [None] * len(measures)

plt.figure(figsize=(10, 2))
for im, measure in enumerate(measures):
    [r, p] = pearsonr(output_df[measure], output_df['tract extension'])
    print(f'{measure}, r = {r}, p = {p}')
    ax = plt.subplot(1, 5, im+1)
    ax.set_xlabel('dummy', fontsize=15)
    sns_plt = sns.scatterplot(measure, 'tract extension', data=output_df, style='hemi', hue='species', palette=sns.color_palette([my_green, my_blue]), legend=False)
    sns_plt.xaxis.set_label_position('top')
    x_label = np.min(output_df[measure])
    ax.text(x_label, 2.1, f'r={np.round(r,2)}, p={np.round(p,2)}')
    plots[im] = sns_plt

plots[0].set(yticks=[1, 1.5, 2, 2.5])
for sns_plt in plots[1::]:
    sns_plt.yaxis.set_visible(False)

plt.show()


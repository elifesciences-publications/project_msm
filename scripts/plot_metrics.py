import numpy as np
import matplotlib.pyplot as plt
import sys
import pandas as pd
import seaborn as sns

run_or_load = 'run'

### --------
# Defaults
### --------

print('set defaults')
rootdir = 'myPath'

tracts_df = pd.DataFrame(columns=('species', 'hemi', 'tract', 'tract_name'))
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'AF', 'af_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'CST', 'cst_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'IFO', 'ifo_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'ILF', 'ilf_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'MDLF', 'mdlf_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'SLF3', 'slf3_l']
tracts_df.loc[len(tracts_df)] = ['human', 'L', 'VOF', 'vof_l']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'AF', 'af_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'CST', 'cst_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'IFO', 'ifo_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'ILF', 'ilf_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'MDLF', 'mdlf_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'SLF3', 'slf3_r']
tracts_df.loc[len(tracts_df)] = ['human', 'R', 'VOF', 'vof_r']

tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'AF', 'af_l_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'CST', 'cst_l']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'IFO', 'ifo_l']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'ILF', 'ilf_l_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'MDLF', 'mdlf_l_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'SLF3', 'slf3_l_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'L', 'VOF', 'vof_l_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'AF', 'af_r_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'CST', 'cst_r']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'IFO', 'ifo_r']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'ILF', 'ilf_r_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'MDLF', 'mdlf_r_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'SLF3', 'slf3_r_inv']
tracts_df.loc[len(tracts_df)] = ['chimp', 'R', 'VOF', 'vof_r_inv']

tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'AF', 'af_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'CST', 'cst_ne_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'IFO', 'ifo_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'ILF', 'ilf_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'MDLF', 'mdlf_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'SLF3', 'slf3_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'L', 'VOF', 'vof_l']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'AF', 'af_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'CST', 'cst_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'IFO', 'ifo_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'ILF', 'ilf_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'MDLF', 'mdlf_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'SLF3', 'slf3_r']
tracts_df.loc[len(tracts_df)] = ['macaque', 'R', 'VOF', 'vof_r']

ppts = {'human': ['sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', 'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-11', 'sub-12', 'sub-13', 'sub-14', 'sub-15', 'sub-16', 'sub-17', 'sub-18', 'sub-19', 'sub-20', 'sub-21'],
        'chimp': ['C1', 'C2', 'C3', 'C4', 'C5'],
        'macaque': ['M1', 'M2', 'M3', 'M4', 'M5']}

percentage_list = np.array([20, 30, 40, 50])
# too tedious to get the maxima of y-axis automatically
max_list = np.array([6, 4, 3, 3])


#tract_list = tracts_df.tract.unique()
tract_list = ['CST', 'MDLF', 'VOF', 'IFO', 'ILF', 'SLF3', 'AF']


if run_or_load == 'run':
    print('load in data')
    df = pd.DataFrame(columns=('species', 'hemi', 'tract', "p_h", "p_s", "percentage", 'measure', 'value'))
    ind = 0
    for species in ['chimp', 'macaque']:
        for hemi in tracts_df.hemi.unique():
            for tract in tract_list:
                print(species, hemi, tract)
                tract_name = tracts_df[(tracts_df.hemi == hemi) & (tracts_df.species == species) & (tracts_df.tract == tract)].tract_name.values[0]
                for i_h, p_h in enumerate(ppts['human']):
                    for i_s, p_s in enumerate(ppts[species]):
                        for measure in ['my_dice', 'my_exp']:
                            my_vals = scipy.io.loadmat(os.path.join(rootdir, species, 'group', 'surf', tract_name, measure))[measure]
                            for perc in percentage_list:
                                df.loc[ind] = [species, hemi, tract, p_h, p_s, perc, measure, my_vals[i_h, i_s, perc]]
                                ind = ind + 1

    print('save dataframe to pickle')
    df.to_pickle(os.path.join(rootdir, 'values.pkl'))

elif run_or_load == 'load':
    print('load dataframe from pickle')
    df = pd.read_pickle(os.path.join(rootdir, 'values.pkl'))


# make subsets for GLM targets
print('write out subset of data for statistic')
measure = 'my_exp'
percentage = 40
for hemi in ['L', 'R']:
    df_out = df[((df.species == 'chimp') | (df.species == 'macaque')) & (df.measure == measure) & (df.percentage == percentage) & (df.hemi == hemi)]
    df_out.to_csv(os.path.join(rootdir, f'targets_{hemi}.csv'), index=False)


#####
print('draw plot')
sns.set_style({'font.serif':'Helvetica'})
#sns.set(font_scale=1)
my_blue = (0.46, 0.47, 0.89)
my_green = (0.44, 0.74, 0.4)
# Draw the initial plot
for percentage in percentage_list:
    my_max = max_list[np.where(percentage_list == percentage)[0][0]]

    g = sns.catplot(y='value', hue='species', x='tract', row='measure', col='hemi', kind='bar', data=df[df.percentage == percentage],
                    order=tract_list, ci='sd', height=2, aspect=2, palette=sns.color_palette([my_blue, my_green]), sharey=False, legend=False)
    g.fig.get_axes()[0].set_ylim([0, 1])
    g.fig.get_axes()[0].set_yticks([0, 1])
    g.fig.get_axes()[1].set_ylim([0, 1])
    g.fig.get_axes()[1].set_yticks([])
    g.fig.get_axes()[2].set_ylim([0, my_max])
    g.fig.get_axes()[2].set_yticks([0, 1, my_max])
    g.fig.get_axes()[3].set_ylim([0, my_max])
    g.fig.get_axes()[3].set_yticks([])
    for ax in g.fig.get_axes():
        ax.set_xlabel("")
        ax.set_ylabel("")
        ax.set_title("")

plt.show()

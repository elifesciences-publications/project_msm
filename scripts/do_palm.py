import numpy as np
import os
import csv
import pandas as pd

rootdir = 'myPath'
# run statistical analysis or show output
run_or_show = 'run'
hemi_list = ['L', 'R']
n_permutations = 5000


if run_or_show == 'run':
    # get subset of data
    for he, hemi in enumerate(hemi_list):
        print('get subset of', hemi, 'hemisphere')
        df = pd.read_csv(os.path.join(rootdir, f'targets_{hemi}.csv'))
        # ----
        # GLM
        # ----
        # run R-script to get model matrix!
        # fixed effects
        df_fe = pd.read_csv(os.path.join(rootdir, 'palm_GLM', 'my_glm_fe.csv'), sep=' ')
        # random effects
        df_re = pd.read_csv(os.path.join(rootdir, 'palm_GLM', 'my_glm_re.csv'), sep=' ')
        # combine effects to GLM
        df_glm = pd.concat([df_fe, df_re], axis=1, sort=False)
        my_glm = df_glm.as_matrix()

        # ----
        # contrasts
        # ----
        # one contrast for each fixed-effect
        my_con = np.zeros([df_fe.shape[1], my_glm.shape[1]])
        my_con[0:df_fe.shape[1], 0:df_fe.shape[1]] = np.eye(df_fe.shape[1])
        # remove first contrast for intercept, because PALM will throw an error
        my_con = np.delete(my_con, 0, 0)

        # ----
        # F-test
        # ----
        # 1: no f-test for species, because derive f-value from t-stats
        # 2-5: f-test for tract
        # 6-9: f-test for species*trac
        my_f = np.array([[0, 1, 1, 1, 1, 0, 0, 0, 0],
                         [0, 0, 0, 0, 0, 1, 1, 1, 1]])

        # ----
        # Save model
        # ----
        out_target = os.path.join(rootdir, 'palm_GLM', 'my_targets_' + hemi + '.csv')
        out_glm = os.path.join(rootdir, 'palm_GLM', 'my_glm_r.csv')
        out_con = os.path.join(rootdir, 'palm_GLM', 'my_con_r.csv')
        out_f = os.path.join(rootdir, 'palm_GLM', 'my_f_r.csv')
        out_palm = os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi)
        np.savetxt(out_target, df.value.values, fmt='%3.3f', delimiter=",")
        np.savetxt(out_glm, my_glm, fmt='%1.0f', delimiter=",")
        np.savetxt(out_con, my_con, fmt='%1.0f', delimiter=",")
        np.savetxt(out_f, my_f, fmt='%3.3f', delimiter=",")

        # ----
        # Run PALM (once without -corrcon to produce tstats, once with to produce cfwep)
        # ----
        print('run PALM')
        palm_command = (
            f"fsl_sub -q short.q -N palm_glm -l /vols/Scratch/neichert/myCode/logs /home/fs0/neichert/scratch/external/palm-alpha115/palm "
            f" -i {out_target} -d {out_glm}  -t {out_con} -f {out_f} -o {out_palm} -n {str(n_permutations)} -quiet"
            f" -twotail -corrcon")
        print(palm_command)
        os.system(palm_command)


elif run_or_show == 'show':
    for hemi in hemi_list:
        print(hemi)
        # contrast for species main effect (t-test)
        c_sp = 1
        # contrast for tract main effect (f-test)
        c_tr = 10
        # contrast for species*tract interaction (f-test)
        c_sptr = 11

        print('output stats of GLM')
        # species-tract GLM:
        # main effect species (c1)
        f = np.power(float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_tstat_c{c_sp}.csv')).readlines()[0]), 2)
        pt = float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_tstat_fwep_c{c_sp}.csv')).readlines()[0])
        p = 2 * min(pt, 1 - pt)
        print('main effect species (f, p): ', f, p)

        # main effect tract:
        f = float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_fstat_c{c_tr}.csv')).readlines()[0])
        p = float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_zfstat_cfwep_c{c_tr}.csv')).readlines()[0])
        print('main effect tract (f, p): ', f, p)

        # interaction effect (16):
        f = float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_fstat_c{c_sptr}.csv')).readlines()[0])
        p = float(open(os.path.join(rootdir, 'palm_GLM', 'GLM' + hemi + f'_dat_zfstat_fwep_c{c_sptr}.csv')).readlines()[0])
        print('interaction effect (f, p): ', f, p)

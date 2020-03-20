import numpy as np
import matplotlib.pyplot as plt
import scipy.io
import os

# load data
rootdir = '/myPath/'
fp = scipy.io.loadmat(os.path.join(rootdir, 'my_fingerprint'))['fingerprint']

# fp(sp,he,m,v,pt)
fp_m = np.nanmean(fp, axis=(4))
fp_err = np.nanstd(fp, axis=(4))

orig_o = ('AF', 'CST', 'IFO', 'ILF', 'MDLF', 'SLF3', 'VOF')


my_colors = [(1, 0, 0), # my_red
    (0.46, 0.47, 0.89), # my_blue
    (0.44, 0.74, 0.4)] # my_green

for v in np.arange(0, fp_m.shape[3]):
    N = fp_m.shape[2]
    width = 0.3
    ax = plt.subplot(2, fp_m.shape[3] / 2, v + 1, projection='polar')
    for sp in (0, 1, 2):
        theta = np.linspace(0.1 * sp, 2 * np.pi, N, endpoint=False)
        bars = ax.bar(theta, fp_m[sp, 0, :, v], width=width, bottom=0.0, color=my_colors[sp])
        err = ax.errorbar(theta, fp_m[sp, 0, :, v], fp_err[sp, 0, :, v], fmt='.', c='black')
        for bar in bars:
            bar.set_alpha(0.9)
    ax.set_xticks(theta)
    ax.set_xticklabels(orig_o, fontfamily='Helvetica', fontweight='bold', fontsize='large')
    ax.set_yticks([0, 0.5, 1])
    ax.set_yticklabels('')

plt.show()

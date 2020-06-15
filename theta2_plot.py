import numpy as np
import matplotlib.pyplot as plt
from fact.io import read_h5py
import pandas as pd
import plotting

import matplotlib
if matplotlib.get_backend() == 'pgf':
    from matplotlib.backends.backend_pgf import PdfPages
else:
    from matplotlib.backends.backend_pdf import PdfPages

columns = [
    'source_x_prediction', 
    'source_y_prediction', 
    'dragon_time', 
    'gammaness', 
    'concentration_cog',
    'focal_length'
    ]

offs = [
    'build/dl2_v0.5.1_LST-1.Run01837.h5', 
    'build/dl2_v0.5.1_LST-1.Run01840.h5', 
    'build/dl2_v0.5.1_LST-1.Run01841.h5',
    'build/dl2_v0.5.1_LST-1.Run01842.h5'
    ]

ons = [
    'build/dl2_v0.5.1_LST-1.Run01832.h5', 
    'build/dl2_v0.5.1_LST-1.Run01833.h5', 
    'build/dl2_v0.5.1_LST-1.Run01834.h5',
    'build/dl2_v0.5.1_LST-1.Run01835.h5',
    'build/dl2_v0.5.1_LST-1.Run01836.h5',
    'build/dl2_v0.5.1_LST-1.Run01843.h5',
    'build/dl2_v0.5.1_LST-1.Run01844.h5'
    ]

df_off = pd.DataFrame()
for i, run in enumerate(offs):
    df_off = pd.concat( [
            df_off,
            read_h5py(run, key = 'events', columns=columns)
        ],
        ignore_index=True
    )

df_on = pd.DataFrame()
for i, run in enumerate(ons):
    df_on = pd.concat( [
            df_on,
            read_h5py(run, key = 'events', columns=columns)
        ],
        ignore_index=True
    )

figures = []

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(df_on, df_off, ax)
ax.set_title('Total-time scaling')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(df_on, df_off, ax, alpha='alt')
ax.set_title('Furthest $10\%$ scaling')


#test plots
gamma = read_h5py('build/dl2_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5', key = 'events')
gamma_diff = read_h5py('build/dl2_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5', key = 'events')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma_diff.disp_prediction, bins=100, histtype='step')
ax.set_xlabel('disp prediction')
ax.set_title('gamma-diffuse testing')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma_diff.gammaness, bins=100, histtype='step')
ax.set_xlabel('gammaness')
ax.set_title('gamma-diffuse testing')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(gamma_diff, ax=ax, range=None)
ax.set_title('gamma-diffuse testing')

#angular resolustion
figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.angular_res(gamma, 'mc_energy', ax)
ax.set_title('Angular resolution (no cuts)')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)

gamma['sign_prediction'] = np.sign(gamma.disp_prediction)
gamma_cuts = gamma.query('sign_prediction == disp_sign')
gamma_cuts = gamma_cuts.query('gammaness > 0.7')
plotting.angular_res(gamma_cuts, 'mc_energy', ax)
ax.set_title('Angular resolution (correct sign prediction & gammaness > 0.7)')


#saving
with PdfPages('build/theta2_plot.pdf') as pdf:
    for fig in figures:
        fig.tight_layout()
        pdf.savefig(fig)

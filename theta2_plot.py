import numpy as np
import matplotlib.pyplot as plt
from fact.io import read_h5py
from fact.analysis.statistics import li_ma_significance
import pandas as pd

import matplotlib
if matplotlib.get_backend() == 'pgf':
    from matplotlib.backends.backend_pgf import PdfPages
else:
    from matplotlib.backends.backend_pdf import PdfPages

def dist_to_camera(on_df, off_df=None, ax=None, range=[0,1], alpha='total_time'):

    ax = ax or plt.gca()
    on_df_selected = on_df.query('gammaness > 0.7')
    on_df_selected = on_df_selected.query('concentration_cog > 0.0025')

    dist_on = on_df_selected.source_x_prediction**2 + on_df_selected.source_y_prediction**2
    theta2_on = np.rad2deg(np.sqrt(dist_on) / on_df.focal_length)**2

    if isinstance(off_df, pd.core.frame.DataFrame):
        off_df_selected = off_df.query('gammaness > 0.7')
        off_df_selected = off_df_selected.query('concentration_cog > 0.0025')
        
        dist_off = off_df_selected.source_x_prediction**2 + off_df_selected.source_y_prediction**2
        theta2_off = np.rad2deg(np.sqrt(dist_off) / off_df.focal_length)**2

        if alpha == 'total_time':
            time_on = on_df.dragon_time
            total_time_on = time_on.max() - time_on.min()
            print(f'Total time ON = {total_time_on}')
            time_off = off_df.dragon_time
            total_time_off = time_off.max() - time_off.min()
            print(f'Total time OFF = {total_time_off}')

            scaling = total_time_on/total_time_off
        else:
            norm_range = range[1]-range[1]/10

            hist = np.histogram(theta2_on[theta2_on < range[1]], bins=100)
            x_on = hist[1]
            x_on = x_on[:-1].copy()
            mean_on = np.mean(hist[0][x_on > norm_range])

            hist = np.histogram(theta2_off[theta2_off < range[1]], bins=100)
            x_off = hist[1]
            x_off = x_off[:-1].copy()
            mean_off = np.mean(hist[0][x_off > norm_range])

            scaling = mean_on/mean_off
        
        ax.hist(theta2_off, bins=100, range=range, histtype='step', label='OFF', weights=np.full_like(theta2_off, scaling))

    ax.hist(theta2_on, bins=100, range=range, histtype='step', label='ON')
    ax.set_xlabel(r'$\theta^2 \,\, / \,\, \mathrm{deg}^2$')
    ax.legend()
    ax.figure.tight_layout()

    if isinstance(off_df, pd.core.frame.DataFrame):
        cut = 0.065
        n_off = np.count_nonzero(theta2_off < cut)
        n_on = np.count_nonzero(theta2_on < cut)
        li_ma = li_ma_significance(n_on, n_off, scaling)

        ax.axvline(x=cut, color='k', lw=0.1)
        text = rf'$N_\mathrm{{off}} = {n_off}, N_\mathrm{{on}} = {n_on}, \alpha = {scaling:.2f}$' + '\n' + rf'$S_\mathrm{{Li&Ma}} = {li_ma:.2f}$'
        ax.text(0.3, 900, text)

    return ax



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
dist_to_camera(df_on, df_off, ax)
ax.set_title('Total-time scaling')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
dist_to_camera(df_on, df_off, ax, alpha='alt')
ax.set_title('Furthest $10\%$ scaling')


#test plots
gamma = read_h5py('build/dl2_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5', key = 'events')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma.disp_prediction, bins=100, histtype='step')
ax.set_xlabel('disp prediction')
ax.set_title('gamma-diffuse testing')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma.gammaness, bins=100, histtype='step')
ax.set_xlabel('gammaness')
ax.set_title('gamma-diffuse testing')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
dist_to_camera(gamma, ax, range=None)
ax.set_title('gamma-diffuse testing')

#saving
with PdfPages('build/theta2_plot.pdf') as pdf:
    for fig in figures:
        fig.tight_layout()
        pdf.savefig(fig)

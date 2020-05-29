import numpy as np
import matplotlib.pyplot as plt
from fact.io import read_h5py
from fact.analysis.statistics import li_ma_significance
import pandas

import matplotlib
if matplotlib.get_backend() == 'pgf':
    from matplotlib.backends.backend_pgf import PdfPages
else:
    from matplotlib.backends.backend_pdf import PdfPages

def dist_to_camera(on_df, off_df=None, ax=None, range=[0,0.12]):

    ax = ax or plt.gca()
    on_df_selected = on_df.query('gammaness > 0.5')
    dist_on = on_df_selected.source_x_prediction**2 + on_df_selected.source_y_prediction**2

    if isinstance(off_df, pandas.core.frame.DataFrame):
        time_on = on_df.dragon_time
        total_time_on = time_on.max() - time_on.min()
        print(f'Total time ON = {total_time_on}')
        time_off = off_df.dragon_time
        total_time_off = time_off.max() - time_off.min()
        print(f'Total time OFF = {total_time_off}')
        
        scaling = total_time_off/total_time_on
        off_df_selected = off_df.query('gammaness > 0.5')
        dist_off = off_df_selected.source_x_prediction**2 + off_df_selected.source_y_prediction**2
        ax.hist(dist_off, bins=100, range=range, histtype='step', label='OFF', weights=np.full_like(dist_off, scaling))

    ax.hist(dist_on, bins=100, range=range, histtype='step', label='ON')
    ax.set_xlabel(r'$distance^2_{\mathrm{camera-center}} \,\, / \,\, \mathrm{m}^2$')
    ax.legend()
    ax.figure.tight_layout()

    if isinstance(off_df, pandas.core.frame.DataFrame):
        cut = 0.005
        n_off = np.count_nonzero(dist_off < cut)
        n_on = np.count_nonzero(dist_on < cut)
        li_ma = li_ma_significance(n_on, n_off, scaling)
        print(f'N_off = {n_off} \nN_on = {n_on} \nLi-Ma significance = {li_ma}')

    return ax

on = read_h5py('build/run01832_precuts.hdf5', key = 'events')
off = read_h5py('build/run01837_precuts.hdf5', key = 'events')
figures = []

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
dist_to_camera(on, off, ax)
ax.set_title('observations')

gamma = read_h5py('build/gamma-diffuse_testing_precuts.hdf5', key = 'events')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma.disp_prediction, bins=100, histtype='step')
ax.set_xlabel('disp prediction')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
ax.hist(gamma.gammaness, bins=100, histtype='step')
ax.set_xlabel('gammaness')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
dist_to_camera(gamma, ax, range=None)
ax.set_title('gamma-diffuse_testing_precuts')


with PdfPages('build/distance_plot.pdf') as pdf:
    for fig in figures:
        fig.tight_layout()
        pdf.savefig(fig)



#data: lbeiske@phobos:/net/cta-tank/POOL/projects/cta/LST/Data/DL1/v0.5.1
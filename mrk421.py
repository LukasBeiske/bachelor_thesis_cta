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
    'focal_length',
    'alt_tel',
    'az_tel'
]

runs = [
    'build/dl2_v0.5.1_LST-1.Run02113.h5',
    'build/dl2_v0.5.1_LST-1.Run02114.h5',
    'build/dl2_v0.5.1_LST-1.Run02115.h5',
    'build/dl2_v0.5.1_LST-1.Run02116.h5',
    'build/dl2_v0.5.1_LST-1.Run02117.h5',
    'build/dl2_v0.5.1_LST-1.Run02130.h5',
    'build/dl2_v0.5.1_LST-1.Run02131.h5',
    'build/dl2_v0.5.1_LST-1.Run02132.h5',
    'build/dl2_v0.5.1_LST-1.Run02133.h5'
]

df = pd.DataFrame()
for i, run in enumerate(runs):
    df = pd.concat( [
            df,
            read_h5py(run, key = 'events', columns=columns)
        ],
        ignore_index=True
    )

df_runs = []
for i, run in enumerate(runs):
    df_temp = read_h5py(run, key = 'events', columns=columns)
    df_runs.append(df_temp)


figures = []

#figures.append(plt.figure())
#ax = figures[-1].add_subplot(1, 1, 1)
#plotting.theta2(df_runs, 0.06, df_runs, ax=ax, coord='mrk 421', mode='runs', text_pos=400)
#ax.set_title('Mrk 421 coordinates, OFF = mirrored -> n_off = 3')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(df, 0.06, df, ax=ax, coord='mrk 421', n_off=3, text_pos=400)
ax.set_title('Mrk 421 coordinates, n_off = 3')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(df, 0.06, df, ax=ax, coord='mrk 421', n_off=5, text_pos=400)
ax.set_title('Mrk 421 coordinates, n_off = 5')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.theta2(df, 0.06, ax=ax, range=None)
ax.set_title('Mrk 421 camera center')

#mrk 421 coordinates
figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.plot2D_runs(df_runs, runs, 'mrk 421', ax)


#saving
with PdfPages('build/mrk421_plot.pdf') as pdf:
    for fig in figures:
        fig.tight_layout()
        pdf.savefig(fig)
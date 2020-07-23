import numpy as np
import matplotlib.pyplot as plt
from fact.io import read_h5py
import pandas as pd
import plotting
import click

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

@click.command()
@click.argument('outdir', type=click.Path(exists=True, dir_okay=True))
@click.argument('output', type=click.Path(exists=False, dir_okay=False))
def main(outdir, output):
    runs = [
        f'{outdir}/dl2_v0.5.1_LST-1.Run02113.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02114.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02115.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02116.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02117.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02130.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02131.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02132.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run02133.h5'
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
    theta2_cut = 0.04
    gammaness_threshold = 0.6

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df, theta2_cut, gammaness_threshold, df, ax=ax, coord='mrk 421', n_offs=3)
    ax.set_title('Mrk 421 coordinates, n_offs = 3')

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df, theta2_cut, gammaness_threshold, df, ax=ax, coord='mrk 421', n_offs=5)
    ax.set_title('Mrk 421 coordinates, n_offs = 5')

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df, theta2_cut, gammaness_threshold, ax=ax, range=None)
    ax.set_title('Mrk 421 camera center')

    #mrk 421 coordinates
    #figures.append(plt.figure())
    #ax = figures[-1].add_subplot(1, 1, 1)
    #plotting.plot2D_runs(df_runs, runs, 'mrk 421', gammaness_threshold, ax)


    #saving
    with PdfPages(output) as pdf:
        for fig in figures:
            fig.tight_layout()
            pdf.savefig(fig)


if __name__ == '__main__':
    main()
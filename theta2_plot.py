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
@click.argument('gamma_diff_file', type=click.Path(exists=True, dir_okay=False))
@click.argument('gamma_file', type=click.Path(exists=True, dir_okay=False))
@click.argument('output', type=click.Path(exists=False, dir_okay=False))
def main(outdir, gamma_diff_file, gamma_file, output):
    offs = [
        f'{outdir}/dl2_v0.5.1_LST-1.Run01837.h5', 
        f'{outdir}/dl2_v0.5.1_LST-1.Run01840.h5', 
        f'{outdir}/dl2_v0.5.1_LST-1.Run01841.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run01842.h5'
    ]

    ons = [
        f'{outdir}/dl2_v0.5.1_LST-1.Run01832.h5', 
        f'{outdir}/dl2_v0.5.1_LST-1.Run01833.h5', 
        f'{outdir}/dl2_v0.5.1_LST-1.Run01834.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run01835.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run01836.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run01843.h5',
        f'{outdir}/dl2_v0.5.1_LST-1.Run01844.h5'
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

    gamma_diff = read_h5py(gamma_diff_file, key = 'events')
    gamma = read_h5py(gamma_file, key = 'events')

    figures = []
    theta2_cut = 0.04
    gammaness_threshold = 0.6

    #theta2 camera center
    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df_on, theta2_cut, gammaness_threshold, df_off, ax)
    ax.set_title('Crab camera center, total-time scaling')

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df_on, theta2_cut, gammaness_threshold, df_off, ax, alpha='manuel')
    ax.set_title('Crab camera center, furthest $50\%$ scaling')

    #crab coordinates
    on_pointing = []
    for i, run in enumerate(ons):
        df = read_h5py(run, key = 'events', columns=columns)
        on_pointing.append(df)

    #figures.append(plt.figure())
    #ax = figures[-1].add_subplot(1, 1, 1)
    #plotting.plot2D_runs(on_pointing, ons, 'crab', gammaness_threshold, ax)
    #
    #figures.append(plt.figure())
    #ax = figures[-1].add_subplot(1, 1, 1)
    #plotting.plot2D(df_on, gammaness_threshold, ax)

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df_on, 0.1, gammaness_threshold, df_off, ax, coord='crab')
    ax.set_title('Crab coordinates, total-time scaling')

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.theta2(df_on, 0.1, gammaness_threshold, df_off, ax, alpha='manuel', coord='crab')
    ax.set_title('Crab coordinates, furthest $50\%$ scaling')

    #test plots
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

    #figures.append(plt.figure())
    #ax = figures[-1].add_subplot(1, 1, 1)
    #plotting.theta2(gamma_diff, theta2_cut, gammaness_threshold, ax=ax, range=None)
    #ax.set_title('gamma-diffuse testing')

    #angular resolustion
    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)
    plotting.angular_res(gamma, 'mc_energy', ax)
    ax.set_title('Angular resolution (no cuts)')

    figures.append(plt.figure())
    ax = figures[-1].add_subplot(1, 1, 1)

    gamma['sign_prediction'] = np.sign(gamma.disp_prediction)
    gamma_cuts = gamma.query('sign_prediction == disp_sign')
    gamma_cuts = gamma_cuts.query(f'gammaness > {gammaness_threshold}')
    plotting.angular_res(gamma_cuts, 'mc_energy', ax)
    ax.set_title(f'Angular resolution (correct sign prediction & gammaness > {gammaness_threshold})')

    #saving
    with PdfPages(output) as pdf:
        for fig in figures:
            fig.tight_layout()
            pdf.savefig(fig)


if __name__ == '__main__':
    main()
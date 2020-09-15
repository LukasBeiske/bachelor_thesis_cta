import numpy as np
import matplotlib.pyplot as plt
import matplotlib
from fact.io import (read_h5py, read_data)
import pandas as pd
import plotting

# some plots for the presentation
# bad code and hardcoded paths (had to be fast) !!!

def plot_bias_resolution(
        performance_df,
        key,
        label,
        bins=15,
        ax=None,
        label_column='mc_energy',
        prediction_column='gamma_energy_prediction',
        energy_unit='TeV'
):
    df = performance_df.copy()

    ax = ax or plt.gca()

    if np.isscalar(bins):
        bins = np.logspace(
            np.log10(df[label_column].min()),
            np.log10(df[label_column].max()),
            bins + 1
        )

    df['bin'] = np.digitize(df[label_column], bins)
    df['rel_error'] = (df[prediction_column] - df[label_column]) / df[label_column]

    binned = pd.DataFrame(index=np.arange(1, len(bins)))
    binned['center'] = 0.5 * (bins[:-1] + bins[1:])
    binned['width'] = np.diff(bins)

    grouped = df.groupby('bin')
    binned['bias'] = grouped['rel_error'].mean()
    binned['bias_median'] = grouped['rel_error'].median()
    binned['lower_sigma'] = grouped['rel_error'].agg(lambda s: np.percentile(s, 15))
    binned['upper_sigma'] = grouped['rel_error'].agg(lambda s: np.percentile(s, 85))
    binned['resolution_quantiles'] = (binned.upper_sigma - binned.lower_sigma) / 2
    binned = binned[grouped.size() > 100]  # at least one hundred events

    ax.errorbar(
        binned['center'],
        binned[key],
        xerr=0.5 * binned['width'],
        label=label,
        linestyle='',
    )
    ax.legend()
    ax.set_xscale('log')
    ax.set_xlabel(
            rf'$\log_{{10}}(E_{{\mathrm{{MC}}}} \,\, / \,\, \mathrm{{{energy_unit}}})$'
    )

    return ax

gamma_2_150 = read_h5py('build/dl2_gamma_south_pointing_20200706_v0.5.2_local_DL1_testing.h5', key = 'events')
gamma_2_300 = read_h5py('HDD/build_scaling_300/dl2_gamma_south_pointing_20200706_v0.5.2_local_DL1_testing.h5', key = 'events')
gamma_1_150 = read_h5py('HDD/build_noscaling/dl2_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5', key = 'events')
gamma_1_300 = read_h5py('HDD/build_noscaling_300/dl2_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5', key = 'events')

gammaness_threshold = 0.6

figures = []

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.angular_res(gamma_1_150, 'mc_energy', ax, label='noscaling_150')
plotting.angular_res(gamma_1_300, 'mc_energy', ax, label='noscaling_300')
plotting.angular_res(gamma_2_150, 'mc_energy', ax, label='scaling_150')
plotting.angular_res(gamma_2_300, 'mc_energy', ax, label='scaling_300')
ax.set_title('All events')

# event selection
gamma_2_150['sign_prediction'] = np.sign(gamma_2_150.disp_prediction)
gamma_2_150_cuts = gamma_2_150.query('sign_prediction == disp_sign')
gamma_2_150_cuts = gamma_2_150_cuts.query(f'gammaness > {gammaness_threshold}')

gamma_2_300['sign_prediction'] = np.sign(gamma_2_300.disp_prediction)
gamma_2_300_cuts = gamma_2_300.query('sign_prediction == disp_sign')
gamma_2_300_cuts = gamma_2_300_cuts.query(f'gammaness > {gammaness_threshold}')

gamma_1_150['sign_prediction'] = np.sign(gamma_1_150.disp_prediction)
gamma_1_150_cuts = gamma_1_150.query('sign_prediction == disp_sign')
gamma_1_150_cuts = gamma_1_150_cuts.query(f'gammaness > {gammaness_threshold}')

gamma_1_300['sign_prediction'] = np.sign(gamma_1_300.disp_prediction)
gamma_1_300_cuts = gamma_1_300.query('sign_prediction == disp_sign')
gamma_1_300_cuts = gamma_1_300_cuts.query(f'gammaness > {gammaness_threshold}')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plotting.angular_res(gamma_1_150_cuts, 'mc_energy', ax, label='noscaling_150')
plotting.angular_res(gamma_1_300_cuts, 'mc_energy', ax, label='noscaling_300')
plotting.angular_res(gamma_2_150_cuts, 'mc_energy', ax, label='scaling_150')
plotting.angular_res(gamma_2_300_cuts, 'mc_energy', ax, label='scaling_300')
ax.set_title(rf'correct sign and $p_\gamma > {gammaness_threshold}$')


# energy perfromance
energy_2_150 = read_data('build/cv_regressor.h5', key='data')
energy_2_300 = read_data('HDD/build_scaling_300/cv_regressor.h5', key = 'data')
energy_1_150 = read_data('HDD/build_noscaling/cv_regressor.h5', key = 'data')
energy_1_300 = read_data('HDD/build_noscaling_300/cv_regressor.h5', key = 'data')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plot_bias_resolution(energy_1_150, key='bias', label='noscaling_150', ax=ax)
plot_bias_resolution(energy_1_300, key='bias', label='noscaling_300', ax=ax)
plot_bias_resolution(energy_2_150, key='bias', label='scaling_150', ax=ax)
plot_bias_resolution(energy_2_300, key='bias', label='scaling_300', ax=ax)
ax.set_title('Bias')

figures.append(plt.figure())
ax = figures[-1].add_subplot(1, 1, 1)
plot_bias_resolution(energy_1_150, key='resolution_quantiles', label='noscaling_150', ax=ax)
plot_bias_resolution(energy_1_300, key='resolution_quantiles', label='noscaling_300', ax=ax)
plot_bias_resolution(energy_2_150, key='resolution_quantiles', label='scaling_150', ax=ax)
plot_bias_resolution(energy_2_300, key='resolution_quantiles', label='scaling_300', ax=ax)
ax.set_title('quantile Resolution')


for i, fig in enumerate(figures):
    fig.tight_layout()
    fig.savefig(f'build/plot_talk_{i}.pdf')
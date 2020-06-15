import numpy as np
import matplotlib.pyplot as plt
from fact.analysis.statistics import li_ma_significance
import pandas as pd

def theta2(df_on, df_off=None, ax=None, range=[0,1], alpha='total_time'):

    ax = ax or plt.gca()
    df_on_selected = df_on.query('gammaness > 0.7')

    dist_on = df_on_selected.source_x_prediction**2 + df_on_selected.source_y_prediction**2
    theta2_on = np.rad2deg(np.sqrt(dist_on) / df_on.focal_length)**2

    if df_off is not None:
        df_off_selected = df_off.query('gammaness > 0.7')
        
        dist_off = df_off_selected.source_x_prediction**2 + df_off_selected.source_y_prediction**2
        theta2_off = np.rad2deg(np.sqrt(dist_off) / df_off.focal_length)**2

        delta_on = np.diff(df_on.dragon_time.sort_values())
        delta_on = delta_on[np.abs(delta_on) < 10]
        total_time_on = len(df_on) * delta_on.mean() 
        print(f'Total time ON = {total_time_on}')

        delta_off = np.diff(df_off.dragon_time.sort_values())
        delta_off = delta_off[np.abs(delta_off) < 10]
        total_time_off = len(df_off) * delta_off.mean() 
        print(f'Total time OFF = {total_time_off}')

        if alpha == 'total_time':
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

    if df_off is not None:
        cut = 0.065
        n_off = np.count_nonzero(theta2_off < cut)
        n_on = np.count_nonzero(theta2_on < cut)
        li_ma = li_ma_significance(n_on, n_off, scaling)
        n_exc_mean = n_on - scaling * n_off
        n_exc_std = np.sqrt(n_on + scaling**2 * n_off)

        ax.axvline(x=cut, color='k', lw=0.1)
        if alpha == 'total_time':
            total_time_on_hour = total_time_on / 3600
            total_time_off_hour = total_time_off / 3600
            text = (rf'$N_\mathrm{{on}} = {n_on},\, N_\mathrm{{off}} = {n_off}$' + '\n' 
                + rf'$t_\mathrm{{on}} = {total_time_on_hour:.2f} \mathrm{{h}},\, t_\mathrm{{off}} = {total_time_off_hour:.2f} \mathrm{{h}},\, \alpha = {scaling:.2f}$' + '\n' 
                + rf'$N_\mathrm{{exc}} = {n_exc_mean:.0f} \pm {n_exc_std:.0f},\, S_\mathrm{{Li&Ma}} = {li_ma:.2f}$'
            )
        else:
            text = (rf'$N_\mathrm{{on}} = {n_on},\, N_\mathrm{{off}} = {n_off},\, \alpha = {scaling:.2f}$' + '\n' 
                + rf'$N_\mathrm{{exc}} = {n_exc_mean:.0f} \pm {n_exc_std:.0f},\, S_\mathrm{{Li&Ma}} = {li_ma:.2f}$'
            )
        
        ax.text(0.3, 900, text)

    return ax


def angular_res(df, true_energy_column, ax=None):

    df = df.copy()
    edges = 10**np.arange(
        np.log10(df[true_energy_column].min()),
        np.log10(df[true_energy_column].max()),
        0.2     #cta convention
    )
    df['bin_idx'] = np.digitize(df[true_energy_column], edges)

    binned = pd.DataFrame({
        'e_center': 0.5 * (edges[1:] + edges[:-1]),
        'e_low': edges[:-1],
        'e_high': edges[1:],
        'e_width': np.diff(edges),
    }, index=pd.Series(np.arange(1, len(edges)), name='bin_idx'))

    df['diff'] = np.rad2deg(
        np.sqrt((df.source_x_prediction - df.src_x)**2 + (df.source_y_prediction - df.src_y)**2)
        / df.focal_length
    )

    def f(group):
        group = group.sort_values('diff')
        group = group.dropna(axis='index', subset=['diff'])
        group68 = group.quantile(q=0.68)
        return group68['diff']

    grouped = df.groupby('bin_idx')
    binned['ang_res'] = grouped.apply(f)
    
    ax = ax or plt.gca()

    ax.errorbar(
        binned.e_center, binned.ang_res,
        xerr=binned.e_width / 2,
        ls='',
        label=r'$68^{\mathrm{th}}$ Percentile'
    )
    ax.set_ylabel(r'$\theta \,\, / \,\, \mathrm{deg}$')
    ax.set_xlabel(
        r'$E_{\mathrm{true}} \,\,/\,\, \mathrm{TeV}$'
    )
    ax.set_xscale('log')
    ax.legend()

    return ax
import numpy as np
import matplotlib.pyplot as plt
from fact.analysis.statistics import li_ma_significance
import pandas as pd

def theta2(df_on, df_off=None, ax=None, range=[0,1], alpha='total_time'):

    ax = ax or plt.gca()
    df_on_selected = df_on.query('gammaness > 0.7')
    df_on_selected = df_on_selected.query('concentration_cog > 0.0025')

    dist_on = df_on_selected.source_x_prediction**2 + df_on_selected.source_y_prediction**2
    theta2_on = np.rad2deg(np.sqrt(dist_on) / df_on.focal_length)**2

    if isinstance(df_off, pd.DataFrame):
        df_off_selected = df_off.query('gammaness > 0.7')
        df_off_selected = df_off_selected.query('concentration_cog > 0.0025')
        
        dist_off = df_off_selected.source_x_prediction**2 + df_off_selected.source_y_prediction**2
        theta2_off = np.rad2deg(np.sqrt(dist_off) / df_off.focal_length)**2

        if alpha == 'total_time':
            time_on = df_on.dragon_time
            total_time_on = time_on.max() - time_on.min()
            print(f'Total time ON = {total_time_on}')
            time_off = df_off.dragon_time
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

    if isinstance(df_off, pd.DataFrame):
        cut = 0.065
        n_off = np.count_nonzero(theta2_off < cut)
        n_on = np.count_nonzero(theta2_on < cut)
        li_ma = li_ma_significance(n_on, n_off, scaling)

        ax.axvline(x=cut, color='k', lw=0.1)
        text = rf'$N_\mathrm{{off}} = {n_off}, N_\mathrm{{on}} = {n_on}, \alpha = {scaling:.2f}$' + '\n' + rf'$S_\mathrm{{Li&Ma}} = {li_ma:.2f}$'
        ax.text(0.3, 900, text)

    return ax


def angular_res(df, true_energy_column, ax=None):

    df = df.copy()
    edges = 10**np.arange(                                                      #Warum hier diser Umweg mit log10? -> Damit hohe Energien nicht dominieren? Ne...
        np.log10(df[true_energy_column].min()),
        np.log10(df[true_energy_column].max()),
        0.2
    )
    df['bin_idx'] = np.digitize(df[true_energy_column], edges)

    # discard under and overflow                                                Kann doch eig gar nicht passieren, weil edges über min() und max() definiert?!
    df = df[(df['bin_idx'] != 0) & (df['bin_idx'] != len(edges))]

    binned = pd.DataFrame({
        'e_center': 0.5 * (edges[1:] + edges[:-1]),
        'e_low': edges[:-1],
        'e_high': edges[1:],
        'e_width': np.diff(edges),
    }, index=pd.Series(np.arange(1, len(edges)), name='bin_idx'))

    df['diff'] = np.rad2deg(np.sqrt(
            np.abs(np.sqrt(df.source_x_prediction**2 + df.source_y_prediction**2) - np.sqrt(df.src_x**2 + df.src_y**2)) #difference as distance
            ) 
        / df.focal_length
        )

    def f(group):
        group = group.sort_values('diff')
        group = group.dropna(axis='index', subset=['diff'])
        group68 = group.quantile(q=0.68)
        return group68['diff']
        
    ang_res = pd.DataFrame(index=binned.index)

    grouped = df.groupby('bin_idx')
    ang_res = grouped.apply(f)

    ax = ax or plt.gca()

    ax.errorbar(
        binned.e_center, ang_res,
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
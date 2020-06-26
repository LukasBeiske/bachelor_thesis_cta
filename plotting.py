import numpy as np
import matplotlib.pyplot as plt
from fact.analysis.statistics import li_ma_significance
import pandas as pd
from astropy.time import Time
from astropy.coordinates import SkyCoord, AltAz, EarthLocation
import astropy.units as u
from ctapipe.coordinates import CameraFrame

def theta2(df_on, cut,  df_off=None, ax=None, range=[0,1], alpha='total_time', coord=None):

    ax = ax or plt.gca()
    df_on_selected = df_on.query('gammaness > 0.7')

    if coord is not None:
        def coord_trafo(df):
            crab = SkyCoord.from_name('crab')
            altaz = AltAz(
                location = EarthLocation.of_site('Roque de los Muchachos'),
                obstime = Time(df.dragon_time, format='unix')
            )
            telescope_pointing = SkyCoord(
                alt = u.Quantity(df.alt_tel.to_numpy(), u.rad, copy=False),
                az = u.Quantity(df.az_tel.to_numpy(), u.rad, copy=False),
                frame = altaz
            )
            camera_frame = CameraFrame(
                focal_length = u.Quantity(df.focal_length.to_numpy(), u.m, copy=False),
                telescope_pointing = telescope_pointing,
                location = EarthLocation.of_site('Roque de los Muchachos'),
                obstime = Time(df.dragon_time, format='unix')
            )
            crab_cf = crab.transform_to(camera_frame)

            dist = (df.source_x_prediction - crab_cf.x.to_value(u.m))**2 + (df.source_y_prediction - crab_cf.y.to_value(u.m))**2
            return dist

        dist_on = coord_trafo(df_on_selected)
    else:
        dist_on = df_on_selected.source_x_prediction**2 + df_on_selected.source_y_prediction**2
    
    theta2_on = np.rad2deg(np.sqrt(dist_on) / df_on.focal_length)**2

    if df_off is not None:
        df_off_selected = df_off.query('gammaness > 0.7')
        
        dist_off = df_off_selected.source_x_prediction**2 + df_off_selected.source_y_prediction**2

        theta2_off = np.rad2deg(np.sqrt(dist_off) / df_off.focal_length)**2

        def total_t(df):
            delta = np.diff(df.dragon_time.sort_values())
            delta = delta[np.abs(delta) < 10]
            return len(df) * delta.mean()

        total_time_on = total_t(df_on)
        total_time_off = total_t(df_off)

        if alpha == 'total_time':
            scaling = total_time_on/total_time_off
        else:
            norm_range = range[1] - range[1]/10

            def mean_count(theta2):
                hist = np.histogram(theta2[theta2 < range[1]], bins=100)
                x = hist[1]
                x = x[:-1].copy()
                return np.mean(hist[0][x > norm_range])

            scaling = mean_count(theta2_on) / mean_count(theta2_off)
        
        ax.hist(theta2_off, bins=100, range=range, histtype='step', label='OFF', weights=np.full_like(theta2_off, scaling))

    ax.hist(theta2_on, bins=100, range=range, histtype='step', label='ON')
    ax.set_xlabel(r'$\theta^2 \,\, / \,\, \mathrm{deg}^2$')
    ax.legend()
    ax.figure.tight_layout()

    if df_off is not None:
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
        
        ax.text(0.3, 400, text)

    return ax


def angular_res(df, true_energy_column, ax=None):

    df = df.copy()
    edges = 10**np.arange(
        np.log10(df[true_energy_column].min()),
        np.log10(df[true_energy_column].max()),
        0.2     #cta convention: 5 bins per energy decade
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
    counts = grouped.size()
    binned['ang_res'] = grouped.apply(f)
    binned['counts'] = counts
    binned = binned.query('counts > 50') # at least 50 events per bin
    
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


def plot2D(df, ax=None):

    ax = ax or plt.gca()
    df_selected = df.query('gammaness > 0.7')

    crab = SkyCoord.from_name('crab')
    altaz = AltAz(
        location = EarthLocation.of_site('Roque de los Muchachos'),
        obstime = Time(df_selected.dragon_time, format='unix')
    )
    telescope_pointing = SkyCoord(
        alt = u.Quantity(df_selected.alt_tel.to_numpy(), u.rad, copy=False),
        az = u.Quantity(df_selected.az_tel.to_numpy(), u.rad, copy=False),
        frame = altaz
    )
    camera_frame = CameraFrame(
        focal_length = u.Quantity(df_selected.focal_length.to_numpy(), u.m, copy=False),
        telescope_pointing = telescope_pointing,
        location = EarthLocation.of_site('Roque de los Muchachos'),
        obstime = Time(df_selected.dragon_time, format='unix')
    )
    crab_cf = crab.transform_to(camera_frame)

    ax.hist2d(crab_cf.x.to_value(u.m), crab_cf.y.to_value(u.m), bins = 100)

    return ax
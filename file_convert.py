import pandas as pd
from fact.io import to_h5py
import numpy as np
import click

@click.command()
@click.argument('infile', type=click.Path(exists=True, dir_okay=False))
@click.argument('outfile', type=click.Path(exists=False, dir_okay=False))
@click.argument('inkey')
def main(infile, outfile, inkey):
    df = pd.read_hdf(infile, key = inkey)

    # simulations
    if 'mc_az' in df.columns:
        df['pointing_azimuth'] = np.rad2deg(df.mc_az_tel)
        df['pointing_zenith'] = 90 - np.rad2deg(df.mc_alt_tel)
        df['source_azimuth'] = np.rad2deg(df.mc_az)
        df['source_zenith'] = 90 - np.rad2deg(df.mc_alt)
    # observations
    else:
        df['pointing_azimuth'] = np.rad2deg(df.az_tel)
        df['pointing_zenith'] = 90 - np.rad2deg(df.alt_tel)
    
    df['psi_deg'] = np.rad2deg(df.psi)
    df['focal_length'] = 28
    to_h5py(df, outfile, key='events', mode = 'w')

if __name__ == '__main__':
    main()
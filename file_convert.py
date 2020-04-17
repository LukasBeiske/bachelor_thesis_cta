import pandas as pd
from fact.io import to_h5py

df = pd.read_hdf('/home/lukas/Bachelorarbeit/bachelor_thesis_cta_analysis/dl1_gamma_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5', key='dl1/event/telescope/parameters/LST_LSTCam')
to_h5py(df, 'gamma_training.hdf5', key='events')

df = pd.read_hdf('/home/lukas/Bachelorarbeit/bachelor_thesis_cta_analysis/dl1_gamma-diffuse_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5', key='dl1/event/telescope/parameters/LST_LSTCam')
to_h5py(df, 'gamma-diffuse_training.hdf5', key='events')

df = pd.read_hdf('/home/lukas/Bachelorarbeit/bachelor_thesis_cta_analysis/dl1_proton_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5', key='dl1/event/telescope/parameters/LST_LSTCam')
to_h5py(df, 'proton_training.hdf5', key='events')
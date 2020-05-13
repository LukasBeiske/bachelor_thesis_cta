from fact.io import read_h5py
from aict_tools.cta_helpers import horizontal_to_camera_cta_simtel
import pandas as pd
import joblib
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import numpy as np

figures = []

#Plote Feature Importance
clf = joblib.load(open('build/sign.pkl', 'rb'))
series = pd.Series(clf.feature_importances_, index = clf.feature_names).sort_values()

figures.append(plt.figure())
ax1 = figures[-1].add_subplot(1, 1, 1)
ax1.barh(series.index, series.values)
ax1.set_title("Feature Importance")

#Plote disp_angle - psi
df = read_h5py('build/gamma-diffuse_training_precuts.hdf5', key= 'events')

figures.append(plt.figure())
ax2 = figures[-1].add_subplot(1, 1, 1)
ax2.hist(df.disp_angle-df.psi, bins = 100)
ax2.set_title("disp_angle - psi")

#Plote true_psi - psi
df['source_x'], df['source_y'] = horizontal_to_camera_cta_simtel(
            az=df.source_azimuth,
            zd=df.source_zenith,
            az_pointing=df.pointing_azimuth,
            zd_pointing=df.pointing_zenith,
            focal_length=df.focal_length,
        )
true_psi = np.arctan2(df.source_y - df.y, df.source_x - df.x)

figures.append(plt.figure())
ax3 = figures[-1].add_subplot(1, 1, 1)
ax3.hist(true_psi-df.psi, bins = 100)
ax3.set_title("true_psi - psi")

#Test
#figures.append(plt.figure())
#ax4 = figures[-1].add_subplot(1, 1, 1)
#ax4.scatter(df.disp_norm, np.sqrt((df.source_x - df.x)**2 + (df.source_y - df.y)**2))
#ax4.set_title("Test")

#Test 2D
#figures.append(plt.figure())
#ax5 = figures[-1].add_subplot(1, 1, 1)
#ax5.hist2d(df.x, df.y, bins=100)
#ax5.set_title("Test 2D")

with PdfPages('plots/disp_performance.pdf') as pdf:
    for fig in figures:
        fig.tight_layout()
        pdf.savefig(fig)
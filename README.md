# Bachelor thesis on high level analysis for the LST-1

The [`aict-tools`](https://github.com/fact-project/aict-tools) are used to train an apply the random forest algorithm for

* Gamma/Hadron Separation
* Energy Regression
* Reconstruction of origin

### An updated and improved version of the analysis performed here can be found in the [`LST_mono_analysis`](https://github.com/tudo-astroparticlephysics/LST_mono_analysis) repository.

## Data used

1. The models are trained on Monte Carlo simulations of diffuse protons, diffuse gamma-rays and gamma-rays from a point-like source (prod3b).

2. The trained models are used to analyse the following observational data
    * Crab Nebula: 2.63h ON and 1.33h OFF (taken on 18.01.2020)
    * Markarian 421: 2.22h wobble mode (taken on 20.06.2020)

3. All data (MCs and observations) was processed up to image parameter level (DL1) using [`lstchain`](https://github.com/cta-observatory/cta-lstchain) (not part of this thesis).

## How to build this thesis

1. Create a new conda environment and install the necessary python packages defined in environment.yaml:
    ```
    $ conda env create -n bachelor_thesis_lbeiske -f environment.yaml
    $ conda activate bachelor_thesis_lbeiske
    ```

2. Download input files and store in `data` in the root of this repository:
    * Simulations: `/net/cta-tank/POOL/projects/cta/LST/Simulations/DL1/20190415` (only `%_v0.5.1_%` and `%_v0.5.2_%` files necessary)
    * Observational data: `/net/cta-tank/POOL/projects/cta/LST/Data/DL1/v0.5.1`

3. ```
    $ make
    ```

4. ```
    $ mkdir HDD
    $ make OUTDIR=HDD/build_scaling_300 \
    CUTS_CONFIG=config/quality_cuts_300.yaml
    ```

5. ```
    $ make OUTDIR=HDD/build_noscaling_300 \
    GAMMA_FILE=gamma_south_pointing_20200514_v0.5.1_v01_DL1 \
    GAMMA_DIFFUSE_FILE=gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1 \
    PROTON_FILE=proton_south_pointing_20200514_v0.5.1_v01_DL1 \
    CUTS_CONFIG=config/quality_cuts_300.yaml
    ```

6. ```
    $ make OUTDIR=HDD/build_noscaling \
    GAMMA_FILE=gamma_south_pointing_20200514_v0.5.1_v01_DL1 \
    GAMMA_DIFFUSE_FILE=gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1 \
    PROTON_FILE=proton_south_pointing_20200514_v0.5.1_v01_DL1 
    ```

7. ``` 
    $ make build/thesis.pdf
    ```

8. Build the presentation:
    ```
    $ cd presentation
    $ make
    ```
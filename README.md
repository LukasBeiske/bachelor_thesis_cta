# Bachelor thesis on high level analysis for the LST-1

The [`aict-tools`](https://github.com/fact-project/aict-tools) are used to train an apply the random forest algorithm for

* Gamma/Hadron Separation
* Energy Regression
* Reconstruction of origin

## Data used

1. The models are trained on Monte Carlo simulations of diffuse protons, diffuse gamma-rays and gamma-rays from a point-like source (prod3b).

2. The trained models are used to analyse the following observational data
    * Crab Nebula: 2.63h ON and 1.33h OFF (taken on 18.01.2020)
    * Markarian 421: 2.22h wobble mode (taken on 20.06.2020)

3. All data (MCs and observations) was processed up to image parameter level (DL1) using [`lstchain`](https://github.com/cta-observatory/cta-lstchain) (not part of this thesis).

## How to build this thesis (if necessary software is installed)

1. Download input files and store in `data` in the root of this repository:
    * Simulations: `/net/cta-tank/POOL/projects/cta/LST/Simulations/DL1/20190415` (only `%_v0.5.1_%` and `%_v0.5.2_%` files necessary)
    * Observational data: `/net/cta-tank/POOL/projects/cta/LST/Data/DL1/v0.5.1`

2. ```
    $ make
    ```

3. ```
    $ mkdir HDD
    $ make OUTDIR=HDD/build_scaling_300 \
    CUTS_CONFIG=config/quality_cuts_300.yaml
    ```

4. ```
    $ make OUTDIR=HDD/build_noscaling_300 \
    GAMMA_FILE=gamma_south_pointing_20200514_v0.5.1_v01_DL1 \
    GAMMA_DIFFUSE_FILE=gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1 \
    PROTON_FILE=proton_south_pointing_20200514_v0.5.1_v01_DL1 \
    CUTS_CONFIG=config/quality_cuts_300.yaml
    ```

5. ```
    $ make OUTDIR=HDD/build_noscaling \
    GAMMA_FILE=gamma_south_pointing_20200514_v0.5.1_v01_DL1 \
    GAMMA_DIFFUSE_FILE=gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1 \
    PROTON_FILE=proton_south_pointing_20200514_v0.5.1_v01_DL1 
    ```

6. ``` 
    $ make build/thesis.pdf
    ```

7. Build the presentation:
    ```
    $ cd presentation
    $ make
    ```
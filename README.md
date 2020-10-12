# Bachelor thesis on high level analysis for the LST-1

The [`aict-tools`](https://github.com/fact-project/aict-tools) are used to train an apply the random forest algorithm for

* Gamma/Hadron Separation
* Energy Regression
* Reconstruction of origin

The models are trained on Monte Carlo simulations of diffuse protons, diffuse gamma-rays and gamma-rays from a point-like source (prod3b).

The trained models are used to analyse the following observational data

* Crab Nebula: 2.63h ON and 1.33h OFF (taken on 18.01.2020)
* Markarian 421: 2.22h wobble mode (taken on 20.06.2020)

All data (MCs and observations) was processed up to image parameter level (DL1) using [`lstchain`](https://github.com/cta-observatory/cta-lstchain) (not part of this thesis)
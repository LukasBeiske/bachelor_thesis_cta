OUTDIR = build
INDIR = /media/lukas/Data/TU_Dortmund/bachelor_thesis_cta_DATA

GAMMA_FILE_TR = dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_training
GAMMA_FILE_TE = dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing
GAMMA_DIFFUSE_FILE_TR = dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_training
GAMMA_DIFFUSE_FILE_TE = dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_testing
PROTON_FILE_TR = dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_training
PROTON_FILE_TE = dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_testing
TEL_NAME = LST_LSTCam

AICT_CONFIG=config/aict.yaml

all: $(OUTDIR)/cv_separation.hdf5 $(OUTDIR)/cv_disp.hdf5 $(OUTDIR)/cv_regressor.hdf5 

#file convertion
$(OUTDIR)/%.hdf5: $(INDIR)/%.h5 file_convert.py | $(OUTDIR)
	python file_convert.py \
		$< \
		$@ \
		$(TEL_NAME)

#precuts
$(OUTDIR)/%_precuts.hdf5: $(OUTDIR)/%.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$< \
		$@

#train models
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5: $(AICT_CONFIG) $(OUTDIR)/$(PROTON_FILE_TR)_precuts.hdf5 
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5: $(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5
	aict_train_separation_model \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5 \
		$(OUTDIR)/$(PROTON_FILE_TR)_precuts.hdf5 \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl

$(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/cv_disp.hdf5: $(AICT_CONFIG) $(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5
	aict_train_disp_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5 \
		$(OUTDIR)/cv_disp.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl

$(OUTDIR)/regressor.pkl $(OUTDIR)/cv_regressor.hdf5: $(AICT_CONFIG) $(OUTDIR)/$(GAMMA_FILE_TR)_precuts.hdf5
	aict_train_energy_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_FILE_TR)_precuts.hdf5 \
		$(OUTDIR)/cv_regressor.hdf5 \
		$(OUTDIR)/regressor.pkl

#apply models
apply_test: $(AICT_CONFIG) $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_test: $(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TE)_precuts.hdf5 $(OUTDIR)/$(PROTON_FILE_TE)_precuts.hdf5 $(OUTDIR)/$(GAMMA_FILE_TE)_precuts.hdf5 | $(OUTDIR)
	aict_apply_separation_model \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl
	aict_apply_separation_model \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(PROTON_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(PROTON_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(PROTON_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl
	aict_apply_separation_model \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/$(GAMMA_FILE_TE)_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl



#apply to observations
apply_data: $(OUTDIR)/dl1_v0.5.1_LST-1.Run01832_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01833_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01834_precuts.hdf5
apply_data: $(OUTDIR)/dl1_v0.5.1_LST-1.Run01835_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01836_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01837_precuts.hdf5
apply_data: $(OUTDIR)/dl1_v0.5.1_LST-1.Run01840_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01841_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01842_precuts.hdf5
apply_data: $(OUTDIR)/dl1_v0.5.1_LST-1.Run01843_precuts.hdf5 $(OUTDIR)/dl1_v0.5.1_LST-1.Run01844_precuts.hdf5

$(OUTDIR)/dl1_v0.5.1_LST-1.Run%_precuts.hdf5: $(AICT_CONFIG) $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
$(OUTDIR)/dl1_v0.5.1_LST-1.Run%_precuts.hdf5: $(OUTDIR)/dl1_v0.5.1_LST-1.Run%.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$< \
		$@
	aict_apply_separation_model \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/regressor.pkl



#plot performances (For direct call via '$make <path>')
$(OUTDIR)/regressor_plots.pdf: $(AICT_CONFIG) $(OUTDIR)/cv_regressor.hdf5 | $(OUTDIR)
	aict_plot_regressor_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_regressor.hdf5 \
		$(OUTDIR)/regressor.pkl \
		-o $(OUTDIR)/regressor_plots.pdf

$(OUTDIR)/separator_plots.pdf: $(AICT_CONFIG)  $(OUTDIR)/cv_separation.hdf5 | $(OUTDIR)
	aict_plot_separator_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl \
		-o $(OUTDIR)/separator_plots.pdf

$(OUTDIR)/disp_plots.pdf: $(AICT_CONFIG)  $(OUTDIR)/cv_disp.hdf5 $(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5 | $(OUTDIR)
	aict_plot_disp_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_disp.hdf5 \
		$(OUTDIR)/$(GAMMA_DIFFUSE_FILE_TR)_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl \
		-o $(OUTDIR)/disp_plots.pdf



$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean
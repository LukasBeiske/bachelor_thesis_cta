OUTDIR=build
INDIR=data

GAMMA_FILE_TR=$(INDIR)/dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
GAMMA_FILE_TE=$(INDIR)/dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
GAMMA_DIFFUSE_FILE_TR=$(INDIR)/dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
GAMMA_DIFFUSE_FILE_TE=$(INDIR)/dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
PROTON_FILE_TR=$(INDIR)/dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
PROTON_FILE_TE=$(INDIR)/dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
TEL_NAME=LST_LSTCam

all: $(OUTDIR)/cv_separation.hdf5 $(OUTDIR)/cv_disp.hdf5 $(OUTDIR)/cv_regressor.hdf5 
apply: apply_gamma-diffuse_testing apply_proton_testing apply_gamma_testing

#file convertion
$(OUTDIR)/gamma_training.hdf5: $(GAMMA_FILE_TR) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_FILE_TR)\
		$(OUTDIR)/gamma_training.hdf5 \
		$(TEL_NAME)

$(OUTDIR)/gamma_testing.hdf5: $(GAMMA_FILE_TE) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_FILE_TE)\
		$(OUTDIR)/gamma_testing.hdf5 \
		$(TEL_NAME)

$(OUTDIR)/gamma-diffuse_training.hdf5: $(GAMMA_DIFFUSE_FILE_TR) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_DIFFUSE_FILE_TR)\
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(TEL_NAME)

$(OUTDIR)/gamma-diffuse_testing.hdf5: $(GAMMA_DIFFUSE_FILE_TE) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_DIFFUSE_FILE_TE)\
		$(OUTDIR)/gamma-diffuse_testing.hdf5 \
		$(TEL_NAME)

$(OUTDIR)/proton_training.hdf5: $(PROTON_FILE_TR) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(PROTON_FILE_TR)\
		$(OUTDIR)/proton_training.hdf5 \
		$(TEL_NAME)

$(OUTDIR)/proton_testing.hdf5: $(PROTON_FILE_TE) file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(PROTON_FILE_TE)\
		$(OUTDIR)/proton_testing.hdf5 \
		$(TEL_NAME)

#precuts
$(OUTDIR)/gamma_training_precuts.hdf5: $(OUTDIR)/gamma_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma_training.hdf5 \
		$(OUTDIR)/gamma_training_precuts.hdf5 

$(OUTDIR)/gamma_testing_precuts.hdf5: $(OUTDIR)/gamma_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma_testing.hdf5 \
		$(OUTDIR)/gamma_testing_precuts.hdf5 

$(OUTDIR)/gamma-diffuse_training_precuts.hdf5: $(OUTDIR)/gamma-diffuse_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 

$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5: $(OUTDIR)/gamma-diffuse_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing.hdf5 \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 

$(OUTDIR)/proton_training_precuts.hdf5: $(OUTDIR)/proton_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/proton_training.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 

$(OUTDIR)/proton_testing_precuts.hdf5: $(OUTDIR)/proton_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/proton_testing.hdf5 \
		$(OUTDIR)/proton_testing_precuts.hdf5 

#train models
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5: config/config_separator_lb.yaml $(OUTDIR)/proton_training_precuts.hdf5 $(OUTDIR)/gamma-diffuse_training_precuts.hdf5
	aict_train_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl

$(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/cv_disp.hdf5: config/config_source_cta_lb.yaml $(OUTDIR)/gamma-diffuse_training_precuts.hdf5
	aict_train_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/cv_disp.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl

$(OUTDIR)/regressor.pkl $(OUTDIR)/cv_regressor.hdf5: config/config_energy_lb.yaml $(OUTDIR)/gamma_training_precuts.hdf5
	aict_train_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/gamma_training_precuts.hdf5 \
		$(OUTDIR)/cv_regressor.hdf5 \
		$(OUTDIR)/regressor.pkl

#apply models
apply_gamma-diffuse_testing: config/config_separator_lb.yaml config/config_source_cta_lb.yaml config/config_energy_lb.yaml
apply_gamma-diffuse_testing: $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_gamma-diffuse_testing: $(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 | $(OUTDIR)
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl

apply_proton_testing: config/config_separator_lb.yaml config/config_source_cta_lb.yaml config/config_energy_lb.yaml
apply_proton_testing: $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_proton_testing: $(OUTDIR)/proton_testing_precuts.hdf5 | $(OUTDIR)
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/proton_testing_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/proton_testing_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/proton_testing_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl

apply_gamma_testing: config/config_separator_lb.yaml config/config_source_cta_lb.yaml config/config_energy_lb.yaml
apply_gamma_testing: $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_gamma_testing: $(OUTDIR)/gamma_testing_precuts.hdf5 | $(OUTDIR)
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma_testing_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/gamma_testing_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/gamma_testing_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl



#apply to observations (For direct call via '$make <path>')
apply_runON: config/quality_cuts_lb.yaml config/config_separator_lb.yaml config/config_source_cta_lb.yaml config/config_energy_lb.yaml
apply_runON: $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_runON: $(INDIR)/dl1_v0.5.1_LST-1.Run01832.h5 file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(INDIR)/dl1_v0.5.1_LST-1.Run01832.h5 \
		$(OUTDIR)/run01832.hdf5 \
		$(TEL_NAME)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/run01832.hdf5 \
		$(OUTDIR)/run01832_precuts.hdf5
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/run01832_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/run01832_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/run01832_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl

apply_runOFF: config/quality_cuts_lb.yaml config/config_separator_lb.yaml config/config_source_cta_lb.yaml config/config_energy_lb.yaml
apply_runOFF: $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/regressor.pkl
apply_runOFF: $(INDIR)/dl1_v0.5.1_LST-1.Run01837.h5 file_convert.py | $(OUTDIR)
	python file_convert.py \
		$(INDIR)/dl1_v0.5.1_LST-1.Run01837.h5 \
		$(OUTDIR)/run01837.hdf5 \
		$(TEL_NAME)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/run01837.hdf5 \
		$(OUTDIR)/run01837_precuts.hdf5
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/run01837_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/run01837_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/run01837_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl



#plot performances (For direct call via '$make <path>')
$(OUTDIR)/regressor_plots.pdf: config/config_energy_lb.yaml $(OUTDIR)/cv_regressor.hdf5 | $(OUTDIR)
	aict_plot_regressor_performance \
		config/config_energy_lb.yaml \
		$(OUTDIR)/cv_regressor.hdf5 \
		$(OUTDIR)/regressor.pkl \
		-o $(OUTDIR)/regressor_plots.pdf

$(OUTDIR)/separator_plots.pdf: config/config_separator_lb.yaml  $(OUTDIR)/cv_separation.hdf5 | $(OUTDIR)
	aict_plot_separator_performance \
		config/config_separator_lb.yaml \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl \
		-o $(OUTDIR)/separator_plots.pdf

$(OUTDIR)/disp_plots.pdf: config/config_source_cta_lb.yaml  $(OUTDIR)/cv_disp.hdf5 $(OUTDIR)/gamma-diffuse_training_precuts.hdf5 | $(OUTDIR)
	aict_plot_disp_performance \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/cv_disp.hdf5 \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl \
		-o $(OUTDIR)/disp_plots.pdf



$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean
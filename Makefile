OUTDIR=build
INDIR=data

GAMMA_FILE_TR=$(INDIR)/dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
GAMMA_FILE_TE=$(INDIR)/dl1_gamma_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
GAMMA_DIFFUSE_FILE_TR=$(INDIR)/dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
GAMMA_DIFFUSE_FILE_TE=$(INDIR)/dl1_gamma-diffuse_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
PROTON_FILE_TR=$(INDIR)/dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_training.h5
PROTON_FILE_TE=$(INDIR)/dl1_proton_south_pointing_20200514_v0.5.1_v01_DL1_testing.h5
KEY=dl1/event/telescope/parameters/LST_LSTCam

all: $(OUTDIR)/cv_separation.hdf5 $(OUTDIR)/cv_disp.hdf5 $(OUTDIR)/cv_regressor.hdf5 
all: $(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 $(OUTDIR)/proton_testing_precuts.hdf5 $(OUTDIR)/gamma_testing_precuts.hdf5

#file convertion
$(OUTDIR)/gamma_training.hdf5: $(GAMMA_FILE_TR) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_FILE_TR)\
		$(OUTDIR)/gamma_training.hdf5 \
		$(KEY)

$(OUTDIR)/gamma_testing.hdf5: $(GAMMA_FILE_TE) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_FILE_TE)\
		$(OUTDIR)/gamma_testing.hdf5 \
		$(KEY)

$(OUTDIR)/gamma-diffuse_training.hdf5: $(GAMMA_DIFFUSE_FILE_TR) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_DIFFUSE_FILE_TR)\
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(KEY)

$(OUTDIR)/gamma-diffuse_testing.hdf5: $(GAMMA_DIFFUSE_FILE_TE) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_DIFFUSE_FILE_TE)\
		$(OUTDIR)/gamma-diffuse_testing.hdf5 \
		$(KEY)

$(OUTDIR)/proton_training.hdf5: $(PROTON_FILE_TR) | $(OUTDIR)
	python file_convert.py \
		$(PROTON_FILE_TR)\
		$(OUTDIR)/proton_training.hdf5 \
		$(KEY)

$(OUTDIR)/proton_testing.hdf5: $(PROTON_FILE_TE) | $(OUTDIR)
	python file_convert.py \
		$(PROTON_FILE_TE)\
		$(OUTDIR)/proton_testing.hdf5 \
		$(KEY)

#precuts
$(OUTDIR)/gamma_training_precuts.hdf5: $(OUTDIR)/gamma_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma_training.hdf5 \
		$(OUTDIR)/gamma_training_precuts.hdf5 

#$(OUTDIR)/gamma_testing_precuts.hdf5: $(OUTDIR)/gamma_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
#	aict_apply_cuts \
#		config/quality_cuts_lb.yaml \
#		$(OUTDIR)/gamma_testing.hdf5 \
#		$(OUTDIR)/gamma_testing_precuts.hdf5 

$(OUTDIR)/gamma-diffuse_training_precuts.hdf5: $(OUTDIR)/gamma-diffuse_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 

#$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5: $(OUTDIR)/gamma-diffuse_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
#	aict_apply_cuts \
#		config/quality_cuts_lb.yaml \
#		$(OUTDIR)/gamma-diffuse_testing.hdf5 \
#		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 

$(OUTDIR)/proton_training_precuts.hdf5: $(OUTDIR)/proton_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/proton_training.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 

#$(OUTDIR)/proton_testing_precuts.hdf5: $(OUTDIR)/proton_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
#	aict_apply_cuts \
#		config/quality_cuts_lb.yaml \
#		$(OUTDIR)/proton_testing.hdf5 \
#		$(OUTDIR)/proton_testing_precuts.hdf5 

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
$(OUTDIR)/gamma_testing_precuts.hdf5: $(OUTDIR)/gamma_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma_testing.hdf5 \
		$(OUTDIR)/gamma_testing_precuts.hdf5 
	aict_apply_energy_regressor \
		config/config_energy_lb.yaml \
		$(OUTDIR)/gamma_testing_precuts.hdf5 \
		$(OUTDIR)/regressor.pkl
	
$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5: $(OUTDIR)/gamma-diffuse_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing.hdf5 \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
		$(OUTDIR)/separator.pkl
	aict_apply_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl

$(OUTDIR)/proton_testing_precuts.hdf5: $(OUTDIR)/proton_testing.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/proton_testing.hdf5 \
		$(OUTDIR)/proton_testing_precuts.hdf5 
	aict_apply_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/proton_testing_precuts.hdf5 \
		$(OUTDIR)/separator.pkl


#$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5: config/config_separator_lb.yaml $(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 $(OUTDIR)/separator.pkl
#	aict_apply_separation_model \
#		config/config_separator_lb.yaml \
#		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
#		$(OUTDIR)/separator.pkl

#$(OUTDIR)/proton_testing_precuts.hdf5: config/config_separator_lb.yaml $(OUTDIR)/proton_testing_precuts.hdf5 $(OUTDIR)/separator.pkl
#	aict_apply_separation_model \
#		config/config_separator_lb.yaml \
#		$(OUTDIR)/proton_testing_precuts.hdf5 \
#		$(OUTDIR)/separator.pkl

#$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5: config/config_source_cta_lb.yaml $(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 $(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl
#	aict_apply_disp_regressor \
#		config/config_source_cta_lb.yaml \
#		$(OUTDIR)/gamma-diffuse_testing_precuts.hdf5 \
#		$(OUTDIR)/disp.pkl \
#		$(OUTDIR)/sign.pkl

#$(OUTDIR)/gamma_testing_precuts.hdf5: config/config_energy_lb.yaml $(OUTDIR)/gamma_testing_precuts.hdf5 $(OUTDIR)/regressor.pkl
#	aict_apply_energy_regressor \
#		config/config_energy_lb.yaml \
#		$(OUTDIR)/gamma_testing_precuts.hdf5 \
#		$(OUTDIR)/regressor.pkl



#Optional/ For direct call via '$make <path>': plot performances
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
		$(OUTDIR)/sign.pkl \
		$(OUTDIR)/disp.pkl \
		-o $(OUTDIR)/disp_plots.pdf


$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean
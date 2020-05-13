OUTDIR=build
INDIR=data

GAMMA_FILE=$(INDIR)/dl1_gamma_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5
GAMMA_DIFFUSE_FILE=$(INDIR)/dl1_gamma-diffuse_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5
PROTON_FILE=$(INDIR)/dl1_proton_south_pointing_20200316_v0.4.5__EG2_DL1_training.h5
KEY=dl1/event/telescope/parameters/LST_LSTCam

all: $(OUTDIR)/cv_separation.hdf5 $(OUTDIR)/cv_disp.hdf5

#file convertion
$(OUTDIR)/gamma_training.hdf5: $(GAMMA_FILE) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_FILE)\
		$(OUTDIR)/gamma_training.hdf5 \
		$(KEY)

$(OUTDIR)/gamma-diffuse_training.hdf5: $(GAMMA_DIFFUSE_FILE) | $(OUTDIR)
	python file_convert.py \
		$(GAMMA_DIFFUSE_FILE)\
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(KEY)

$(OUTDIR)/proton_training.hdf5: $(PROTON_FILE) | $(OUTDIR)
	python file_convert.py \
		$(PROTON_FILE)\
		$(OUTDIR)/proton_training.hdf5 \
		$(KEY)


#precuts
$(OUTDIR)/gamma_training_precuts.hdf5: $(OUTDIR)/gamma_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma_training.hdf5 \
		$(OUTDIR)/gamma_training_precuts.hdf5 

$(OUTDIR)/gamma-diffuse_training_precuts.hdf5: $(OUTDIR)/gamma-diffuse_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training.hdf5 \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 

$(OUTDIR)/proton_training_precuts.hdf5: $(OUTDIR)/proton_training.hdf5 config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(OUTDIR)/proton_training.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 

#train separator
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5: config/config_separator_lb.yaml $(OUTDIR)/proton_training_precuts.hdf5 $(OUTDIR)/gamma-diffuse_training_precuts.hdf5
	aict_train_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl

#train disp 
$(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/cv_disp.hdf5: config/config_source_cta_lb.yaml $(OUTDIR)/gamma-diffuse_training_precuts.hdf5
	aict_train_disp_regressor \
		config/config_source_cta_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/cv_disp.hdf5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean
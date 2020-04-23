OUTDIR=build

GAMMA_FILE=data/gamma_training.hdf5
GAMMA_DIFFUSE_FILE=data/gamma-diffuse_training.hdf5
PROTON_FILE=data/proton_training.hdf5

all: $(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5

#precuts
$(OUTDIR)/gamma_training_precuts.hdf5: $(GAMMA_FILE) config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(GAMMA_FILE) \
		$(OUTDIR)/gamma_training_precuts.hdf5 

$(OUTDIR)/gamma-diffuse_training_precuts.hdf5: $(GAMMA_DIFFUSE_FILE) config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(GAMMA_DIFFUSE_FILE) \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 

$(OUTDIR)/proton_training_precuts.hdf5: $(PROTON_FILE) config/quality_cuts_lb.yaml | $(OUTDIR)
	aict_apply_cuts \
		config/quality_cuts_lb.yaml \
		$(PROTON_FILE) \
		$(OUTDIR)/proton_training_precuts.hdf5 

#train separator
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.hdf5: config/config_separator_lb.yaml $(OUTDIR)/proton_training_precuts.hdf5 $(OUTDIR)/gamma-diffuse_training_precuts.hdf5
	aict_train_separation_model \
		config/config_separator_lb.yaml \
		$(OUTDIR)/gamma-diffuse_training_precuts.hdf5 \
		$(OUTDIR)/proton_training_precuts.hdf5 \
		$(OUTDIR)/cv_separation.hdf5 \
		$(OUTDIR)/separator.pkl

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean
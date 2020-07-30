OUTDIR = build
INDIR = data

GAMMA_FILE = gamma_south_pointing_20200706_v0.5.2_local_DL1
GAMMA_DIFFUSE_FILE = gamma-diffuse_south_pointing_20200706_v0.5.2_local_DL1
PROTON_FILE = proton_south_pointing_20200706_v0.5.2_local_DL1

AICT_CONFIG = config/aict.yaml
CUTS_CONFIG = config/quality_cuts.yaml
TEL_NAME = LST_LSTCam

TeXOptions = -lualatex \
			 -interaction=nonstopmode \
			 -halt-on-error \
			 -output-directory=$(OUTDIR)

all: $(OUTDIR)/cv_separation.h5 \
	$(OUTDIR)/cv_disp.h5 \
	$(OUTDIR)/cv_regressor.h5 \
	$(OUTDIR)/regressor_plots.pdf \
	$(OUTDIR)/disp_plots.pdf \
	$(OUTDIR)/separator_plots.pdf \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01832.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01833.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01834.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01835.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01836.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01837.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01840.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01841.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01842.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01843.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run01844.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02113.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02114.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02115.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02116.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02117.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02130.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02131.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02132.h5 \
	$(OUTDIR)/dl2_v0.5.1_LST-1.Run02133.h5 \
	$(OUTDIR)/dl2_$(GAMMA_FILE)_testing.h5 \
	$(OUTDIR)/dl2_$(GAMMA_DIFFUSE_FILE)_testing.h5 \
	$(OUTDIR)/dl2_$(PROTON_FILE)_testing.h5 \
	$(OUTDIR)/theta2_plot.pdf \
	$(OUTDIR)/mrk421_plot.pdf \
	$(OUTDIR)/thesis.pdf
	

#file convert
$(OUTDIR)/%_aict.h5: $(INDIR)/%.h5 file_convert.py | $(OUTDIR)
	python file_convert.py \
		$< \
		$@ \
		$(TEL_NAME)

#precuts
$(OUTDIR)/%_precuts.h5: $(OUTDIR)/%_aict.h5 $(CUTS_CONFIG) | $(OUTDIR)
	aict_apply_cuts \
		$(CUTS_CONFIG) \
		$< \
		$@

#train models
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.h5: $(CUTS_CONFIG) $(AICT_CONFIG) $(OUTDIR)/dl1_$(PROTON_FILE)_training_precuts.h5 
$(OUTDIR)/separator.pkl $(OUTDIR)/cv_separation.h5: $(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5
	aict_train_separation_model \
		$(AICT_CONFIG) \
		$(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5 \
		$(OUTDIR)/dl1_$(PROTON_FILE)_training_precuts.h5 \
		$(OUTDIR)/cv_separation.h5 \
		$(OUTDIR)/separator.pkl

$(OUTDIR)/disp.pkl $(OUTDIR)/sign.pkl $(OUTDIR)/cv_disp.h5: $(CUTS_CONFIG) $(AICT_CONFIG) $(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5
	aict_train_disp_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5 \
		$(OUTDIR)/cv_disp.h5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl

$(OUTDIR)/regressor.pkl $(OUTDIR)/cv_regressor.h5: $(CUTS_CONFIG) $(AICT_CONFIG) $(OUTDIR)/dl1_$(GAMMA_FILE)_training_precuts.h5
	aict_train_energy_regressor \
		$(AICT_CONFIG) \
		$(OUTDIR)/dl1_$(GAMMA_FILE)_training_precuts.h5 \
		$(OUTDIR)/cv_regressor.h5 \
		$(OUTDIR)/regressor.pkl

#apply models
$(OUTDIR)/%_aict.h5: $(INDIR)/%.h5 file_convert.py
	python file_convert.py $< $@ $(TEL_NAME)

$(OUTDIR)/dl2_%.h5: $(OUTDIR)/dl1_%_aict.h5 $(OUTDIR)/separator.pkl $(OUTDIR)/disp.pkl $(OUTDIR)/regressor.pkl $(AICT_CONFIG) $(CUTS_CONFIG)
	aict_apply_cuts \
		$(CUTS_CONFIG) \
		$< $@ \
		--chunksize=100000
	aict_apply_separation_model \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/separator.pkl \
		--chunksize=100000
	aict_apply_disp_regressor \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl \
		--chunksize=100000
	aict_apply_energy_regressor \
		$(AICT_CONFIG) \
		$@ \
		$(OUTDIR)/regressor.pkl \
		--chunksize=100000

#performance plots
$(OUTDIR)/regressor_plots.pdf: $(AICT_CONFIG) $(OUTDIR)/cv_regressor.h5 | $(OUTDIR)
	aict_plot_regressor_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_regressor.h5 \
		$(OUTDIR)/regressor.pkl \
		-o $@

$(OUTDIR)/separator_plots.pdf: $(AICT_CONFIG) $(OUTDIR)/cv_separation.h5 | $(OUTDIR)
	aict_plot_separator_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_separation.h5 \
		$(OUTDIR)/separator.pkl \
		-o $@

$(OUTDIR)/disp_plots.pdf: $(AICT_CONFIG) $(OUTDIR)/cv_disp.h5 $(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5 | $(OUTDIR)
	aict_plot_disp_performance \
		$(AICT_CONFIG) \
		$(OUTDIR)/cv_disp.h5 \
		$(OUTDIR)/dl1_$(GAMMA_DIFFUSE_FILE)_training_precuts.h5 \
		$(OUTDIR)/disp.pkl \
		$(OUTDIR)/sign.pkl \
		-o $@

#observations
$(OUTDIR)/theta2_plot.pdf: theta2_plot.py plotting.py \
  $(OUTDIR)/dl2_$(GAMMA_DIFFUSE_FILE)_testing.h5 $(OUTDIR)/dl2_$(GAMMA_FILE)_testing.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01832.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run01833.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01834.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run01835.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01836.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run01837.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01840.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run01841.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01842.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run01843.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run01844.h5 | $(OUTDIR)
	python theta2_plot.py \
		$(OUTDIR) \
		$(OUTDIR)/dl2_$(GAMMA_DIFFUSE_FILE)_testing.h5 \
		$(OUTDIR)/dl2_$(GAMMA_FILE)_testing.h5 \
		$(OUTDIR)/theta2_plot.pdf 

$(OUTDIR)/mrk421_plot.pdf: mrk421.py plotting.py $(OUTDIR)/dl2_v0.5.1_LST-1.Run02113.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run02114.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run02115.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run02116.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run02117.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run02130.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run02131.h5 \
  $(OUTDIR)/dl2_v0.5.1_LST-1.Run02132.h5 $(OUTDIR)/dl2_v0.5.1_LST-1.Run02133.h5 | $(OUTDIR)
	python mrk421.py \
		$(OUTDIR) \
		$(OUTDIR)/mrk421_plot.pdf 


#thesis
$(OUTDIR)/thesis.pdf: FORCE | $(OUTDIR)
	latexmk $(TeXOptions) thesis.tex

FORCE:

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)


.PHONY: all clean

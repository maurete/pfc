dep_main = config.m webif.m webif_test.m webif_train.m problem_gen.m \
select_model.m mysvm_train.m mysvm_classify.m mlp_xtrain.m mlp_classify.m \
opt_rsquared.m

# these files will be moved into the private/ subdir of archive
dep_sec = cross_validation.m error_empirical_cv.m error_empirical_deriv.m \
error_empirical.m error_nll_deriv.m error_nll.m error_rmb_csvm.m \
kernel_linear.m kernel_rbf_deriv.m kernel_rbf.m loadset.m \
model_csvm_deriv.m model_csvm.m model_sigmoid_deriv.m model_sigmoid.m \
model_sigmoid_train.m opt_bfgs_simple.m opt_irpropplus.m opt_line_search.m \
opt_rprop.m problem_classify.m scale_data.m scale_sym.m \
select_model_empirical.m select_model_gridsearch.m \
select_model_mlp.m select_model_rmb.m select_model_trivial.m \
stpart.m

dep_sub = jsonlab*/*.* feats/*.m libsvm*/matlab/* \
private/strandsample.m private/stpick.m private/stshuffle.m \
private/balance_dataset.m private/readstr.m private/savestr.m \
private/get_kernel.m private/featset_index.m \
private/time_init.m private/time_tick.m \
private/init_matlabpool.m private/interp.m private/interpolate.m \
private/findorder.m private/grid_insert.m private/insert.m \
private/grid_new.m private/grid_linearize.m private/grid_repack.m \
private/grid_zoom.m private/grid_threshold.m private/grid_nbest.m

compress = zip -r
copy = cp --parents
move = mv
delete = rm -rf
makedir = mkdir -p
changedir = cd

filename = webif.zip
tempdir  = temp

all:	webif

webif:	$(dep_main) $(dep_sec) $(dep_sub)
	$(makedir) $(tempdir)
	$(copy) $(dep_main) $(tempdir)
	$(copy) $(dep_sub) $(tempdir)
	$(makedir) $(tempdir)/private/
	$(copy) $(dep_sec) $(tempdir)/private/
	$(changedir) $(tempdir); $(compress) $(filename) .
	$(move) $(tempdir)/$(filename) .
	$(delete) $(tempdir)

clean:
	$(delete) $(tempdir) $(filename)

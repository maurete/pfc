function validation()

%1. xue
prob_xue = problem_gen('xue');

updated   = problem_gen({'updated',1,0},prob_xue);
crosssp   = problem_gen({'cross-species',1,0},prob_xue);
conserved = problem_gen({'conserved-hairpin',-1,0},prob_xue);

model_xue_rmb = select_model(prob_xue, 8, 'rbf', 'rmb');
model_xue_emp = select_model(prob_xue, 8, 'linear', 'empirical');

res_updated_rmb = problem_classify(updated,model_xue_rmb);
res_crosssp_rmb = problem_classify(crosssp,model_xue_rmb);
res_conserved_rmb = problem_classify(conserved,model_xue_rmb);
res_updated_emp = problem_classify(updated,model_xue_emp)
res_crosssp_emp = problem_classify(crosssp,model_xue_emp);
res_conserved_emp = problem_classify(conserved,model_xue_emp);

fprintf('PROBLEM: XUE FEATSET:8 \n')
fprintf('***************************************\n')
fprintf('test set & method  &   n_elem    &   acc \n')
fprintf(' %s & %s & %d & %6.3f \n','updated','rmb',numel(updated.testlabels), res_updated_rmb.se);
fprintf(' %s & %s & %d & %6.3f \n','crosssp','rmb',numel(crosssp.testlabels), res_crosssp_rmb.se);
fprintf(' %s & %s & %d & %6.3f \n','conserved','rmb',numel(conserved.testlabels), res_conserved_rmb.sp);
fprintf(' %s & %s & %d & %6.3f \n','updated','emp',numel(updated.testlabels), res_updated_emp.se);
fprintf(' %s & %s & %d & %6.3f \n','crosssp','emp',numel(crosssp.testlabels), res_crosssp_emp.se);
fprintf(' %s & %s & %d & %6.3f \n','conserved','emp',numel(conserved.testlabels), res_conserved_emp.sp);
fprintf('***************************************\n')

%2. ng

prob_ng = problem_gen('ng');

ie_nh = problem_gen({'mirbase82-mipred/multi:non-human',1,0},prob_ng);
ie_nc = problem_gen({'functional-ncrna/multi',-1,0},prob_ng);

model_ng_rmb = select_model(prob_ng, 8, 'rbf', 'rmb');
model_ng_emp = select_model(prob_ng, 8, 'linear', 'empirical');

res_ie_nh_rmb = problem_classify(ie_nh,model_ng_rmb);
res_ie_nc_rmb = problem_classify(ie_nc,model_ng_rmb);
res_ie_nh_emp = problem_classify(ie_nh,model_ng_emp);
res_ie_nc_emp = problem_classify(ie_nc,model_ng_emp);

fprintf('PROBLEM: NG FEATSET:8 \n')
fprintf('***************************************\n')
fprintf('test set & method  &   n_elem    &   acc \n')
fprintf(' %s & %s & %d & %6.3f \n','ie_nh','rmb',numel(ie_nh.testlabels), res_ie_nh_rmb.se);
fprintf(' %s & %s & %d & %6.3f \n','ie_nc','rmb',numel(ie_nc.testlabels), res_ie_nc_rmb.sp);
fprintf(' %s & %s & %d & %6.3f \n','ie_nh','emp',numel(ie_nh.testlabels), res_ie_nh_emp.se);
fprintf(' %s & %s & %d & %6.3f \n','ie_nc','emp',numel(ie_nc.testlabels), res_ie_nc_emp.sp);
fprintf('***************************************\n')

%3. batuwita

prob_btw = problem_gen('batuwita');
model_btw_rmb = select_model(prob_btw, 8, 'rbf', 'rmb');
model_btw_emp = select_model(prob_btw, 8, 'linear', 'empirical');

%4. mirbase20

prob_mb20_h_xue = problem_gen({'mirbase20/multi:human',1,0},prob_xue);
prob_mb20_nh_xue = problem_gen({'mirbase20/multi:non-human',1,0},prob_xue);

prob_mb20_h_ng = problem_gen({'mirbase20/multi:human',1,0},prob_ng);
prob_mb20_nh_ng = problem_gen({'mirbase20/multi:non-human',1,0},prob_ng);

prob_mb20_h_btw = problem_gen({'mirbase20/multi:human',1,0},prob_btw);
prob_mb20_nh_btw = problem_gen({'mirbase20/multi:non-human',1,0},prob_btw);

res_mb20_h_xue_rmb = problem_classify(prob_mb20_h_xue,model_xue_rmb);
res_mb20_nh_xue_rmb = problem_classify(prob_mb20_nh_xue,model_xue_rmb);
res_mb20_h_xue_emp = problem_classify(prob_mb20_h_xue,model_xue_emp);
res_mb20_nh_xue_emp = problem_classify(prob_mb20_nh_xue,model_xue_emp);

res_mb20_h_ng_rmb = problem_classify(prob_mb20_h_ng,model_ng_rmb);
res_mb20_nh_ng_rmb = problem_classify(prob_mb20_nh_ng,model_ng_rmb);
res_mb20_h_ng_emp = problem_classify(prob_mb20_h_ng,model_ng_emp);
res_mb20_nh_ng_emp = problem_classify(prob_mb20_nh_ng,model_ng_emp);

res_mb20_h_btw_rmb = problem_classify(prob_mb20_h_btw,model_btw_rmb);
res_mb20_nh_btw_rmb = problem_classify(prob_mb20_nh_btw,model_btw_rmb);
res_mb20_h_btw_emp = problem_classify(prob_mb20_h_btw,model_btw_emp);
res_mb20_nh_btw_emp = problem_classify(prob_mb20_nh_btw,model_btw_emp);

fprintf('PROBLEM: MIRBASE20 FEATSET:8 \n')
fprintf('***************************************\n')
fprintf('species & trained with & method  & n_elem & acc \n')
fprintf(' %s & %s & %s & %d & %6.3f \n','human','xue','rmb', ...
        numel(prob_mb20_h_xue.testlabels), res_mb20_h_xue_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','xue','rmb', ...
        numel(prob_mb20_nh_xue.testlabels), res_mb20_nh_xue_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','human','xue','emp', ...
        numel(prob_mb20_h_xue.testlabels), res_mb20_h_xue_emp.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','xue','emp', ...
        numel(prob_mb20_nh_xue.testlabels), res_mb20_nh_xue_emp.se);

fprintf(' %s & %s & %s & %d & %6.3f \n','human','ng','rmb', ...
        numel(prob_mb20_h_ng.testlabels), res_mb20_h_ng_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','ng','rmb', ...
        numel(prob_mb20_nh_ng.testlabels), res_mb20_nh_ng_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','human','ng','emp', ...
        numel(prob_mb20_h_ng.testlabels), res_mb20_h_ng_emp.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','ng','emp', ...
        numel(prob_mb20_nh_ng.testlabels), res_mb20_nh_ng_emp.se);

fprintf(' %s & %s & %s & %d & %6.3f \n','human','btw','rmb', ...
        numel(prob_mb20_h_btw.testlabels), res_mb20_h_btw_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','btw','rmb', ...
        numel(prob_mb20_nh_btw.testlabels), res_mb20_nh_btw_rmb.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','human','btw','emp', ...
        numel(prob_mb20_h_btw.testlabels), res_mb20_h_btw_emp.se);
fprintf(' %s & %s & %s & %d & %6.3f \n','non-human','btw','emp', ...
        numel(prob_mb20_nh_btw.testlabels), res_mb20_nh_btw_emp.se);
fprintf('***************************************\n')

end
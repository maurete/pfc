function pruebas
  %%
  %%
  %% === SVM ===
  %%
  %%
  [iris_label, iris_inst] = libsvmread ( 'data/iris-svm.data' );
  % valores de c y g obtenidos con svm-easy:
  model = svmtrain ( iris_label, iris_inst, '-c 2048 -g 0.0078125' )
  fflush(stdout);
  [predict_label, accuracy, dec_values] = svmpredict( iris_label, iris_inst, model)
  fflush(stdout);

  %%
  %%
  %%  MLP
  %%
  %%
  printf("mlp 2-2, dataset: separable\n")
  fflush(stdout);
  p=csvread("data/separable.data");
  color = max( rainbow(max(p(:,3)+1))-0.3, 0);
  figure;
  scatter(p(:,1), p(:,2), 20, color(p(:,3).+1,:), "filled");
  title("dataset: separable");
  sleep(1)
  mlp1 = mlp_new( [2 2] );
  [er sd mlp1] = mlp_train_kfold( mlp1, "data/separable.data" );
  figure;
  plot(1:length(er), er, sd);
  title("error (azul) y sd, dataset: separable")
  sleep(1)
  mlp_scan_2d(mlp1);
  sleep(1)

  printf("mlp 2-6-2, dataset: mypattern (concéntrico)\n")
  fflush(stdout);
  p=csvread("data/mypattern.data");
  figure;
  scatter(p(:,1), p(:,2), 20, color(p(:,3).+1,:), "filled");
  title("dataset: concentrico");
  sleep(1)
  mlp2 = mlp_new( [2 6 2] );
  [er sd mlp2] = mlp_train_kfold( mlp2, "data/mypattern.data" );
  figure;
  plot(1:length(er), er, sd);
  title("error, sdev - dataset: concentrico");
  sleep(1)
  mlp_scan_2d(mlp2);
  sleep(1)

  printf("mlp 4-6-3, dataset: iris\n")
  fflush(stdout);
  ## p=csvread("data/iris.data");
  ## figure;
  ## scatter(p(:,1), p(:,2), 20, color(p(:,3).+1,:), "filled");
  ## sleep(1)
  mlp3 = mlp_new( [4 6 3] );
  [er sd mlp3] = mlp_train_kfold( mlp3, "data/iris-num.data" );
  figure;
  plot(1:length(er), er, sd);
  title("error, sdev - dataset: iris");
  sleep(1)
  ## mlp_scan_2d(mlp2);
  ## sleep(1)


endfunction


function [ error stddev mlp ] = mlp_train_kfold ( mlp, file, K=10, err=0.001, rate=0.1, momentum=0.2 )

	 % lectura de los datos
	 data = csvread ( file );
	 
	 % numero de nodos de entrada y salida del mlp
	 ninputs = mlp{1,1}(1);
	 noutputs = mlp{1,1}(end);
	 
	 % valido cantidad de entradas archivo-mlp
	 assert( size(data)(2)-1 <= ninputs, "Hay más entradas que nodos en la capa de entrada" );

	 % las clases deberán ser números consecutivos a partir de 1
	 nclasses = max(data(:,end)); 
	 
	 % valido nro de salidas
	 assert( nclasses <= noutputs, "Hay más clases a representar que salidas en el mlp" );

	 class = eye(noutputs)*2 - 1; % la salida del mlp para la clase n será class(:,n)

	 % partición del conjunto
	 npatterns = size(data)(1);
	 nsubset = ceil(npatterns/K);

	 error = [];
	 stddev = [];

	 % para cada epoca
	 for e=1:1000
	 
	   data = shuffle(data);
	   epoch_err = zeros(size(data)(2),1);
	   
	   printf("epoca: %d\n", e);

	   % para cada particion
	   for k=randperm(K)
	     
	     % voy dejando el k-ésimo subconjunto afuera, mezclo el resto
	     data_part = shuffle(data([1:nsubset*(k-1),nsubset*k+1:npatterns],:));

	     % printf("particion actual: [ 1-%d %d-%d ]\n", nsubset*(k-1) , nsubset*k+1, npatterns )

	     for i=1:size(data_part)(1)
		 ## printf("mlp_backprop( mlp, [ ");
		 ## for d=data_part(i,1:end-1)
		 ##     printf("%f,",d)
		 ## endfor
		 ## printf(" ], [ ");
		 ## for c=class(:,data_part(1,end))
		 ##     printf("%d,",c)
		 ## endfor
		 ## printf(")\n")
		 mlp = mlp_backprop( mlp, data_part(i,1:end-1)', class(:,data_part(i,end)), rate, momentum);
	     endfor

	     % valido con los patrones restantes
	     test_part = data([nsubset*(k-1)+1:min(nsubset*k-1,npatterns)],:);
	     for i=nsubset*(k-1)+1:min(nsubset*k-1,npatterns)
		 epoch_err(i) = sum((class(:,data(i,end)) - mlp_eval(mlp,data(i,1:end-1)')).^2);
	     endfor

	   endfor

	   error = [error mean(epoch_err)/2];
	   stddev = [stddev std(epoch_err)];

	   if e > 2
	   if abs( error(end) - error(end-1) ) < err
	      return;
	   endif
	   endif
	 endfor

endfunction

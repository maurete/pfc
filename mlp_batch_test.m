
function [ output error ] = mlp_batch_test ( mlp, file )

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

	 error = [];
	 output = [];

	 % para cada patron
	 for i=1:npatterns
	 
	   % obtengo la salida del mlp
	   output = [output  mlp_eval(mlp, data(i,1:end-1)') ];

	   error = sum( abs(class(data(i,end)) - output(:,end)) );

	 endfor

endfunction

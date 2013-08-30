%
% mlp_backprop: implementación del algoritmo de back-propagation para un patrón de entrada
% 

function [ mlp output ] = mlp_backprop ( mlp, input, desired, rate=0.1, momentum=0 )

  ## assert( length(desired) == layers(end),
  ## 	  "el tamaño de las salidas esperadas es incorrecto");

  % convierto input y desired en vectores columna
  input = reshape( input, [], 1 );
  desired = reshape( desired, [], 1 );

  [ output mlp ] = mlp_eval( mlp, input );
  % mlp ahora contiene las salidas capa por capa

  layers = mlp{1,1};
  weights = mlp(2,:);
  prevDw = mlp(5,:);
  y = mlp(3,:);
  v = mlp(4,:); %campo local inducido

  N = length(layers);

  error = desired - output;

  lgrad = {};
  Dw = {};
  
  lgrad{N} = error .* (1+y{N}) .* (1-y{N}) ./ 2; % grad local de las neuronas de la capa N
  Dw{N} = ( lgrad{N} * [ y{N-1}; -1]' ) .* rate; % Delta w para la capa N 

  for n = N-1:-1:2 % para cada capa oculta...
    % inicializo el vector gradientes locales para la capa 
    lgrad{n} = (1+y{n}) .* (1-y{n}) ./ 2;
    for j=1:layers(n) % para cada neurona en la capa
	% calculo el gradiente local de esa neurona
	lgrad{n}(j) *= ( weights{n+1}(:,j)' * lgrad{n+1} );
    endfor

    Dw{n} = ( lgrad{n} * [ y{n-1}; -1 ]' ) .* rate + momentum*prevDw{n} ;

  endfor

  for n=2:N
    weights{n} = weights{n} + Dw{n};
  endfor

  mlp(2,:)=weights;
  mlp(5,:)=Dw;

endfunction

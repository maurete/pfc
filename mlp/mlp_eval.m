%
% mlp_eval: obtiene la salida del mlp para la entrada dada
% 

function [ output mlp ] = mlp_eval ( mlp, input )

  layers = mlp{1,1};
  weights = mlp(2,:);

  assert( length(input) == layers(1),
	  "el número de entradas dadas es incorrecto!");

  v = {}; % producto w*inputs
  y = {}; % salida de la capa = fnact(v)

  % convierto input en vector columna y lo guardo como "salida" de la
  % primer capa (la de entrada)
  y{1} = reshape( input, [], 1 );
  v{1} = [];

  % calculo la salida de cada capa
  for n=2:length(layers)
      v{n} = weights{n} * [ y{n-1}; -1 ];
      y{n} = ((exp(-v{n})+1).^-1)*2 - 1;
  endfor

  output = y{end};

  % guardo las salidas intermedias en el mlp
  for k=1:length(y)
    mlp{3,k} = y{k};
    mlp{4,k} = v{k};
  endfor

endfunction

%
% mlp_new: inicializa un nuevo mlp en un cell array
%             * el elemento (1,1) contiene la estructura de las capas
%             * los elementos (2,?) contienen las matrices de pesos para cada capa
% 
function mlp = mlp_new ( layers )

  assert( length(layers) > 1, "debe haber al menos una capa de entrada y una de salida!");
  assert( ! sum(layers <= 0,'native'), "no puede haber capas con menos de un nodo!" );

  mlp = {};

  mlp{1,1} = layers;

  % Para cada capa menos la de entrada, inicializo una matriz de pesos
  % de ( num-neuronas x num-salidas-capa-anterior+bias )
  for n=2:length(layers)
      mlp{2,n} = rand( layers(n), layers(n-1)+1 ) - 0.5;
      mlp{5,n} = zeros( layers(n), layers(n-1)+1 ); % para el término de momento
  endfor

endfunction

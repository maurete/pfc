function [output, deriv] = model_sigmoid(input, args)
    A = args(1);
    B = args(2);
    output = zeros(size(input));
    deriv  = zeros(length(input), length(args));
    for i=1:length(input)
        output(i) = 1/(1+exp(A*input(i)+B));
        e = exp(A*input(i)+B); f = 1/(1+e); d = -f*f*e;
        deriv(i,:) = [ d*input(i), d ];
    end
end
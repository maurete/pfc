function s = strandsample(seed, population, nsamples)

    s = [];
    if nsamples < 1, return, end

    % fix random number generation
    if isempty(ver('octave')), a = rng(seed); % matlab
    else a = rand('state'); rand('seed',seed); % octave
    end

    if isscalar(population)
        % just generate random indexes
        s = randperm(population, nsamples);
    else
        % sample elements from vector population
        l = length(population);
        s = population(randperm(l,nsamples));
    end

    % restore random stream
    if isempty(ver('octave')), rng(a); % matlab
    else rand('state',a); % octave
    end

end

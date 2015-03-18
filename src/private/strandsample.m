function s = strandsample(seed, population, nsamples)
    a = rng(seed);
    s = randsample(population, nsamples);
    rng(a);
end

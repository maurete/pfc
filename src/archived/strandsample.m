function s = strandsample(seed, population, nsamples)
    stream = RandStream('mt19937ar','Seed',seed);
    s = randsample(stream, population, nsamples);
end
function svm_workflow_btw ( )

    % batuwita dataset
    dataset = struct();
    dataset(1).name          = 'mirbase12'; %
    dataset(1).train_species = 'human';
    dataset(1).test_species  = 'none';
    dataset(1).train_ratio   = 0.85; % 660 entries (original=691)
    dataset(1).test_ratio    = 0.15;

    dataset(2).name          = 'coding'; %
    dataset(2).train_species = 'all';
    dataset(2).test_species  = 'none';
    dataset(2).train_ratio   = 0.12; % to keep 2:1 ratio as
                                     % were not using class
                                     % imbalance solving
    dataset(2).test_ratio    = 0.5;

    dataset(3).name          = 'other-ncrna'; % human other ncrna
    dataset(3).train_species = 'all';
    dataset(3).test_species  = 'none';
    dataset(3).train_ratio   = 0.85; % 129 entries (original=754)
    dataset(3).test_ratio    = 0.15;


    % sigma parameter for the RBF kernel
    Z = [1e0 10^0.5 10^0.9 10^0.95 1e1 10^1.05 10^1.1 10^1.15 10^1.2 10^1.5 1e2 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8 1e9]';

    % boxconstraint parameter for the RBF kernel
    C = [1e-3 1e-2 1e-1 10^-0.5 1e0 10^0.5 1e1 10^1.5 10^1.75 1e2 10^2.25 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8];

    % number of workers for the matlabpool
    N = 12;

    % number of iterations
    I = 10;

    svm_workflow_gridsearch (dataset, N, I)

end

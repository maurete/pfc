function svm_workflow_xue ( )

    % xue dataset
    dataset = struct();
    dataset(1).name          = 'mirbase50';
    dataset(1).train_species = 'human';
    dataset(1).test_species  = 'human';
    dataset(1).train_ratio   = 163/193;
    dataset(1).test_ratio    = 30/193;

    dataset(2).name          = 'mirbase50';
    dataset(2).train_species = 'none';
    dataset(2).test_species  = 'non-human';
    dataset(2).train_ratio   = 0;
    dataset(2).test_ratio    = 1;

    dataset(3).name          = 'updated';
    dataset(3).train_species = 'none';
    dataset(3).test_species  = 'human';
    dataset(3).train_ratio   = 0;
    dataset(3).test_ratio    = 1;

    dataset(4).name          = 'coding';
    dataset(4).train_species = 'all';
    dataset(4).test_species  = 'all';
    dataset(4).train_ratio   = 168/8494;
    dataset(4).test_ratio    = 1000/8494;

    dataset(5).name          = 'conserved-hairpin';
    dataset(5).train_species = 'all';
    dataset(5).test_species  = 'all';
    dataset(5).train_ratio   = 0;
    dataset(5).test_ratio    = 1; % long =2444

    % sigma parameter for the RBF kernel
    Z = [1e0 10^0.5 10^0.9 10^0.95 1e1 10^1.05 10^1.1 10^1.15 10^1.2 10^1.5 1e2 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8 1e9]';

    % boxconstraint parameter for the RBF kernel
    C = [1e-3 1e-2 1e-1 10^-0.5 1e0 10^0.5 1e1 10^1.5 10^1.75 1e2 10^2.25 10^2.5 1e3 1e4 1e5 1e6 1e7 1e8];

    % number of workers for the matlabpool
    N = 12;

    % number of iterations
    I = 10;

    %svm_workflow_rbf (dataset, C, Z, N, I)
    svm_workflow_gridsearch (dataset, N, I)

end

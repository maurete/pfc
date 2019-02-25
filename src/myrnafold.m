function [structure,mfe,status] = myrnafold(sequence)
%MYRNAFOLD Fold (find secondary structure of) given SEQUENCE.
%
%   [STRUCTURE,MFE] = MYRNAFOLD(SEQUENCE) tries to obtain MFE secondary
%     structure for given RNA sequence by first invoking ViennaRNA's
%     RNAFold command, and if that fails, by invoking Bioinformatics
%     Toolbox's rnafold() function.
%     SEQUENCE is the RNA sequence for which secondary structure
%     information should be obtained.
%     STRUCTURE is the resulting secondary structure string in dot-
%     bracket notation.
%     MFE is the resulting minimum free energy.
%     STATUS = 0 means external RNAfold command was invoked.
%
%   See also RNAFOLD

    try,config;end % Load global settings

    % RNAFold output secondary structure RE
    structure_fmt = '^\s*([.()]+)\s+\(([-0-9.]+)\)\s*$';

    structure = [];
    mfe = [];

    if exist('RNAFOLD_EXT_CMD','var')
        % First try invoking external RNAfold command
        [status,output] = system([RNAFOLD_EXT_CMD,' <<< ',sequence]);
        % Check command status
        if status == 0
            % Read lines from output strings
            lines = strread(output,'%s','delimiter','\n');
            % Capture groups from RE
            groups = regexp(lines{2},structure_fmt, 'tokens');
            % Save secondary structure
            structure = groups{1}{1};
            if length(groups{1}) > 1,
                % Save minimum free energy
                mfe = sscanf(groups{1}{2},'%f');
            end
            return
        end
    end

    % As a fallback use matlab's rnafold
    [structure,mfe] = rnafold(sequence);

end

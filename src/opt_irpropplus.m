classdef opt_irpropplus < handle
%opt_irpropplus Improved Rprop+ optimizer class.
%
% This class is a Matlab reimplementation of that found in the Shark toolkit by
% C. Igel et al., http://shark-project.sourceforge.net
%
% Details about the IRProp+ algorithm can be found in the original publication
% "Improving the Rprop Learning Algorithm" by C. Igel and M. Hüsken (2000)
%

    properties
        np     = 1.2;
        nm     = 0.5;
        dmax   = inf;
        dmin   = 0;
        delta0 = 0.01;
        delta;
        deltaw;
        olderr;
        olderrderiv;
    end

    methods

        function obj = opt_irpropplus( modelarg, np, nm, dmax, dmin, delta0 )
        % OPT_IRPROPPLUS Constructor function
        %
        %  OBJ = OPT_IRPROPPLUS(MODELARG,NP,NM,DMAX,DMIN,DELTA0)
        %  Initializes the optimizer. MODELARG is a row vector containing dummy
        %  model parameters for constructing the delta vector. NP is the
        %  increase factor, NM the decrease factor, DMAX the upper limit of the
        %  increments, DMIN the lower limit, and DELTA0 the initial value for
        %  the delta parameter.
        %

            if nargin > 1 && ~isempty(np),         obj.np = np;     end
            if nargin > 2 && ~isempty(nm),         obj.nm = nm;     end
            if nargin > 3 && ~isempty(dmax),     obj.dmax = dmax;   end
            if nargin > 4 && ~isempty(dmin),     obj.dmin = dmin;   end
            if nargin > 5 && ~isempty(delta0), obj.delta0 = delta0; end

            obj.delta       = obj.delta0 .* ones(size(modelarg));
            obj.deltaw      = zeros(size(modelarg));
            obj.olderr      = inf;
            obj.olderrderiv = zeros(size(modelarg));

        end

        function [oarg, oerr] = optimize(obj, model, modelderiv, modelarg, ...
                                         errorfunc, errorderiv, input, ...
                                         target, modelisfeasible)
            %OPTIMIZE perform one optimization step
            %  [OARG,OERR] = OPTIMIZE(OBJ, MODEL, MODELDERIV, MODELARG, ...
            %      ERRORFUNC, ERRORDERIV, INPUT, TARGET, MODELISFEASIBLE)
            %  Runs one iteration of the optimization process. MODEL is the
            %  function to be optimized, MODELDERIV its derivative, MODELARG
            %  is the current parameter vector for the MODEL, ERRORFUNC the
            %  error function, ERRORDERIV its derivative, INPUT are the model
            %  inputs, TARGET its respective targets, and MODELISFEASIBLE is a
            %  handle to a function which receives model arguments as input and
            %  returns a boolean telling wether model parameters are in the
            %  allowed range.
            %  Output OARG are the new parameters found and OERR the value
            %  returned by the error function.
            %

            if nargin < 9, modelisfeasible = []; end

            % Compute current error and its derivative
            if isa(errorderiv,'function_handle')
                cerr      =  errorfunc(model,        [],modelarg,input,target);
                cerrderiv = errorderiv(model,modelderiv,modelarg,input,target);
            else
                [cerr,cerrderiv] = errorfunc(model, modelderiv, modelarg, ...
                                             input, target);
            end

            oarg = modelarg;
            oerr = nan;

            % Loop for each dimension
            for i=1:length(modelarg)

                % The IRProp+ logic
                if cerrderiv(i) * obj.olderrderiv(i) > 0
                    obj.delta(i) = min(obj.dmax, obj.np*obj.delta(i));
                    obj.deltaw(i) = obj.delta(i) * ( - sign(cerrderiv(i)) );
                    oarg(i) = oarg(i) + obj.deltaw(i);
                    obj.olderrderiv(i) = cerrderiv(i);

                elseif cerrderiv(i) * obj.olderrderiv(i) < 0
                    obj.delta(i) = max(obj.dmin, obj.nm*obj.delta(i));
                    if obj.olderr < cerr, oarg(i) = oarg(i) - obj.deltaw(i); end
                    obj.olderrderiv(i) = 0;

                else
                    obj.deltaw(i) = obj.delta(i) * ( - sign(cerrderiv(i)) );
                    oarg(i) = oarg(i) + obj.deltaw(i);
                    obj.olderrderiv(i) = cerrderiv(i);
               end

               % Reset output parameters if found parameters are invalid,
               % and scale down delta parameter
               if isa(modelisfeasible,'function_handle') && ...
                       ~ modelisfeasible(oarg)
                   oarg(i) = modelarg(i);
                   obj.delta(i) = obj.delta(i) * obj.nm;
                   obj.olderrderiv(i) = 0;
               end
            end

            oerr = cerr;

        end

        function out = maxdelta(obj)
        % MAXDELTA return maximum value of the internal delta parameter
        %

            out = max(obj.delta);

        end
    end

end

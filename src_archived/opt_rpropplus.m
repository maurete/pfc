classdef opt_rpropplus < handle

    properties
        np     = 1.2;
        nm     = 0.5;
        dmax   = inf;
        dmin   = 0;
        delta;
        deltaw;
        %olderr;
        olderrderiv;
    end

    methods

        function obj = opt_rpropplus( modelarg, np, nm, dmax, dmin, delta0, varargin )

            if nargin > 1 && ~isempty(np),     obj.np = np;   end
            if nargin > 2 && ~isempty(nm),     obj.nm = nm;   end
            if nargin > 3 && ~isempty(dmax), obj.dmax = dmax; end
            if nargin > 4 && ~isempty(dmin), obj.dmin = dmin; end
            if nargin < 6,                     delta0 = 0.01; end

            obj.delta       = delta0 .* ones(size(modelarg));
            obj.deltaw      = zeros(size(modelarg));
            obj.olderrderiv = zeros(size(modelarg));
            %obj.olderr      = inf;

        end

        function [oarg, oerr] = optimize(obj, model, modelderiv, modelarg, ...
                                         errorfunc, errorderiv, ...
                                         input, target, modelisfeasible)
            if nargin < 9, modelisfeasible = []; end

            if isa(errorderiv,'function_handle')
                cerr      =  errorfunc(model, modelarg, input, target);
                cerrderiv = errorderiv(model, modelderiv, modelarg, input, target);
            else
                [cerr cerrderiv] = errorfunc(model, modelderiv, modelarg, input, target);
            end

            oarg = modelarg;
            oerr = nan;

            for i=1:length(modelarg)

                if cerrderiv(i) * obj.olderrderiv(i) > 0
                    %fprintf('cerrderiv*olderrdeirv > 0\n')
                    obj.delta(i) = min(obj.dmax, obj.np*obj.delta(i));
                    obj.deltaw(i) = obj.delta(i) * ( - sign(cerrderiv(i)) );
                    oarg(i) = oarg(i) + obj.deltaw(i);
                    obj.olderrderiv(i) = cerrderiv(i);

                elseif cerrderiv(i) * obj.olderrderiv(i) < 0
                    %fprintf('cerrderiv*olderrdeirv < 0\n')
                    obj.delta(i) = max(obj.dmin, obj.nm*obj.delta(i));
                    oarg(i) = oarg(i) - obj.deltaw(i);
                    obj.olderrderiv(i) = 0;

                else
                    %fprintf('cerrderiv*olderrdeirv == 0\n')
                    obj.deltaw(i) = obj.delta(i) * ( - sign(cerrderiv(i)) );
                    oarg(i) = oarg(i) + obj.deltaw(i);
                    obj.olderrderiv(i) = cerrderiv(i);
               end

               if isa(modelisfeasible,'function_handle') && ...
                       ~ modelisfeasible(oarg)
                   fprintf('model not feasible\n')
                   oarg(i) = modelarg(i);
                   obj.delta(i) = obj.delta(i) * obj.nm;
                   obj.olderrderiv(i) = 0;
               end
            end

            oerr = cerr;
        end

        function out = maxdelta(obj)
            out = max(obj.delta);
        end

    end %methods
end %classdef
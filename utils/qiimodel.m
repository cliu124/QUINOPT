function varargout = qiimodel(varargin)

%% QIIMODEL.m Set model for quadratic integral inequality constraint (internal use)
%
% QIIMODEL sets persistent structures containing all information about the
% integral inequalities defined by the user. Use as follows:
%
% QIIMODEL('indvar',x,a,b) sets up the independent variable of integration x
%       with domain [a,b]. Independent variables are stored in the vector
%       INDVARMODEL.IVARS, while the domain is stored as a row of the matrix
%       INDVARMODELS.DOMAIN.
%
% QIIMODEL('setindvardomain',x,a,b) changes the domain of an existing variable
%       x to [a,b]. An error is thrown if x is not an existing dependent
%       variable. The best way to change the domain of an indvar object is
%       via the function setDomain rather than a direct call to QIIMODEL.
%
% QIIMODEL('depvar',x,K) sets up the dependent variable U(x), its
%       derivatives up to order K, and all the corresponding boundary values.
%       The dependent variables are stored in the vector DEPVARMODEL.DVAR,
%       the boundary values are stored in the vector DEPVARMODEL.BVAL, the
%       independent variables are stored in DEPVARMODEL.IVARS and the
%       maximum derivative orders are stored in DEPVARMODEL.MAXDER.
%       Each basic dependent variable (zeroth derivative) is assigned a
%       unique integer identifier; these are stored in DEPVARMODEL.DVARID.
%       Finally, DEPVARMODEL.DVARPART and DEPVARMODEL.BVALPART contain the
%       indices of last element of DEPVARMODEL.DERORD and DEPVARMODEL.BVAL,
%       respectively, that refers to each unique DVARID. This information
%       is used for dynamic definition of derivative variables.
%
% QIIMODEL('depvar',x,[K1,...,Kn]) sets up n dependent variables U1(x), ...,
%       Un(x), their derivatives and their boundary values.
%
% QIIMODEL('adddepvarderivative',DVARID,K) adds internal variables to model
%       the derivatives up to order K of an existing dependent variable
%       with identified DVARID. The internal model DEPVARMODEL is updated
%       accordingly.
%
% QIIMODEL('cleardepvar',DVARID) removes the dependent variable with
%       identifier DVARID from the internal model.
%
% QIIMODEL('clearindvar',IVARID) removes the independent variable with
%       identifier IVARID from the internal model, together with all the
%       dependent variables that depend on it.
%
% MODEL = QIIMODEL('querymodel') returs the internal model for the
%       inequality as a structure with fields MODEL.INDVARMODEL and
%       MODEL.DEPVARMODEL.
%
% QIIMODEL('clear') clears the internal model.
%
% See also INDVAR, DEPVAR, YALMIP, CLEARMODEL

% ----------------------------------------------------------------------- %
%        Author:    Giovanni Fantuzzi
%                   Department of Aeronautics
%                   Imperial College London
%       Created:    05/05/2016
% Last Modified:    05/05/2016
% ----------------------------------------------------------------------- %

% ----------------------------------------------------------------------- %
% Declare persistent variables
% ----------------------------------------------------------------------- %
persistent INDVARMODEL DEPVARMODEL MAXDVARID
if isempty(MAXDVARID)
    MAXDVARID = 0; 
end

% ----------------------------------------------------------------------- %
% Check first input
% ----------------------------------------------------------------------- %
if ~ischar(varargin{1})
    error('Input flag must be a valid string.')
end

% ----------------------------------------------------------------------- %
% Operate on model
% ----------------------------------------------------------------------- %
if any(strcmpi(varargin{1},{'querymodel','query','recover'}))
    varargout{1}.INDVARMODEL = INDVARMODEL;
    varargout{1}.DEPVARMODEL = DEPVARMODEL;
    varargout{1}.MAXDVARID   = MAXDVARID;
    
elseif strcmpi(varargin{1},'clear')
    INDVARMODEL = [];
    DEPVARMODEL = [];
    MAXDVARID   = 0;
    
elseif strcmpi(varargin{1},'indvar')
    % Update list of independent variable identifiers
    if isempty(INDVARMODEL)
        INDVARMODEL.IVARS = (varargin{2});
        INDVARMODEL.IVARID = depends(varargin{2});
        INDVARMODEL.DOMAIN = sort([varargin{3},varargin{4}]);
    else
        INDVARMODEL.IVARS(end+1,1) = (varargin{2});
        INDVARMODEL.IVARID(end+1,1) = depends(varargin{2});
        INDVARMODEL.DOMAIN(end+1,:) = sort([varargin{3},varargin{4}]);
    end
    
elseif strcmpi(varargin{1},'setindvardomain')
    if ~isempty(INDVARMODEL)
        % Update domain of indvar
        i = ismember(INDVARMODEL.IVARID,depends(varargin{2}));
        if any(i)
            INDVARMODEL.DOMAIN(i,:) = sort([varargin{3},varargin{4}],2);
        else
            error('Cannot change the domain of an inexistent independent variable.')
        end
    else
        error('You need to define an independent variable before changing its domain.')
    end
    
elseif strcmpi(varargin{1},'depvar')
    if ~isempty(INDVARMODEL)
        % Define dependent variables
        IVAR = sdpvar(varargin{2});          % convert to sdpvar
        MAXDER = [varargin{3:end}];          % Max derivative of variable
        ndvars = length(MAXDER);             % Number of basic variables
        DVAR = dvarpoly(sum(MAXDER+1),1);    % Dependent variables & derivatives
        BVAL = dvarpoly(2*sum(MAXDER+1),1);  % Boundary values
        if isempty(DEPVARMODEL)
            DVARID = MAXDVARID+(1:ndvars);
            MAXDVARID = max(DVARID);
            DEPVARMODEL.DVARID = DVARID;
            DEPVARMODEL.IVAR = IVAR*ones(1,ndvars);
            DEPVARMODEL.MAXDER = MAXDER;
            DEPVARMODEL.DVAR = DVAR;
            DEPVARMODEL.BVAL = BVAL;
            DEPVARMODEL.DVARPART = [0, cumsum(MAXDER+1)];
            DEPVARMODEL.BVALPART = [0, 2*cumsum(MAXDER+1)];
            DEPVARMODEL.SYMMETRY = 0;                       % no symmetry by default
        else
            % DVARID = DEPVARMODEL.DVARID(end)+(1:ndvars);
            DVARID = MAXDVARID+(1:ndvars);
            MAXDVARID = max(DVARID);
            DEPVARMODEL.DVARID = [DEPVARMODEL.DVARID, DVARID];
            DEPVARMODEL.IVAR = [DEPVARMODEL.IVAR, IVAR*ones(1,ndvars)];
            DEPVARMODEL.MAXDER = [DEPVARMODEL.MAXDER, MAXDER];
            DEPVARMODEL.DVAR = [DEPVARMODEL.DVAR; DVAR];
            DEPVARMODEL.BVAL = [DEPVARMODEL.BVAL; BVAL];
            DEPVARMODEL.DVARPART = [0, cumsum(DEPVARMODEL.MAXDER+1)];
            DEPVARMODEL.BVALPART = [0, 2*cumsum(DEPVARMODEL.MAXDER+1)];
            DEPVARMODEL.SYMMETRY = [DEPVARMODEL.SYMMETRY, 0]; % no symmetry by default
        end
        varargout{1} = DVARID;
        
    else
        error('You need to define an independent variable before defining dependent variables.')
        
    end
    
elseif strcmpi(varargin{1},'adddepvarderivative')
    % Add derivatives up to specified order
    DVARID = varargin{2};
    K = varargin{3};
    varIndex = find(DEPVARMODEL.DVARID==DVARID);
    
    if isempty(varIndex)
        error('The specified dependent variable identifier does not exist.')
    elseif K<=DEPVARMODEL.MAXDER(varIndex)
        % nothing to do!
        return
    else
        OLDDER = DEPVARMODEL.MAXDER(varIndex); % highest order of existing derivatives
        DVAR = dvarpoly(K-OLDDER,1);           % New dependent variables & derivatives
        BVAL = dvarpoly(2*(K-OLDDER),1);       % New boundary values
        I = DEPVARMODEL.DVARPART(varIndex+1);
        J = DEPVARMODEL.BVALPART(varIndex+1);
        DEPVARMODEL.DVAR = [DEPVARMODEL.DVAR(1:I); DVAR; DEPVARMODEL.DVAR(I+1:end)];
        DEPVARMODEL.BVAL = [DEPVARMODEL.BVAL(1:J); BVAL; DEPVARMODEL.BVAL(J+1:end)];
        DEPVARMODEL.MAXDER(varIndex) = K;
        DEPVARMODEL.DVARPART = [0, cumsum(DEPVARMODEL.MAXDER+1)];
        DEPVARMODEL.BVALPART = [0, 2*cumsum(DEPVARMODEL.MAXDER+1)];
    end

elseif strcmpi(varargin{1},'adddepvarsymmetry')
    % Add assumption on symmetry about midpoint of the interval:
    % 0: no symmetry (default upon creation of depvars)
    % 1: odd
    % 2: even
    DVARID = varargin{2};
    varIndex = find(DEPVARMODEL.DVARID==DVARID);
    
    % Get symmetry code
    if isempty(varIndex)
        error('The specified dependent variable identifier does not exist.')
    elseif strcmpi(varargin{3},'none')
        DEPVARMODEL.SYMMETRY(varIndex) = 0;
    elseif strcmpi(varargin{3},'odd')
        DEPVARMODEL.SYMMETRY(varIndex) = 1;
    elseif strcmpi(varargin{3},'even')
        DEPVARMODEL.SYMMETRY(varIndex) = 2;
    else
        error('Unknown symmetry: allowed values are ''none'', ''odd'' or ''even''.')
    end
    
    
elseif strcmpi(varargin{1},'cleardepvar')
    % Are there more than one variable in the model?
    if length(DEPVARMODEL.DVARID)>1
        varIndex = find(DEPVARMODEL.DVARID==varargin{2});
        if ~isempty(varIndex)
            Il = DEPVARMODEL.DVARPART(varIndex);    % last variable before those to remove
            Iu = DEPVARMODEL.DVARPART(varIndex+1);  % last variable to remove
            Jl = DEPVARMODEL.BVALPART(varIndex);
            Ju = DEPVARMODEL.BVALPART(varIndex+1);
            DEPVARMODEL.DVARID = DEPVARMODEL.DVARID([1:varIndex-1,varIndex+1:end]);
            DEPVARMODEL.IVAR = DEPVARMODEL.IVAR([1:varIndex-1,varIndex+1:end]);
            DEPVARMODEL.MAXDER = DEPVARMODEL.MAXDER([1:varIndex-1,varIndex+1:end]);
            DEPVARMODEL.DVAR = DEPVARMODEL.DVAR([1:Il,Iu+1:end]);
            DEPVARMODEL.BVAL = DEPVARMODEL.BVAL([1:Jl,Ju+1:end]);
            DEPVARMODEL.DVARPART = [0, cumsum(DEPVARMODEL.MAXDER+1)];
            DEPVARMODEL.BVALPART = [0, 2*cumsum(DEPVARMODEL.MAXDER+1)];
        end
    % Does it exist or has it been already cleared by class destructors?
    elseif DEPVARMODEL.DVARID==varargin{2}
        DEPVARMODEL = [];
    end
    
elseif strcmpi(varargin{1},'clearindvar')
    if length(INDVARMODEL.IVARID)>1
        varIndex = find(INDVARMODEL.IVARID==varargin{2});
        INDVARMODEL.IVARID = INDVARMODEL.IVARID([1:varIndex-1,varIndex+1:end]);
        INDVARMODEL.IVARS = INDVARMODEL.IVARS([1:varIndex-1,varIndex+1:end]);
        INDVARMODEL.DOMAIN = INDVARMODEL.DOMAIN([1:varIndex-1,varIndex+1:end],:);
    else
        INDVARMODEL = [];
    end
    
end

% ----------------------------------------------------------------------- %
% END CODE
end
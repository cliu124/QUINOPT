function X = legendreTripleProduct(lVals,nMin,nMax,mMin,mMax)

%% LEGENDRETRIPLEPRODUCT.m Integral of product of 3 Legendre polynomials 
%
% X = LEGENDRETRIPLEPRODUCT(lVals,nMin,nMax,mMin,mMax) computes the integral
%       of product of legendre polynomials L_l(x)*L_n(x)*L_m(x) for each 
%       value of l specified in lVals and for all n's and m's within the
%       bounds specified by nMin, nMax, mMin, mMax.
%
% Output: a cell array of dimension length(lVals)-by-1, where each entry
% corresponds to each value in lVals and contains an (nMax-nMin+1)-by-(mMax-mMin+1)
% matrix whose entry (n,m) represents the integral of L_l(x)*L_n(x)*L_m(x).

% ----------------------------------------------------------------------- %
%        Author:    Giovanni Fantuzzi
%                   Department of Aeronautics
%                   Imperial College London
%       Created:    18/02/2015
% Last Modified:    05/05/2016
% ----------------------------------------------------------------------- %

% Some parameters
mVals = mMin:mMax;              % range of values m
nVals = nMin:nMax;              % range of values n
numlVals = length(lVals);       % number of values l
X = cell(numlVals,1);           % initialise output
rows = length(nVals);           % rows in each matrix X{l}
cols = length(mVals);           % cols in each matrix X{l}

% Rescaling matrix (use outer product to build)
S =  ( sqrt(2*nVals(:)+1)*sqrt(2*mVals+1) ) ./2;

% Loop
for k = 1:numlVals
    
    l = lVals(k);
    
    % Loop over matrix entries
    Xtemp = zeros(rows,cols);
    
    for j = 1:cols
        
        m = mVals(j);
        
        % Find values of n for which intergral is nonzero
        rr = rem(l+m+nVals,2);
        idx = find( (rr==0)&(l+nVals-m>=0)&(l+m-nVals>=0)&(nVals+m-l>=0) );
        
        if ~isempty(idx)
            % Setup Xtemp(n,m) for current m and first suitable value of nVals
            n = nVals(idx(1));
            Itemp = I_lmn(l,m,n);
            Xtemp(idx(1),j) = 2*Itemp/(1+l+m+n);
            
            % increase n in steps of 2 until maximum n
            nEnd = nVals(idx(end)) ;
            it = 1;
            while n < nEnd-1
                n = n+2;
                it = it+1;
                % set factors for update - UGLY CODE!
                f1 = (l+m+n-1)/(l+m+n+1);
                if l+m-n+1 > 0
                    f2 = (l+m-n+2)/(l+m-n+1);
                else
                    f2 = 1;
                end
                if l+n-m > 0 
                    f3 = (l+n-m-1)/(l+n-m);
                else
                    f3 = 1;
                end
                if m+n-l > 0
                    f4 = (m+n-l-1)/(m+n-l);
                else
                    f4=1;
                end
                if l+m+n-1 > 0
                    f5 = (l+m+n)/(l+m+n-1);
                else
                    f5 = 1;
                end
                % update
                Xtemp(idx(it),j) = f1*f2*f3*f4*f5*Xtemp(idx(it)-2,j);
            end
            
        end
    end
    
    % Rescale --- ugly code, in principle set rescaled products 
    % to start with!
    Xtemp = (sparse(Xtemp)).*S;
    
    % Assign sparse output
    X{k} = Xtemp;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function I = I_lmn(l,m,n)
        
        % Compute the large factorial products to then find the integral of
        % the triple products.
        
        v1num = l+m-n-1:-2:1;
        v1den = l+m-n:-2:2;     % L+M-N is even
        
        v2num = l+n-m-1:-2:1;
        v2den = l+n-m:-2:2;     % L+N-M is even
        
        v3num = m+n-l-1:-2:1;
        v3den = m+n-l:-2:2;     % M+N-L is even
        
        v4num = m+n+l:-2:2;     % L+M+N is even
        v4den = m+n+l-1:-2:1;
        
        
        % Note for empty matrices: if L+M-N==0, v1num and v1den
        % are empty and v1num./v1den is also empty. The prod([])=1,
        % which is correct ( corresponds to factorial(0) )
        
        I = prod(v1num./v1den)*prod(v2num./v2den)...
                        *prod(v3num./v3den)*prod(v4num./v4den);
            %prod([v1num,v2num,v3num,v4num]./[v1den,v2den,v3den,v4den]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
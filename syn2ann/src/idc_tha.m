%% *Acceleration Time Integration*
% _Editor: Filippo Gatti
% CentraleSupélec - Laboratoire MSSMat
% DICA - Politecnico di Milano
% Copyright 2014-15_
%% NOTES
% _idc_tha_: function that integrates and differentiate acceleration
% signal
%% INPUT:
% * dtm (sampling time step)
% * tha (BP filtered input signal)
% * bfb (Butterworth's filter b coefficient)
% * bfa (Butterworth's filter a coefficient)
%% OUTPUT:
% * tha (acceleration time-history vector (after differentiation))
% * thv (velocity time-history vector (after differentiation))
% * thd (displacement time-history vector (after differentiation))

function [varargout] = idc_tha(varargin)
    %% *SET-UP*
    % time-step
    dtm = varargin{1};
    % accelerogram
    tha = varargin{2}(:);
    flag=false;
    if nargin>2
        bfb = varargin{3};
        bfa = varargin{4};
        flag = true;
    end

    if flag
        %% *CORRECTED ACCELERATION TIME INTEGRATION*
        disp('--->IDC_THA: CORRECTING VELOCITY')
        % velocity
        thv = cumtrapz(tha)*dtm;
        %
        % _velocity base-line correction_
        %
        thv = detrend(thv);
        %
        % _velocity acausal Butterworth filtering_
        %
        thv = filtfilt(bfb,bfa,thv);
        
        %% *CORRECTED VELOCITY TIME INTEGRATION*
        disp('--->IDC_THA: CORRECTING DISPLACEMENT')
        % displacement
        thd = cumtrapz(thv)*dtm;
        %
        % _displacement base-line correction_
        %
        thd = detrend(thd);
        %
        % _displacement cosinus tapering_
        %
        thd = cos_taper(thd);
        % EQUIVALENT: thd = taper_fun(thd,2.5,1,1);
        %
        % _displacement acasual filtering_
        %
        thd = filtfilt(bfb,bfa,thd);
        
        %% *FINAL ACC/VEL/DIS*
        disp('--->IDC_THA: BACK TO ACCELERATION')
        % velocity 
        thv = avd_diff(dtm,thd);
        % acceleration
        tha = avd_diff(dtm,thv);
        % velocity
        thv = cumtrapz(tha)*dtm;
        % displacement
        thd = cumtrapz(thv)*dtm;
    else
        %% *ACCELERATION TIME INTEGRATION*
        disp('--->IDC_THA: UNCORRECTED TIME INTEGRATION')
        % velocity
        thv = cumtrapz(tha)*dtm;
        % displacement
        thd = cumtrapz(thv)*dtm;
    end
    
    %% *OUTPUT*
    varargout{1} = tha(:);
    varargout{2} = thv(:);
    varargout{3} = thd(:);
    return
end

% *Compute response spectra*
% _Editor: Filippo Gatti
% CentraleSupélec - Laboratoire MSSMat
% DICA - Politecnico di Milano
% Copyright 2016_
%% NOTES
% _lfhf_pad_: function that pads the lf and hf records and compute
% arias intensity and T5% for lf and hf records to align hf to lf
%% INPUT:
% * _nss(low frequency records)_
% * _sps(high frequency records)_
%% OUTPUT:
% * _nss(low frequency records)_
% * _sps(high frequency records)_
function [varargout] = lfhf_pad(varargin)
    %% SET-UP
    nss = varargin{1};
    sps = varargin{2};
    tpad = 0;
    for i_ = 1:nss.mon.na
        %% PAD DEFINITION
        npad_lf = round(tpad/nss.mon.dtm(i_));
        npad_hf = round(tpad/sps.mon.dtm(i_));
        npad_lf = nss.mon.ntm(i_)+npad_lf;
        npad_hf = sps.mon.ntm(i_)+npad_hf;
        npad = max([npad_lf,npad_hf]);
        %% PADDING RECORDS
        for j_ = 1:nss.mon.nc
            % tapering
            nss.syn{i_}.tha.(nss.mon.cp{j_}) = ...
                taper_fun(nss.syn{i_}.tha.(nss.mon.cp{j_}),5,0,1); 
            
            % _padding low-frequency_
            nss.syn{i_}.tha.(nss.mon.cp{j_}) = ...
                padarray(nss.syn{i_}.tha.(nss.mon.cp{j_}),...
                npad-nss.mon.ntm(i_),0,'post');
            
            % _padding high-frequency_
            sps.syn{i_}.tha.(sps.mon.cp{j_}) = ...
                padarray(sps.syn{i_}.tha.(sps.mon.cp{j_}),...
                npad-sps.mon.ntm(i_),0,'post');
        end
        % _update time vector_
        nss.mon.ntm(i_) = npad;
        sps.mon.ntm(i_) = npad;
        nss.mon.vtm(i_) = {nss.mon.dtm(i_)*(0:nss.mon.ntm(i_)-1)'};
        sps.mon.vtm(i_) = {sps.mon.dtm(i_)*(0:sps.mon.ntm(i_)-1)'};
    end
    %% OUTPUT
    varargout{1} = nss;
    varargout{2} = sps;
    return
end
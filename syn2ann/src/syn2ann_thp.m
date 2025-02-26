%% *Process time-histories*
% _Editor: Filippo Gatti
% CentraleSupélec - Laboratoire MSSMat
% DICA - Politecnico di Milano
% Copyright 2016_
%% NOTES
% _syn2ann_thp_: function to process time-histories
%% INPUT:
% * _sas (syn2ann structure)_
%% OUTPUT:
% * _sas (syn2ann structure)_
%% N.B.
% Need for _PGAVD_eval.m_, _arias_intensity.m_
function [varargout] = syn2ann_thp(varargin)
    %% *SET-UP*
    sas = varargin{1};
    for i_ = 1:sas.mon.na
        for j_ = 1:sas.mon.nc
            %% *ARIAS INTENSITY*
            [sas.syn{i_}.AT5.(sas.mon.cp{j_}),....
                sas.syn{i_}.AI5.(sas.mon.cp{j_}),...
                sas.syn{i_}.Ain.(sas.mon.cp{j_})] = ...
                arias_intensity(sas.syn{i_}.tha.(sas.mon.cp{j_}),...
                sas.mon.dtm(i_));
            %% *PGA-PGV-PGD*
            [sas.syn{i_}.pga.(sas.mon.cp{j_})(1),...
                sas.syn{i_}.pga.(sas.mon.cp{j_})(2),...
                sas.syn{i_}.pgv.(sas.mon.cp{j_})(1),...
                sas.syn{i_}.pgv.(sas.mon.cp{j_})(2),...
                sas.syn{i_}.pgd.(sas.mon.cp{j_})(1),...
                sas.syn{i_}.pgd.(sas.mon.cp{j_})(2)] = ...
                PGAVD_eval(sas.mon.dtm(i_),...
                sas.syn{i_}.tha.(sas.mon.cp{j_}),...
                sas.syn{i_}.thv.(sas.mon.cp{j_}),...
                sas.syn{i_}.thd.(sas.mon.cp{j_}));
        end
    end
    %% *OUTPUT*
    varargout{1} = sas;
    return
end

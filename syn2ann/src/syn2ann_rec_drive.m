%% *GENERATION OF STRONG GROUND MOTION SIGNALS BY COUPLING PHYSICS-BASED ANALYSIS WITH ARTIFICIAL NEURAL NETWORKS*
% _Editor: Filippo Gatti
% CentraleSupélec - Laboratoire MSSMat
% DICA - Politecnico di Milano
% Copyright 2016_
%% *NOTES*
% _syn2ann_rec_drive_: function to parse and correct recordings
%% *N.B.*
% Need for:
% _importdata.m,syn2ann_rec_parser.m,syn2ann_blc.m,syn2ann_thp.m,syn2ann_spp.m_
fprintf('---------------------\n1. RECORDS\n---------------------\n');
%% *PARSING RECORDS*
fprintf('--> Parsing\n');
% _original_
% corrected MRN (Roberto)
ew = importdata(fullfile(bhr.pt,'EW_corrette.csv'));
ns = importdata(fullfile(bhr.pt,'NS_corrette.csv'));
ud = importdata(fullfile(bhr.pt,'UD_corrette.csv'));
idx = 2;
cor.MRN.tha.ew = ew.data(:,idx+12*0);
cor.MRN.thv.ew = ew.data(:,idx+12*1);
cor.MRN.thd.ew = ew.data(:,idx+12*2);
cor.MRN.tha.ns = ns.data(:,idx+12*0);
cor.MRN.thv.ns = ns.data(:,idx+12*1);
cor.MRN.thd.ns = ns.data(:,idx+12*2);
cor.MRN.tha.ud = ud.data(:,idx+12*0);
cor.MRN.thv.ud = ud.data(:,idx+12*1);
cor.MRN.thd.ud = ud.data(:,idx+12*2);
% corrected MIR01 (Roberto)
idx = 3;
cor.MIR01.tha.ew = ew.data(:,idx+12*0);
cor.MIR01.thv.ew = ew.data(:,idx+12*1);
cor.MIR01.thd.ew = ew.data(:,idx+12*2);
cor.MIR01.tha.ns = ns.data(:,idx+12*0);
cor.MIR01.thv.ns = ns.data(:,idx+12*1);
cor.MIR01.thd.ns = ns.data(:,idx+12*2);
cor.MIR01.tha.ud = ud.data(:,idx+12*0);
cor.MIR01.thv.ud = ud.data(:,idx+12*1);
cor.MIR01.thd.ud = ud.data(:,idx+12*2);
% corrected MIR02 (Roberto)
idx = 4;
cor.MIR02.tha.ew = ew.data(:,idx+12*0);
cor.MIR02.thv.ew = ew.data(:,idx+12*1);
cor.MIR02.thd.ew = ew.data(:,idx+12*2);
cor.MIR02.tha.ns = ns.data(:,idx+12*0);
cor.MIR02.thv.ns = ns.data(:,idx+12*1);
cor.MIR02.thd.ns = ns.data(:,idx+12*2);
cor.MIR02.tha.ud = ud.data(:,idx+12*0);
cor.MIR02.thv.ud = ud.data(:,idx+12*1);
cor.MIR02.thd.ud = ud.data(:,idx+12*2);
% corrected MIR08 (Roberto)
idx = 6;
cor.MIR08.tha.ew = ew.data(:,idx+12*0);
cor.MIR08.thv.ew = ew.data(:,idx+12*1);
cor.MIR08.thd.ew = ew.data(:,idx+12*2);
cor.MIR08.tha.ns = ns.data(:,idx+12*0);
cor.MIR08.thv.ns = ns.data(:,idx+12*1);
cor.MIR08.thd.ns = ns.data(:,idx+12*2);
cor.MIR08.tha.ud = ud.data(:,idx+12*0);
cor.MIR08.thv.ud = ud.data(:,idx+12*1);
cor.MIR08.thd.ud = ud.data(:,idx+12*2);

bhr.lfr = [];
bhr.hfr = [];
[bhr,rec.org] = syn2ann_rec_parser(bhr,cor);

%% *BASELINE CORRECTION*
rec.fil = syn2ann_blc(rec.org);

%% *PGA-PGV-PGD & ARIAS INTENSITY*
fprintf('--> Peak Values and Arias\n');
rec.org = syn2ann_thp(rec.org);
rec.fil = syn2ann_thp(rec.fil);
%% *SPECTRA*
fprintf('--> Spectra\n');
rec.org = syn2ann_spp(rec.org);
rec.fil = syn2ann_spp(rec.fil);

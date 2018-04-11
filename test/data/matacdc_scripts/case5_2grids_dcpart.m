function [baseMVAac, baseMVAdc, pol, busdc, convdc, branchdc] = case5_2gridsdc()
%% dc grid topology

%% system MVA base
baseMVAac = 100;
baseMVAdc = 100;

%colunm_names% dcpoles
pol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%   busdc_i busac_i  grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
busdc = [
    1       2       1       0       1       345         1.1     0.9     0;
    2       7       1       0       1       345         1.1     0.9     0;
];

%% converters
%   busdc_i  type_dc type_ac P_g   Q_g   Vtar    rtf xtf   bf    rc      xc    basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  
convdc = [
    1         1       1       -60    -40    1     0.01  0.01  0.01 0.01   0.01  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885;
    2         2       1       0       0     1     0.01  0.01  0.01 0.01   0.01  345         1.1     0.9     1.1     1       1.103 0.887  2.885    2.885;
];

%% branches
%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status
branchdc = [
    1       2       0.052   0   0    100     100     100     1;
 ];
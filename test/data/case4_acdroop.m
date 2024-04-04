function mpc = case4acdroop()
% 4bus case to test the AC voltage control functionalities of HVDC converters

%% MATPOWER Case Format : Version 1
%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 1000;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
    1       3       0    0	0   0   1       1	 0  380     1       1.1     0.9;
    2       3       0    0	0   0   1       1    0	380     1       1.1     0.9;
    3       2       0    0	0   0   1       1    0	380     1       1.1     0.9;
    4       2       0    0	0   0   1       1    0	380     1       1.1     0.9;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	-600      0	400      -400    1	  100       1       1000     -1000 0 0 0 0 0 0 0 0 0 0 0;
    2	600      0	400      -400    1	  100       1       1000     -1000 0 0 0 0 0 0 0 0 0 0 0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle status angmin angmax
mpc.branch = [
    1   3   0.111803414E-01    0.758119137E-01    0.945984133E-02    250   250   250     0       0       1 -90 90;
    2   4   0.401327479E-01    0.272541773        0.340797668E-01    250   250   250     0       0       1 -90 90;
];


%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=1;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
    1              1       -600       1       380         1.1     0.9     0;
    2              1       600       1       380         1.1     0.9     0;
    3              1       -600       1       380         1.1     0.9     0;
    4              1       600       1       380         1.1     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin acq_droop kq_droop Vtar
mpc.convdc = [
    1       3   2       2       -600      100    0 1     0  0 0 1 0 0 0.0074   0.1849 1  380         1.1     0.9     11     1       0 0  0    0      0.0050    -58.6274   1.0079   0 250 -250 100 -100 1 20 1;
    2       4   1       2       600       100    0 1     0  0 0 1 0 0 0.0074   0.1849 1  380         1.1     0.9     11     1       0 0  0    0      0.0070     21.9013   1.0000   0 250 -250 100 -100 0 0 1;
    3       3   2       2       -600      -100    0 1     0  0 0 1 0 0 0.0074   0.1849 1  380         1.1     0.9     11     1       0 0  0    0      0.0050    -58.6274   1.0079   0 250 -250 100 -100 1 10 1;
    4       4   1       1       600       100    0 1     0  0 0 1 0 0 0.0074   0.1849 1  380         1.1     0.9     11     1       0 0  0    0      0.0070     21.9013   1.0000   0 250 -250 100 -100 0 0 1;
];

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status
mpc.branchdc = [
    1       2       0.644767896E-02   0   0    250     250     250     1;
    3       4       0.644767896E-02   0   0    250     250     250     1;
 ];

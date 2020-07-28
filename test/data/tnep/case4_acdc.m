function mpc = case4tnep()
% 4bus case to test hybrid AC/DC transmission expansion optimization
% problem

%% MATPOWER Case Format : Version 1
%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
    1       1       0	   0	0   0   1       1	 0	345     1       1.1     0.9;
	  2       3       0	   0	0   0   1       1    0	345     1       1.1     0.9;
    3       1       100    0	0   0   1       1    0	345     1       1.1     0.9;
    4       1       200    0	0   0   1       1    0	345     1       1.1     0.9;
];
%  4       1       0    0	0   0   1       1       0	345     1       1.1     0.9;
%  1       1       0	   0	0   0   1       1	 0	345     1       1.1     0.9;

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	2	0      0	400      -400    1	  100       1       400     -400 0 0 0 0 0 0 0 0 0 0 0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle status angmin angmax
mpc.branch = [
    1   2   0.02    0.06    0    250   250   250     0       0       1 -90 90;
];

%column_names% f_bus	t_bus	br_r	br_x	br_b	rate_a	rate_b	rate_c	tap	shift	br_status	angmin	angmax	construction_cost
mpc.ne_branch = [
  1  4   0.020   0.200   0.00   150  150  150  0  0  1 -60  60 1;
];


%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
    1              1       0       1       345         1.1     0.9     0;
    2              1       0       1       345         1.1     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin
mpc.convdc = [
    1       2   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     11     1       0 0  0    0      0.0050    -58.6274   1.0079   0 250 -250 100 -100;
    2       3   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     11     1       0 0  0    0      0.0070     21.9013   1.0000   0 250 -250 100 -100;
];

%     1       2   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     11     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 300 -300 100 -100;
%     2       3   2       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     11     1       1.103 0.887  2.885    2.885      0.0070     21.9013   1.0000   0 300 -300 100 -100;

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status
mpc.branchdc = [
    1       2       0.052   0   0    250     250     250     1;
 ];

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	2	 1	0;
];
%% candidate dc bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc_ne = [
    3              1       0       1       345         1.1     0.9     0;
    4              1       0       1       345         1.1     0.9     0;
	  5              1       0       1       345         1.1     0.9     0;
];

%% candidate branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC status cost
mpc.branchdc_ne = [
    3       4       0.052   0   0    200     150     150     1 1;
    3       5       0.052   0   0    200     150     150     1 1;
    3       1       0.052   0   0    200     150     150     1 1;
 ];

%% candidate converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin cost
mpc.convdc_ne = [
    3       4   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     2.2     1     1.103 0.887  2.885    1.885       0.0050    -58.6274   1.0079   0 100 -100 50 -50 1;
    3       4   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     5.0     1     1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 250 -250 100 -100 2;
    4       1   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     2.2     1     1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 50 -50 1.2;
    5       2   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 0  345         1.1     0.9     2.2     1     1.103 0.887  2.885    1.885     0.0050    -58.6274   1.0079   0 250 -250 100 -100 1.1;
];

%     3       4   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 10 -10 1;
%     3       4   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 300 -300 20 -20 2;
%     4       1   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 10 -10 1;
%     5       2   1       1       0       0    0 1     0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     1.1     1       1.103 0.887  2.885    1.885      0.0050    -58.6274   1.0079   0 100 -100 10 -10 1;

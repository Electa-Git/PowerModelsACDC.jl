function mpc = case5_acdc()
%case 5 nodes    Power flow data for 5 bus, 2 generator case.
%   Please see 'help caseformat' for details on the case file format.
%
%   case file can be used together with dc case files "case5_stagg_....m"
%
%   Network data from ...
%   G.W. Stagg, A.H. El-Abiad, "Computer methods in power system analysis",
%   McGraw-Hill, 1968.
%
%   MATPOWER case file data provided by Jef Beerten.

%% MATPOWER Case Format : Version 1
%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1       3       0	0	0   0   1       1.06	0	345     1       1.1     0.9;
	2       2       1950 0	0   0   1       1       0	345     1       1.1    0.9;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	0       0	500      -500    1.00	100       1       5000     0 0 0 0 0 0 0 0 0 0 0 0;
    2	0       0	500      -500    1.00	100       1       5000     0 0 0 0 0 0 0 0 0 0 0 0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
    %1   2   0.02    0.06    0.06    100   100   100     0       0       1 -60 60;
];


%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
    1              1       0       1       525         1.0     1.0     0;
    2              1       0       1       525         1.1     0.9     0;
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g islcc  Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin
mpc.convdc = [
    1       1   1       1       0       0     0 1     0.01  0.01 0 1 0.01 0 0.01   0.01 0  525         1.0     1.0     50     1       0.0 0.0  0.0    0.0      0.0    0.0   1.00   0 4100 -4100 500 -500;
    2       2   2       1       0       0     0 1     0.01  0.01 0 1 0.01 0 0.01   0.01 0  525         1.1     0.9     50     1       0.0 0.0  0.0    0.0      0.0    0.0   1.00   0 4100 -4100 500 -500;
];

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status
mpc.branchdc = [
    1       2       0.00078367   0   0    1500     1500     1500     1;
 ];

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0  1	0;
    2	0	0	3	0  100	0;
];

% adds current ratings to branch matrix
%column_names%	c_rating_a
%mpc.branch_currents = [
%100;100;100;100;100;100;100;
%];

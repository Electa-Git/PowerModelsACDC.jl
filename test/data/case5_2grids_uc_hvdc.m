function mpc = case5_2gris_inertia_hvdc()
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
	1	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.00000	    2.80377	 230.0	 1	    1.10000	    0.90000; % grid 1
	2	 1	 300.0	 98.61	 0.0	 0.0	 1	    1.08407	   -0.73465	 230.0	 1	    1.10000	    0.90000;
	3	 2	 300.0	 98.61	 0.0	 0.0	 1	    1.00000	   -0.55972	 230.0	 1	    1.10000	    0.90000;
	4	 3	 400.0	 131.47	 0.0	 0.0	 1	    1.00000	    0.00000	 230.0	 1	    1.10000	    0.90000;
	5	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.00000	    3.59033	 230.0	 1	    1.10000	    0.90000;


	6	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.00000	    2.80377	 230.0	 2	    1.10000	    0.90000; % grid 2
	7	 1	 300.0	 98.61	 0.0	 0.0	 1	    1.08407	   -0.73465	 230.0	 2	    1.10000	    0.90000;
	8	 2	 300.0	 98.61	 0.0	 0.0	 1	    1.00000	   -0.55972	 230.0	 2	    1.10000	    0.90000;
	9	 2	 400.0	 131.47	 0.0	 0.0	 1	    1.00000	    0.00000	 230.0	 2	    1.10000	    0.90000;
	10	 2	 0.0	 0.0	 0.0	 0.0	 1	    1.00000	    3.59033	 230.0	 2	    1.10000	    0.90000;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	 40.0	 		 30.0	 	30.0	 -30.0	 1.07762	 100.0	 1	 200.0	 0.0; % RES
	1	 170.0	 		 127.5	 	127.5	 -127.5	 1.07762	 100.0	 1	 200.0	 0.0; % RES
	3	 324.498	 	 390.0	 	390.0	 -390.0	 1.1	 	 100.0	 1	 520.0	 0.0; % Gas
	4	 0.0	 		-10.802	 	150.0	 -150.0	 1.06414	 100.0	 1	 200.0	 0.0; % Gas
	5	 470.694	 	-165.039	450.0	 -450.0	 1.06907	 100.0	 1	 600.0	 0.0; % RES

	6	 40.0	 		 30.0	 	30.0	 -30.0	 1.07762	 100.0	 1	 100.0	 0.0; % RES
	6	 170.0	 		 127.5	 	127.5	 -127.5	 1.07762	 100.0	 1	 400.0	 0.0; % RES
	8	 324.498	 	 390.0	 	390.0	 -390.0	 1.1	 	 100.0	 1	 400.0	 0.0; % Gas
	9	 0.0	 		-10.802	 	150.0	 -150.0	 1.06414	 100.0	 1	 200.0	 0.0; % RES
	10	 470.694	 	-165.039	450.0	 -450.0	 1.06907	 100.0	 1	 300.0	 0.0; % RES
];

%column_names% gen_id inertia_constant ramp_rate
mpc.inertia_constants = [
	1	1 2; % ramp rate in pu of pmax / hour
	2	1 2; % 
	3	5 0.6;
	4	5 0.6;
	5	1 2;
	6	1 2;
	7	1 2;
	8	5 0.6;
	9	1 2;
	10	1 2;
]

%column_names%   zone
mpc.zones = [
	1;
	2;
]

%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	  1000.0	 0.0	 3	   0.000000	  10.000000	    100.000000; % grid 1
	2	  1000.0	 0.0	 3	   0.000000	  11.000000	    100.000000;
	2	 30000.0	 0.0	 3	   0.000000	  55.000000	   1000.000000;
	2	 40000.0	 0.0	 3	   0.000000	  50.000000	   1000.000000;
	2	  1000.0	 0.0	 3	   0.000000	  12.000000	    100.000000;

	2	  1000.0	 0.0	 3	   0.000000	  15.000000	    100.000000; % grid 2
	2	  1000.0	 0.0	 3	   0.000000	  14.000000	    100.000000;
	2	 40000.0	 0.0	 3	   0.000000	  50.000000	   1000.000000;
	2	  1000.0	 0.0	 3	   0.000000	  13.000000	    100.000000;
	2	  1000.0	 0.0	 3	   0.000000	  10.000000	    100.000000;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
1	 2	 0.00281	 0.0281	 0.00712	 400.0	 400.0	 400.0	 0.0	  0.0	 1	 -30.0	 30.0; % grid 1
1	 4	 0.00304	 0.0304	 0.00658	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
1	 5	 0.00064	 0.0064	 0.03126	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
2	 3	 0.00108	 0.0108	 0.01852	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
3	 4	 0.00297	 0.0297	 0.00674	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
4	 5	 0.00297	 0.0297	 0.00674	 240.0	 240.0	 240.0	 0.0	  0.0	 1	 -30.0	 30.0;

6	 7	 0.00281	 0.0281	 0.00712	 400.0	 400.0	 400.0	 0.0	  0.0	 1	 -30.0	 30.0; % grid 2
6	 9	 0.00304	 0.0304	 0.00658	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
6	 10	 0.00064	 0.0064	 0.03126	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
7	 8	 0.00108	 0.0108	 0.01852	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
8	 9	 0.00297	 0.0297	 0.00674	 426	 426	 426	 0.0	  0.0	 1	 -30.0	 30.0;
9	 10	 0.00297	 0.0297	 0.00674	 240.0	 240.0	 240.0	 0.0	  0.0	 1	 -30.0	 30.0;
];

%% dc grid topology
%colunm_names% dcpoles
mpc.dcpol=2;
% numbers of poles (1=monopolar grid, 2=bipolar grid)
%% bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc = [
    1              1       0       1       525         1.1     0.9     0; % grid 1
    2              1       0       1       525         1.1     0.9     0; % grid 2
];

%% converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g islcc  Vtar    rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac    Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop      Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin
mpc.convdc = [
    1       5   1       1       0       0     0 1     0.000713994  0.024989802 1 1 4.99 1 0.000416435  0.012493061 1  525         1.1     0.9     1.1     1       0.66198 1.3943009  0.003085833    0.003085833      0    0   0  0 600 -600 200 -200;
    2      10   2       1       0       0     0 1     0.000713994  0.024989802 1 1 4.99 1 0.000416435  0.012493061 1  525         1.1     0.9     1.1     1       0.66198 1.3943009  0.003085833    0.003085833      0    0   0  0 600 -600 200 -200;
];

%% branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC   status
mpc.branchdc = [
    1       2       0.000436074   0   0    600     600     600     1;
 ];
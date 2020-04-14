% Garver system - Transmission Network Estimation Using Linear Programming, IEEE trans. on power appratus and sys
% Power system transmission network expansion planning using AC model by Rider, MJ and Garcia, AV and Romero, R
%modification: gen cost is changed. A low value is set to penalize power losses but not dominate the objective.
function mpc = case6
mpc.version = '2';
mpc.baseMVA = 100.0;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm      Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	 3	 80	   16	 0.0	 0.0	  1	    1.10000	   -0.00000	   240.0	 1	    1.05000	    0.95000;
	2	 1	 240	 48  0.0	 0.0	  1	    0.92617	    7.25883	   240.0	 1	    1.05000	    0.95000;
	3	 2	 40	   8	 0.0	 0.0	 	1	    0.90000	   -17.26710	 240.0	 1	  	1.05000	    0.95000;
	4	 1	 160	 32	 0.0	 0.0	  1	    1.10000	   -0.00000	   240.0	 1	    1.05000	    0.95000;
	5	 1	 240	 48	 0.0	 0.0	  1	    0.92617	    7.25883	   240.0	 1	    1.05000	    0.95000;
	6	 2	  0    0	 0.0	 0.0	  1	    0.90000	   -17.26710	 240.0	 1	    1.05000	    0.95000;
];

%% generator data
%	bus	Pg      Qg	Qmax	Qmin	Vg	mBase       status	Pmax	Pmin	pc1 pc2 qlcmin qlcmax qc2min qc2max ramp_agc ramp_10 ramp_30 ramp_q apf
mpc.gen = [
	1	 148	 54   48.0	 -10.0	 1.1	     100.0	 1	 150.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0;
	3	 170	 -8	 101.0	 -10.0	 0.92617	 100.0	 1	 360.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0;
	6	 0.0	 -4  183.0	 -10.0	 0.9	     100.0	 1	 600.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0;
];

mpc.gencost = [
	2	 0.0	 0.0	 3	   0	   0.01	   0;
	2	 0.0	 0.0	 3	   0	   0.01     0;
	2	 0.0	 0.0	 3	   0	   0.01	   0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle
%	status angmin angmax
mpc.branch = [
	1   2   0.040   0.400   0.00   100  100  100  0  0  1 -60  60;
	1   4   0.060   0.600   0.00   80   80   80   0  0  1 -60  60;
	1   5   0.020   0.200   0.00   100  100  100  0  0  1 -60  60;
	2   3   0.020   0.200   0.00   100  100  100  0  0  1 -60  60;
  2   4   0.040   0.400   0.00   100  100  100  0  0  1 -60  60;
  3   5   0.020   0.200   0.00   100  100  100  0  0  1 -60  60;
];


%% candidate dc bus data
%column_names%   busdc_i grid    Pdc     Vdc     basekVdc    Vdcmax  Vdcmin  Cdc
mpc.busdc_ne = [
1              1       0       1       345         1.1     0.9     0;
2              1       0       1       345         1.1     0.9     0;
3              1       0       1       345         1.1     0.9     0;
4              1       0       1       345         1.1     0.9     0;
5              1       0       1       345         1.1     0.9     0;
6              1       0       1       345         1.1     0.9     0;
];

%% candidate branches
%column_names%   fbusdc  tbusdc  r      l        c   rateA   rateB   rateC status cost
mpc.branchdc_ne = [
	2	 5	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.3;
	2	 6	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.4;
	2	 6	 0.01	 0.00	 0.00  400.0	 0.0	 0.0	 1.0	 3.4;
	3	 6	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.6;
	3	 6	 0.01	 0.00	 0.00  400.0	 0.0	 0.0	 1.0	 3.6;
	4	 5	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.7;
	4	 5	 0.01	 0.00	 0.00  400.0	 0.0	 0.0	 1.0	 3.7;
	4	 6	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.8;
	4	 6	 0.01	 0.00	 0.00  400.0	 0.0	 0.0	 1.0	 3.8;
	5	 6	 0.01	 0.00	 0.00  200.0	 0.0	 0.0	 1.0	 2.9;
	5	 6	 0.01	 0.00	 0.00  400.0	 0.0	 0.0	 1.0	 3.9;
 ];

%% candidate converters
%column_names%   busdc_i busac_i type_dc type_ac P_g   Q_g  islcc  Vtar rtf xtf  transformer tm   bf filter    rc      xc  reactor   basekVac Vmmax   Vmmin   Imax    status   LossA LossB  LossCrec LossCinv  droop Pdcset    Vdcset  dVdcset Pacmax Pacmin Qacmax Qacmin cost
mpc.convdc_ne = [
1       1   1       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1     	1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 3;
2       2   1       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1      1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 3.5;
3       3   1       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1      1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 2.5;
4       4   1       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1      1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 4;
5       5   1       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1      1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 4.5;
6       6   2       1       -360    -1.66   		0 1.0        0.01  0.01 1 1 0.01 1 0.01   0.01 1  345         1.1     0.9     15     1      1.1033 0.887  2.885    2.885       0.0050    -52.7   1.0079   0 700 -700 700 -700 5;
];

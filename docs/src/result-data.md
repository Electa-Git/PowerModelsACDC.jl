# PowerModels Result Data Format

## The Result Data Dictionary

PowerModels utilizes a dictionary to organize the results of a run command. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange.
The data dictionary organization is  consistent with  PowerModels.


## Solution Data

### Unbalanced OPF

#### Buses

For example the data for a bus, `data["bus"]["1"]` is structured as follows,

```
{
"zone":1,
"bus_i":1,
"Vaph1":0.0,
"Gs1":0,
"bus_type":3,
"qd":0.0,
"gs":0.0,
"bs":0.0,
"vmax":1.1,
"Vmph3":0.9959,
"Vmph1":0.9959,
"Vaph2":-2.0943951023931953,
"Gs2":0,
"area":1,
"vmin":0.9,
"index":1,
"Bs2":0,
"Vmph2":0.9959,
"va":0.048935017968641414,
"Bs1":0,
"vm":1.07762,
"Bs3":0,
"base_kv":0.4,
"Vaph3":2.0943951023931953,
"pd":0.0,
"Gs3":0
}
```

A solution specifying a voltage magnitude and angle would for the same case, i.e. `result["solution"]["bus"]["1"]`, would result in,

```
{
"vmv":0.9958999999999999,
"viuv":0.858938553360444,
"vruv":-0.4959084049999998,
"vmu":0.9959,
"vaw":119.99999999999999,
"vrvv":0.9918168099999999,
"vrww":0.9918168099999999,
"vmw":0.9958999999999999,
"vruu":0.99181681,
"vav":-119.99999999999999,
"viuw":-0.858938553360444,
"vruw":-0.4959084049999998,
"vau":0.0,
"vivw":0.8589385533604436,
"vrvw":-0.49590840500000033
}
```

where the voltage phase $V$ (3x1) is defined as  

$V = \begin{bmatrix} vmu \angle vau^{\circ}\\ vmv \angle vav^{\circ} \\ vmw \angle vaw^{\circ} \end{bmatrix}$

with $vmx$ representing the voltage magnitude of phase $x$ in pu and $vax$ representing the voltage angle of phase $x$ in degrees.

#### Branches

A solution specifying a branch power flow for the same case, i.e. `result["solution"]["branch"]["2"]`, would result in

```
{
"pstvv":-0.006,
"pstww":-0.006,
"pstuu":-0.009,
"isruu":9.691239090308176e-5,
"pstwu":0.00727888452032817,
"qstvu":0.00947767910427501,
"qstuv":-0.0036509497941715954,
"qstwv":0.006665255346387849,
"qsfwv":-0.006734342877246977,
"qfu":0.003094790969043324,
"qsfuu":0.0030952176297659438,
"qstuw":0.006599353624148247,
"isiuv":5.309050048609495e-5,
"pfv":0.006039597858503457,
"qsfuv":0.0036914898337854656,
"pstvw":0.005592472532370747,
"isruw":-2.6015611949976753e-5,
"isivw":4.0844846258572364e-5,
"pstvu":0.0018982240916506643,
"isruv":-4.1312347643436824e-5,
"qtv":-0.0029999999818118104,
"psfuw":-0.0004624459425037982,
"psfwu":-0.007338608376368642,
"isrww":4.7140901274024886e-5,
"rank":1,
"psfww":0.006070929962058776,
"pfw":0.006070929962058776,
"qstww":-0.002999576931337203,
"psfuu":0.009148425088931482,
"qstvv":-0.002999572608055382,
"psfvu":-0.0018914010421271533,
"pstuw":0.00048416401314022836,
"qfw":0.0030146477211191233,
"qsfvw":0.0037821579550759528,
"qstwu":-0.006285102066852067,
"qsfuw":-0.006720628728116081,
"iu":0.009844409119042228,
"qsfvu":-0.009555399624069493,
"isrvw":-2.3095584804159215e-5,
"qsfww":0.003015079704932311,
"qtw":-0.002999999981808746,
"pstuv":0.005478462806782956,
"qstvw":-0.003765723685325103,
"isrvv":4.666407446621145e-5,
"ptv":-0.006,
"qstuu":-0.002999588313762525,
"isiuw":-6.240799439612135e-5,
"pstwv":0.0003401994561094154,
"qtu":-0.0029999999818115406,
"qsfvv":0.0030364136823634305,
"psfwv":-0.00036152747931843444,
"ptw":-0.006,
"iw":0.006865923191678224,
"iv":0.006831110778358923,
"qsfwu":0.006370445873360597,
"qfv":0.003035979661587844,
"psfvw":-0.00564436155659646,
"ptu":-0.009,
"psfuv":-0.005594151841277011,
"pfu":0.009148425088931482,
"psfvv":0.006039597858503457
}
```

where the line flow $S_{ft}, S_{tf}$ is defined as

$S_{ft} = \begin{bmatrix} pfu +j qfu\\ pfv +j qfv \\ pfw +j qfw \end{bmatrix}$

$S_{tf} = \begin{bmatrix} ptu +j qtu\\ ptv +j qtv \\ ptw +j qtw \end{bmatrix}$

Furthermore:
- iu, iv, iw are the squared magnitude of the series current in each phase
- psfxy, qsfxy, pstxy, qstxy are the active and reactive series flow components from phase x to y and vice versa
- isrxy, isixy are the series current flow products from phase x to y
- rank is the rank of the PSD-constrained matrix for the line


####  Generators
`result["solution"]["gen"]["1"]` evaluates to:
```
{
"pgu":0.009275584874257826,
"pgv":0.006073435351158063,
"qgv":0.003067157338666488,
"qgw":0.0030276799534092284,
"qgu":0.0031774636362881317,
"pgw":0.006131923378155207
}
```

where the generator's power output $S_{g}$ is defined as

$S_{g} = \begin{bmatrix} pgu +j qgu\\ pgv +j qgv \\ pgw +j qgw \end{bmatrix}$


### SCOPF
TODO

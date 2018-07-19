# File IO

```@meta
CurrentModule = PowerModelsACDC
```

## Specific Data Formats
The .m matpower files have been extended with the fields as described in the MatACDC manual, available in https://www.esat.kuleuven.be/electa/teaching/matacdc#documentation.


## DC Bus
- `busdc_i`   - DC bus number
- `grid`      - DC grid to which the DC bus is connected (in case multiple DC grids)
- `Pdc`       - Power withdrawn from the DC grid (MW) (only for PF)
- `Vdc`       - DC voltage (p.u.)
- `basekVdc`  - Base DC voltage (kV)
- `Vdcmax`    - maximum DC voltage (p.u.)
- `Vdcmin`    - minimum DC voltage (p.u.)
- `Cdc`       - DC bus capacitor size (p.u.), (not used in (optimal) power flow)


## DC Branch
- `fbusdc`  - from bus number DC
- `tbusdc`  - to bus number DC
- `r`       - resistance (p.u.)
- `l`       - inductance (p.u./s) (not used in (optimal) power flow)
- `c`       - total line charging capacity (p.u. * s) (not used in power flow)
- `rateA`   - MVA rating A
- `rateB`   - MVA rating B (long termrating, not used)
- `rateC`   - MVA rating C (long termrating, not used)
- `status`  - initial branch status, (1 - in service, 0 - out of service) (not yet implemented)


## AC DC converter
- `busdc_i`     - converter bus number (DC bus numbering)
- `busac_i`     - converter bus number (AC bus numbering)  
- `type_dc`     - DC bus type (1 = constant power, 2 = DC slack, 3 = DC droop) (only power flow)  
- `type_ac`     - AC bus type (1 = PQ, 2 = PV), should be consistent with AC bus  (only power flow)  
- `P_g`         - active power injected in the AC grid (MW)
- `Q_g`         - reactive power injected in the AC grid (MVAr)    
- `Vtar`        - target voltage of converter connected AC bus (p.u.)
- `islcc`       - binary indicating LCC converter (islcc = 1 -> LCC)
- `rtf`         - transformer resistance (p.u.) (not yet implemented)
- `xtf`         - transformer reactance (p.u.) (not yet implemented)
- `transformer` - binary indicating converter transformer    
- `bf`          - filter susceptance (p.u.) (not yet implemented)
- `filter`      - binary indicating converter filter
- `rc`          - phase reactor resistance (p.u.) (not yet implemented)   
- `xc`          - phase reactor reactance (p.u.) (not yet implemented)
- `reactor`     - binary indicating converter reactor
- `basekVac`    - converter AC base voltage (kV)    
- `Vmmax`       - maximum converter voltage magnitude (p.u.)   
- `Vmmin`       - minimumconverter voltagemagnitude (p.u.)   
- `Imax`        - maximum converter current (p.u.)   
- `status`      - converter status (1 = on, 0 = off) (not yet implemented)
- `LossA`       - constant loss coefficient (MW)
- `LossB`       - linear loss coefficient (kV)
- `LossCrec`    - rectifier quadratic loss coefficient (Ω­)
- `LossCinv`    - inverter quadratic loss coefficient (Ω­) (not yet implemented)
- `droop`       - DC voltage droop (MW/p.u) (not yet implemented)      
- `Pdcset`      - voltage droop power set-point (MW)  (not yet implemented)
- `Vdcset`      - voltage droop voltage set-point (p.u.) (not yet implemented)
- `dVdcset`     - voltage droop deadband (p.u.) (optional) (not yet implemented)
- `Pacmax`      - Maximum AC active power (MW)
- `Pacmin`      - Minimum AC active power (MW)
- `Qacmax`      - Maximum AC reactive power (Mvar)
- `Qacmin`      - Minimum AC reactive power (Mvar)

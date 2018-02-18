# File IO

```@meta
CurrentModule = PowerModelsACDC
```

## Specific Data Formats
The .m matpower files have been extended with the fields as described in the MatACDC manual


## DC Bus
- `busdc_i` 
- `grid`    
- `Pdc`     
- `Vdc`     
- `basekVdc`     
- `Vdcmax`  
- `Vdcmin`  
- `Cdc`


## DC Branch
- `fbusdc`  
- `tbusdc`  
- `r`  
- `l`  
- `c`  
- `rateA`  
- `rateB`  
- `rateC`  
- `status`


## AC DC converter
- `busdc_i`
- `busac_i`  
- `type_dc`  
- `type_ac`  
- `P_g`    
- `Q_g`    
- `Vtar`     
- `rtf`  
- `xtf`      
- `bf`      
- `rc`       
- `xc`      
- `basekVac`     
- `Vmmax`    
- `Vmmin`    
- `Imax`     
- `status`    
- `LossA`  
- `LossB`   
- `LossCrec`  
- `LossCinv`   
- `droop`       
- `Pdcset`     
- `Vdcset`   
- `dVdcset`  
- `Pacmax`  
- `Pacmin`  
- `Qacmax`  
- `Qacmin`

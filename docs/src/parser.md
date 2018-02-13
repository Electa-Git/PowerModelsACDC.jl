# File IO

```@meta
CurrentModule = PowerModelsACDC
```

## Specific Data Formats
The .m matpower files have been extended with the following fields:

### SCOPF

- `mpc.gen_rated.prated` rated active power of generator
- `mpc.gen_rated.qrated` rated reactive power of generator
- `mpc.gen_rated.pref`  reference active power set point of generator
- `mpc.gen_rated.qref`  reference reactive power set point of generator
- `mpc.load.load_bus` bus to which load is connected
- `mpc.load.pref` reference active power value of load
- `mpc.load.qref` reference reactive power value of load
- `mpc.load.status` reference status of load
- `mpc.load.qmax` reactive power maximum of load
- `mpc.load.qmin` reactive power minimum of load
- `mpc.load.pmax` active power maximum of load
- `mpc.load.pmin` active power minimum of load
- `mpc.load.prated` rated active power of load
- `mpc.load.qrated` rated reactive power of load
- `mpc.load.voll` value of lost load
- `mpc.branch_variable_transformer.g_shunt` conductive shunt of transformer
- `mpc.branch_variable_transformer.shiftable` is transformer shiftable?
- `mpc.branch_variable_transformer.shift_fr` shift set point at from side
- `mpc.branch_variable_transformer.shift_to` shift set point at to side
- `mpc.branch_variable_transformer.shift_fr_max` maximum shift set point at from side
- `mpc.branch_variable_transformer.shift_fr_min` minimum shift set point at from side
- `mpc.branch_variable_transformer.shift_to_max` maximum shift set point at to side
- `mpc.branch_variable_transformer.shift_to_min` minimum shift set point at to side
- `mpc.branch_variable_transformer.tappable` is transformer tappable?
- `mpc.branch_variable_transformer.tap_fr` tap setting at from side
- `mpc.branch_variable_transformer.tap_to` tap setting at to side
- `mpc.branch_variable_transformer.tap_fr_max` maximum tap setting at from side
- `mpc.branch_variable_transformer.tap_fr_min` minimum tap setting at from side
- `mpc.branch_variable_transformer.tap_to_max` maximum tap setting at to side
- `mpc.branch_variable_transformer.tap_to_min` minimum tap setting at to side
- `mpc.contingencies.prob` probability of contingency c
- `mpc.contingencies.branch_id1` id of first branch involved in contingency c, otherwise 0 if not involved
- `mpc.contingencies.branch_id2` id of second branch involved in contingency c, otherwise 0 if not involved
- `mpc.contingencies.branch_id3` id of third branch involved in contingency c, otherwise 0 if not involved
- `mpc.contingencies.gen_id1` id of first generator involved in contingency c, otherwise 0 if not involved
- `mpc.contingencies.gen_id2` id of second generator involved in contingency c, otherwise 0 if not involved
- `mpc.contingencies.gen_id3` id of third generator involved in contingency c, otherwise 0 if not involved



### Unbalanced OPF
- `mpc.bus_voltage_ref.Vmph1` reference voltage magnitude for phase 1
- `mpc.bus_voltage_ref.Vmph2` reference voltage magnitude for phase 2
- `mpc.bus_voltage_ref.Vmph3` reference voltage magnitude for phase 3
- `mpc.bus_voltage_ref.Vaph1` reference voltage angle for phase 1
- `mpc.bus_voltage_ref.Vaph2` reference voltage angle for phase 2
- `mpc.bus_voltage_ref.Vaph3` reference voltage angle for phase 3
- `mpc.bus_voltage_ref.Bs1` bus shunt susceptance in phase 1
- `mpc.bus_voltage_ref.Bs2` bus shunt susceptance in phase 2
- `mpc.bus_voltage_ref.Bs3` bus shunt susceptance in phase 3
- `mpc.bus_voltage_ref.Gs1` bus shunt conductance in phase 1
- `mpc.bus_voltage_ref.Gs2` bus shunt conductance in phase 2
- `mpc.bus_voltage_ref.Gs3` bus shunt conductance in phase 3
- `mpc.gen_rated.prated` rated active power of generator
- `mpc.gen_rated.qrated` rated reactive power of generator
- `mpc.gen_rated.pref`  reference active power set point of generator
- `mpc.gen_rated.qref`  reference reactive power set point of generator
- `mpc.gen_per_phase.Pph1ref` generator reference active power phase 1
- `mpc.gen_per_phase.Qph1ref` generator reference reactive power phase 1
- `mpc.gen_per_phase.Pph1rated` generator rated active power phase 1
- `mpc.gen_per_phase.Qph1rated` generator rated reactive power phase 1
- `mpc.gen_per_phase.Pph1max` generator maximum active power phase 1
- `mpc.gen_per_phase.Qph1max` generator maximum reactive power phase 1
- `mpc.gen_per_phase.Pph1min` generator minimum active power phase 1
- `mpc.gen_per_phase.Qph1min` generator minimum reactive power phase 1
- `mpc.gen_per_phase.Pph2ref` generator reference active power phase 2
- `mpc.gen_per_phase.Qph2ref` generator reference reactive power phase 2
- `mpc.gen_per_phase.Pph2rated` generator rated active power phase 2
- `mpc.gen_per_phase.Qph2rated` generator rated reactive power phase 2
- `mpc.gen_per_phase.Pph2max` generator maximum active power phase 2
- `mpc.gen_per_phase.Qph2max` generator maximum reactive power phase 2
- `mpc.gen_per_phase.Pph2min` generator minimum active power phase 2
- `mpc.gen_per_phase.Qph2min` generator minimum reactive power phase 2
- `mpc.gen_per_phase.Pph3ref` generator reference active power phase 3
- `mpc.gen_per_phase.Qph3ref` generator reference reactive power phase 3
- `mpc.gen_per_phase.Pph3rated` generator rated active power phase 3
- `mpc.gen_per_phase.Qph3rated` generator rated reactive power phase 3
- `mpc.gen_per_phase.Pph3max` generator maximum active power phase 3
- `mpc.gen_per_phase.Qph3max` generator maximum reactive power phase 3
- `mpc.gen_per_phase.Pph3min` generator minimum active power phase 3
- `mpc.gen_per_phase.Qph3min` generator minimum active power phase 3
- `mpc.load.load_bus` bus to which the load is connected
- `mpc.load.pref` reference active power of the load (not used for unbalanced OPF)
- `mpc.load.qref` reference reactive power of the load (not used for unbalanced OPF)
- `mpc.load.status` status of the load: 0 disconnected, 1 connected
- `mpc.load.qmax` maximum reactive power of the load (not used for unbalanced OPF)
- `mpc.load.qmin` minimum reactive power of the load (not used for unbalanced OPF)
- `mpc.load.pmax` maximum active power of the load (not used for unbalanced OPF)
- `mpc.load.pmin` minimum active power of the load (not used for unbalanced OPF)
- `mpc.load.prated` rated active power of the load (not used for unbalanced OPF)
- `mpc.load.qrated` rated reactive power of the load (not used for unbalanced OPF)
- `mpc.load.voll` value of lost load
- `mpc.load.Pph1ref` reference active power in phase 1
- `mpc.load.Qph1ref` reference reactive power in phase 1
- `mpc.load.Pph1max` maximum active power in phase 1
- `mpc.load.Qph1max` maximum reactive power in phase 1
- `mpc.load.Pph1min` minimum active power in phase 1
- `mpc.load.Qph1min` minimum reactive power in phase 1
- `mpc.load.Pph2ref` reference active power in phase 2
- `mpc.load.Qph2ref` reference reactive power in phase 2
- `mpc.load.Pph2max` maximum active power in phase 2
- `mpc.load.Qph2max` maximum reactive power in phase 2
- `mpc.load.Pph2min` minimum active power in phase 2
- `mpc.load.Qph2min` minimum reactive power in phase 2
- `mpc.load.Pph3ref` reference active power in phase 3
- `mpc.load.Qph3ref` reference reactive power in phase 3
- `mpc.load.Pph3max` maximum active power in phase 3
- `mpc.load.Qph3max` maximum reactive power in phase 3
- `mpc.load.Pph3min` minimum active power in phase 3
- `mpc.load.Qph3min` minimum reactive power in phase 3

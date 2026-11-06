abstract type AbstractACNFAIVRModel <: _PM.AbstractActivePowerModel end
 
mutable struct ACNFAIVRPowerModel <: AbstractACNFAIVRModel
PowerModels.@pm_fields
end
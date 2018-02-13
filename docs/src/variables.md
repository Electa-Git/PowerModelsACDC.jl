# Variables

## Squared matrix variables in unbalanced DistFlow

!!! note
    The Hermitian voltage and current matrix variables below are constructed from the scalar variables for each of the phase crossproducts. The variable names are indicated in the expanded matrix.

### Node voltage
Let $U_i$ be the complex voltage phasor (`3x1`) in node $i$. The Hermitian adjoint (complex conjugate transpose) operator is $H$.

The matrix variable for node voltage, used in the lifted unbalanced DistFlow formulation $u_i$,  is defined as

$u_i = U_i \cdot U_i^H = \begin{bmatrix} vruu& vruv& vruw\\ vrvw& vrvv &vrvw \\ vruw& vrvw &vrww \end{bmatrix}
+ j \begin{bmatrix} 0& viuv& viuw\\ -vivw& 0 &vivw \\ -viuw& -vivw &0 \end{bmatrix}$


### Line series current
Let $I_{s,ij}$ be the complex current phasor (`3x1`) in the line from $i$ to $j$. The Hermitian adjoint (complex conjugate transpose) operator is $H$.

The matrix variable for line series current, used in the lifted unbalanced DistFlow formulation $i_{s,ij}$,  is defined as

$i_{ij} = I_{s,ij} \cdot I_{s,ij}^H = \begin{bmatrix} isruu& isruv& isruw\\ isrvw& isrvv &isrvw \\ isruw& isrvw &isrww \end{bmatrix}
+ j \begin{bmatrix} 0& isiuv& isiuw\\ -isivw& 0 &isivw \\ -isiuw& -isivw &0 \end{bmatrix}$




## Functions
We provide the following methods to provide a compositional approach for defining common variables used in power flow models. These methods should always be defined over "GenericPowerModel", from the base PowerModels.jl.

```@autodocs
Modules = [PowerModelsACDC]
Pages   = ["core/variable.jl"]
Order   = [:type, :function]
Private  = true
```

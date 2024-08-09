# PIR_controllers
This repository is part of the paper:

 *The Partial Pole Placement for Second-Order Non-Minimum Phase Systems via Proportional-Integral-Retarded Controllers* by E. Moreno-Negrete, Islam Boussaada, S.-I. Niculescu, A. Ramirez, & C.-F. Mendez-Barrios (to be on L-CSS-IEEE)
 
 Recognizing that the controller parameters algebraic functions are *big enough* to attach in the paper, here we attach the MATLAB functions for PIR, PR, and SDP controllers. The user's have to look at the running test section as a demo to get the numerical value of controllers' parameters.


## Running Tests

To run the function for the PIR controller, the user must run the following command

```bash
  [h, kp, ki, kr] = f_PIR_controller(s0, a, b, c, z);
```

To run the function for the PR controller, the user must run the following command

```bash
  [h, kp, kr] = f_PR_controller(s0, a, b, c, z);
```

To run the function for the SDP controller, the user must run the following command

```bash
  [h, kr] = f_SDP_controller(s0, a, b, c, z);
```



## Feedback

If you have any feedback, please reach out to us at emone@ieee.org


## Acknowledgements

 - E. Moreno-Negrete thanks CONAHCYT for his PhD scholarship number (CVU: 990591)
 - This work was partially supported by “Fideicomiso 23871, de multas electorales, a través del Consejo Potosino de Ciencia y Tecnología (COPOCYT)”



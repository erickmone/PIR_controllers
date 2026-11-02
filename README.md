<div align="center">
  
# 🎛️ PIR & PR Controllers
**Analytical Tuning for Second-Order Non-Minimum Phase Systems**

[![Paper](https://img.shields.io/badge/Published_in-IEEE_Access-blue.svg)](https://ieeeaccess.ieee.org/)
[![Platform](https://img.shields.io/badge/Made_for-MATLAB-orange.svg)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

</div>

---

## 📖 About This Repository

This repository serves as the official supplementary code material for the research article:

> **"Analytical Tuning of PIR Controllers for Second-Order Non-Minimum Phase Systems"**  
> *by Erick Moreno-Negrete, Islam Boussaada, Silviu-Iulian Niculescu, & César-Fernando Méndez-Barrios.*  
> 📰 **To be published in:** *IEEE Access*

Recognizing that the algebraic functions defining the controller parameters are too extensive to be fully printed within the manuscript, this repository provides the complete **MATLAB functions** for both **PIR** and **PR** controllers.

---

## ⚙️ Prerequisites

Before running the examples, you must install the **TDS-Control** software package. This is strictly required for the proper execution of the delay-based control algorithms used in these examples.

🔗 **Download here:** [TDS-Control on GitLab](https://gitlab.kuleuven.be/u0011378/tds-control)

---

## 📊 Numerical Examples

To maintain strict consistency with the original manuscript, this repository includes **4 numerical examples**. These examples directly correspond to the special *Numerical Examples* section detailed in our paper. 

We highly recommend users explore the `Running Tests` section as a practical demo to observe how numerical values for the controllers' parameters are properly obtained.

---

## 🚀 Usage & Running Tests

You can easily compute the controller parameters by running the following MATLAB functions:

### 🔹 PIR Controller
To calculate the parameters for the Proportional-Integral-Retarded (PIR) controller, run:
```matlab
[h, kp, ki, kr] = f_PIR_controller(s0, a, b, c, z);

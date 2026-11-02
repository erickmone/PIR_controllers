<div align="center">
  
# 🎛️ PIR & PR Controllers
**Analytical Tuning for Second-Order Non-Minimum Phase Systems**

[![Paper](https://img.shields.io/badge/Published_in-IEEE_Access-blue.svg)](https://ieeeaccess.ieee.org/)
[![Platform](https://img.shields.io/badge/Made_for-MATLAB-orange.svg)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)

</div>

---

## 📖 About This Repository

This repository is part of the research paper:

> **"Analytical Tuning of PIR Controllers for Second-Order Non-Minimum Phase Systems"**  
> *by Erick Moreno-Negrete, Islam Boussaada, Silviu-Iulian Niculescu, & César-Fernando Méndez-Barrios.*  
> 📰 **To be published in:** *IEEE Access*

Recognizing that the algebraic functions defining the controller parameters are big enough to attach in the paper, this repository provides the complete **MATLAB functions** for both **PIR** and **PR** controllers.

---

## ⚙️ Prerequisites

To correctly execute the examples provided in this repository, previous installation of the **TDS-Control** software package is required. 

🔗 **Download and install here:** [TDS-Control on GitLab](https://gitlab.kuleuven.be/u0011378/tds-control)

---

## 📊 Numerical Examples

To maintain strict consistency with the original manuscript, this repository contains **4 numerical examples** that correspond directly to the special numerical examples section detailed in our paper. 

We highly recommend users explore the `Running Tests` section as a practical demo to obtain the numerical values of the controllers' parameters.

---

## 🚀 Running Tests

To run the function for the **PIR controller**, the user must execute the following command:

```bash
[h, kp, ki, kr] = f_PIR_controller(s0, a, b, c, z);
```

To run the function for the **PR controller**, the user must execute the following command:

```bash
[h, kp, kr] = f_PR_controller(s0, a, b, c, z);
```

---

## 📬 Feedback

If you have any feedback or require further assistance, please reach out to us at:  
📧 **[emone@ieee.org](mailto:emone@ieee.org)**

---

## 🙏 Acknowledgements

* **Fernando Méndez-Barrios** is supported by **SECIHTI--México**, under the grant *Ciencia Básica y de Frontera* (CBF2023--2024--2696), and by *"Proyectos para fortalecer la formación de recursos humanos en investigación, desarrollo tecnológico e innovación"* through the Consejo Potosino de Ciencia y Tecnología.
* **Erick Moreno-Negrete** gratefully acknowledges the financial support of Prof. Islam Boussaada through the **SPECTRE project**.
* The work of **Islam Boussaada and Silviu-Iulian Niculescu** is partially financially supported by a grant from the **"CNRS-Joint Research Programme in Africa (CNRS-Africa JRP)"** in the framework of the *"SPECTRE-EDP"* project, and by the Interdisciplinary Object H-CoDe of Paris-Saclay in the framework of the *"SPECTRE"* project.

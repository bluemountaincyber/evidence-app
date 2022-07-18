---
marp: true
theme: gaia
author: Ryan Nicholson
style: |
  section {
    background-color: #ff8800;
    color: #222222;
    padding: 30px;
  }
  h1 {
    text-align: center;
    color: #dddddd;
  }
  h2 {
    text-align: center;
  }
  .author {
    color: #222222;
  }
  .author-info {
    color: #333333;
    font-size: 22px;
  }
  img[alt~="center"] {
    display: block;
    margin: 0 auto;
  }

---
<!-- markdownlint-disable MD004 MD007 MD012 MD024 MD026 MD033-->

# Attacking and Defending Serverless Applications Workshop

![height:250px](img/Cloud_Ace_Final.png)

<p class=author>Ryan Nicholson</p>
<p class=author-info>SEC488/SEC541 Author and Instructor</p>

---

# Agenda (1/2)

* Evidence-App Overview
    - **Exercise 1: Deploying the Serverless Application**

* Serverless ATT&CK Techniques
    - **Exercise 2: Reconnaissance of Evidence-App**
    - **Exercise 3: Discovering Evidence-App Vulnerability**
    - **Exercise 4: Exploiting Evidence-App and Pivoting to Cloud Account**

---

# Agenda (2/2)

- Investigating Serverless ATT&CK techniques
    - **Exercise 5: Identifying Reconnaissance**
    - **Exercise 6: Identifying Vulnerability Discovery**
    - **Exercise 7: Identifying Exploitation and Pivot**

* Conclusion
    - **Exercise 8: Tearing Down Serverless Application**

---

# Evidence-App Overview

- _This serverless web application is used by Sherlock's blue team to import evidence data, generate MD5 and SHA1 hashes of the uploaded files, and save the files in a safe location._

![height:175px center](img/Evidence_App_Snippet.png)

- Source Code: [https://github.com/bluemountaincyber/evidence-app](https://github.com/bluemountaincyber/evidence-app)

---

![height:660px center](img/Evidence_App_Diagram.png)

---

![height:660px center](img/DevSecOps_Infinity_Loop.png)

---

# So... what's in that repo?

- **EVERYTHING** as Code
    * Application **Source Code** (`HTML`, `CSS`, `JavaScript`, and `Python 3`)
    * **Infrastructure as Code (IaC)** to build cloud resources and deploy application (`Terraform`)
    * **Exercise documentation** for this workshop (`mkdocs`)
        - In case you want to work on this afterwards or share with your friends/co-workers
    * This presentation (`marp`)

* **LOTS** of opportunity for a coding mistake...

---

# Deploying the Evidence-App

From **AWS CloudShell**:

* Install Terraform:

    ```bash
    wget https://releases.hashicorp.com/terraform/1.2.4/terraform_1.2.4_linux_amd64.zip
    unzip -d /home/cloudshell-user/.local/bin/ /home/cloudshell-user/terraform.zip
    ```

* Execute Terraform:

  ```bash
  git clone https://github.com/bluemountaincyber/evidence-app.git
  cd /home/cloudshell-user/evidence-app
  terraform init
  terraform apply
  ```

---

# Now It's Your Turn!

<br/>

## Complete _Exercise 1_ and then STOP!

<br/>

![height:300px center](img/Cloud_Ace_Final.png)

---

# MITRE ATT&CK Techniques

---

# Custom Tooling

- Custom Python script to **fuzz** this application
    - `/home/cloudshell-user/evidence-app/scripts/fuzz_evidence_app.py`
- Payloads consist of popular command injection payloads
    - [https://github.com/payloadbox/command-injection-payload-list](https://github.com/payloadbox/command-injection-payload-list)

TODO: ADD IMAGE OF TOOL

---

# Now It's Your Turn!

<br/>

## Complete _Exercise 2, 3, and 4_ and then STOP!

<br/>

![height:300px center](img/Cloud_Ace_Final.png)

---

# Now It's Your Turn!

<br/>

## Complete Exercise _5, 6, and 7_ and then STOP!

<br/>

![height:300px center](img/Cloud_Ace_Final.png)

---

# Now It's Your Turn!


## Complete _Exercise 8_ and... you're done!

## Thanks for attending!

![height:300px center](img/Cloud_Ace_Final.png)

# Evidence App

## Description

This serverless web application is used by Sherlock's blue team to import evidence data, generate MD5 and SHA1 hashes of the uploaded files, and save the files in a safe location.

## Application Diagram

![Application Diagram](docs/img/app-diagram.png)

## Deployment

### Terraform

1. Pre-requisites:

    - [Terraform 1.2.2+](https://www.terraform.io/downloads)

    - [AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

    - [Git](https://git-scm.com/downloads)

    - Command-line environment (e.g., Windows Terminal, Linux Terminal, macOS Terminal, AWS CloudShell)

2. Clone this repository to your local system/CloudShell and `cd` to the newly-cloned directory.

    ```bash
    git clone https://github.com/bluemountaincyber/evidence-app.git
    cd evidence-app
    ```

3. Use Terraform to initialize and deploy the included Infrastructure as Code (IaC). The deployment should take around 5 minutes.

    ```bash
    terraform init
    terraform apply # Answer 'yes' when prompted
    ```

### CloudFormation

1. Pre-requisites:

    - [AWS CLI Tools](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

    - [jq](https://stedolan.github.io/jq/download/)

    - [Git](https://git-scm.com/downloads)

    - Linux Command-line environment (e.g., Linux Terminal, macOS Terminal, AWS CloudShell)

2. Clone this repository to your local system/CloudShell and `cd` to the newly-cloned directory.

    ```bash
    git clone https://github.com/bluemountaincyber/evidence-app.git
    cd evidence-app
    ```

3. Use the provided `cloudformation-deploy.sh` script to deploy the CloudFormation template (`cloudformation.yaml`) and load the web content. The deployment should take around 5 minutes.

    ```bash
    ./cloudformation-deploy.sh
    ```

## Using the Application

1. Navigate to the URL shown in your terminal at the end of the deployment (e.g., `https://d16krrq07nhrmy.cloudfront.net`).

2. When you arrive, you will find a table containing a sample evidence file name (`EICAR.txt`), MD5 hash (`44d88612fea8a8f36de82e1278abb02f`), and SHA1 hash (`3395856ce81f2b7382dee72602f798b642f14140`).

    ![Default Web Page](docs/img/app-default-page.png)

3. If you wish to add your own files to the evidence app, click the **Choose File** button, select your file to upload, and click the **Submit** button.

    - Upon upload the file will be stored in an Amazon S3 bucket in your account which begins with the prefix **evidence-**.

    - The metadata (file name, MD5 hash, and SHA1 hash) is generated and stored in an Amazon DynamoDB table called **evidence**.

## Workbook Documentation

This section describes how to serve the SANS Workshop exercise content.

### Pre-requisites

- [Python 3.6+](https://www.python.org/about/gettingstarted/)
- [Python pip](https://pip.pypa.io/en/stable/installation/)

### Serving the Workbook

1. From a terminal on your local system, navigate to the `workbook` directory.

2. Create a virtual environment called `.venv`.

    ```bash
    python3 -m venv .venv
    ```

3. Activate the virtual environment.

    ```bash
    . .venv/bin/activate
    ```

4. Install required `pip` packages.

    ```bash
    pip3 install -r requirements.txt
    ```

5. Serve workbook with `mkdocs`.

    ```bash
    mkdocs serve
    ```

6. The workbook is now available at [http://localhost:8000](http:localhost:8000).

7. When finished with the workbook, type `Ctrl-C` in your terminal and then deactivate the virtual environment like so:

    ```bash
    deactivate
    ```

## Workshop Slides

The workshop slides are available by opening the file at `presentation/presentation.html` in your web browser.

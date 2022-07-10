# Exercise 8: Tearing Down Serverless Application

**Estimated time to complete:** 5 minutes

## Objectives

* Tear down **evidence-app** resources using `terraform`
* (Optional) Reset **CloudShell** home directory contents

## Challenges

### Challenge 1: Tear Down With Terraform

Log back into your **CloudShell** session and use `terraform` to destroy the **evidence-app** resources.

??? cmd "Solution"

    1. In your **CloudShell** session, run the following commands to destroy all **evidence-app** resources:

        ```bash
        cd /home/cloudshell-user/evidence-app
        terraform destroy -auto-approve
        ```

        !!! summary "Expected Results"

            ```bash
<snip>


            ```

### Challenge 2: (Optional) Reset CloudShell Home Directory
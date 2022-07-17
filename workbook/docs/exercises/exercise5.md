# Exercise 5: Identifying Reconnaissance

<!-- markdownlint-disable MD007 MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #0000ff;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Study the various resources deployed in exercise 1 to determine log sources to aid the investigation of the attack techniques in exercises 2 through 4
* Download **AWS CloudFront** access logs to your **CloudShell** session
* Breakdown the structure of the AWS CloudFront access logs
* Use various Linux commands to determine the following for each CloudFront interaction:
    * Source IP address of the requestor
    * HTTP Method of the request
    * HTTP endpoint requested
    * User-Agent of the requestor

## Challenges

### Challenge 1: Understand the Evidence-App Logging Resources

Look at the diagram outlined in the **evidence-app**'s `README.md` file. What are the possible log sources you can use to find the various attack techniques you performed in exercises 2 through 4?

??? cmd "Solution"

    1. If you open up the `README.md` file in the **evidence-app**'s source code repository, you will find the following diagram:

        ![](../img/exercise5/1.png ""){: class="w600" }

    2. The blue, dashed line indicates all of the logging interactions. Below is a list of the cloud resources, where the logs are written to in your AWS account, and what kind of data is logged:

        | Resource | Logging Destination | Log Description |
        |:---------|:--------------------|:----------------|
        | AWS CloudFront Distribution | `aws-logs-*` S3 bucket | All HTTP requests to the evidence-app |
        | AWS CloudTrail | `aws-logs` S3 bucket | Most API calls made to your AWS account |
        | Amazon API Gateway | `/aws/api_gw/evidence_api` CloudWatch log group | All interactions between CloudFront and API Gateway |
        | AWS Lambda | `/aws/lambda/evidence` CloudWatch log group | Executions of `evidence` Lambda function |

### Challenge 2: Download CloudFront Log Data

Your CloudFront access logs can be found in an S3 bucket beginning with `aws-logs-`. Use the AWS CLI in your **CloudShell** session to download the CloudFront access logs to the `cloudshell-user` home directory.

??? cmd "Solution"

    1. Take a look at which S3 buckets are in your account.
    
        ```bash
        aws s3 ls
        ```

        !!! summary "Expected Result"

            ```bash
            2022-07-17 13:33:27 aws-logs-rprcf6nm0n42opsl
            2022-07-17 13:33:27 cloudtrail-rprcf6nm0n42opsl
            2022-07-17 13:33:27 evidence-rprcf6nm0n42opsl
            2022-07-17 13:33:27 webcode-rprcf6nm0n42opsl
            ```

    2. Just as you did in exercise 4, set the S3 bucket beginning with `aws-logs-` to the `LOG_BUCKET` environment variable.

        ```bash
        export LOG_BUCKET=$(aws s3 ls | egrep -o aws-logs-.*)
        ```

### Challenge 3: Breakdown CloudWatch evidence_api Log Group Structure

### Challenge 4: Determine evidence_api Interaction Specifics

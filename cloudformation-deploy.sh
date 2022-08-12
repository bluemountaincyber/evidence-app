#!/bin/bash

# Create CloudFormation Stack
STACKID=$(aws cloudformation create-stack --stack-name evidence-app \
  --template-body file://cloudformation.yaml --region us-east-1 \
  --capabilities CAPABILITY_NAMED_IAM | jq -r '.StackId')
printf "\033[33mDeploying CloudFormation Stack...\033[0m\n"
while [[ $(aws cloudformation list-stacks --region us-east-1 | jq -r ".StackSummaries[] | select(.StackId == \""$STACKID"\") .StackStatus") != "CREATE_COMPLETE" ]]; do
  sleep 5
done

# Upload sample DynamoDB entry
printf "\033[33mCreating DynamoDB entry...\033[0m\n"
ITEM='{"FileName": {"S": "EICAR.txt"},"MD5Sum": {"S": "44d88612fea8a8f36de82e1278abb02f"},"SHA1Sum": {"S": "3395856ce81f2b7382dee72602f798b642f14140"}}'
aws dynamodb put-item --table-name evidence --item "$ITEM" --region us-east-1

# Push web code to webcode-*
printf "\033[33mAdding webcontent to S3...\033[0m\n"
mkdir webcode_final
cp webcode/* webcode_final/
CFURL=$(aws cloudfront list-distributions | jq -r '.DistributionList.Items[] | select(.Comment == "evidence Website") | "https://" + .DomainName')
sed -e "s@\${function_url}@$CFURL/api/@g" webcode_final/script.js.tpl > webcode_final/script.js
mv webcode_final/index.html.tpl webcode_final/index.html
rm webcode_final/script.js.tpl
WEBCODEBUCKET=$(aws s3 ls | egrep -o "webcode-[0-9]{12}")
aws s3 sync webcode_final s3://$WEBCODEBUCKET >/dev/null

# Display CloudFront URL
printf "\033[32mComplete! Evidence-App URL: \033[0m$CFURL\n"
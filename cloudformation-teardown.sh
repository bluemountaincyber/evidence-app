#!/bin/bash

# Remove webcode_final directory
printf "\033[33mRemoving webcode_final directory...\033[0m\n"
rm -rf webcode_final

# Empty awslogs-* bucket
printf "\033[33mEmptying S3 buckets (1 of 2)...\033[0m\n"
LOGSBUCKET=$(aws s3 ls | egrep -o "awslogs-[0-9]{12}")
aws s3 rm --recursive s3://$LOGSBUCKET >/dev/null

# Empty webcode-* bucket
WEBCODEBUCKET=$(aws s3 ls | egrep -o "webcode-[0-9]{12}")
aws s3 rm --recursive s3://$WEBCODEBUCKET >/dev/null

# Empty evidence-* bucket
EVIDENCEBUCKET=$(aws s3 ls | egrep -o "evidence-[0-9]{12}")
aws s3 rm --recursive s3://$EVIDENCEBUCKET >/dev/null

# Tear down CloudFormation Stack
printf "\033[33mTearing down CloudFormation Stack (1 of 2)...\033[0m\n"
aws cloudformation delete-stack --region us-east-1 \
  --stack-name evidence-app
while [[ $(aws cloudformation list-stacks --region us-east-1 --stack-status-filter DELETE_IN_PROGRESS | jq -r '.StackSummaries[] | select(.StackName == "evidence-app") | .StackStatus' 2>/dev/null) == "DELETE_IN_PROGRESS" ]]; do
  sleep 5
done

# Empty awslogs-* bucket (again)
printf "\033[33mEmptying S3 buckets (2 of 2)...\033[0m\n"
LOGSBUCKET=$(aws s3 ls | egrep -o "awslogs-[0-9]{12}")
aws s3 rm --recursive s3://$LOGSBUCKET >/dev/null

# Tear down CloudFormation Stack (again)
printf "\033[33mTearing down CloudFormation Stack (2 of 2)...\033[0m\n"
aws cloudformation delete-stack --region us-east-1 \
  --stack-name evidence-app
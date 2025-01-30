#!/bin/bash

# Check if both parameters are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <aws-profile> <certificate-arn>"
    exit 1
fi

AWS_PROFILE=$1
CERT_ARN=$2

echo "Using AWS Profile: $AWS_PROFILE"
echo "Checking resources using Certificate ARN: $CERT_ARN"

echo "-----------------------------------------"
echo "Checking API Gateway custom domains..."
aws apigateway get-domain-names --profile "$AWS_PROFILE" --query "items[?certificateArn=='$CERT_ARN']" --output table

echo "-----------------------------------------"
echo "Checking ALB/NLB listeners..."
aws elbv2 describe-listeners --profile "$AWS_PROFILE" --query "Listeners[?SslCertificateArn=='$CERT_ARN']" --output table

echo "-----------------------------------------"
echo "Checking CloudFront distributions..."
aws cloudfront list-distributions --profile "$AWS_PROFILE" --query "DistributionList.Items[?ViewerCertificate.ACMCertificateArn=='$CERT_ARN']" --output table

echo "-----------------------------------------"
echo "Checking Elastic Beanstalk environments..."
aws elasticbeanstalk describe-environments --profile "$AWS_PROFILE" --query "Environments[?OptionSettings[?Namespace=='aws:elbv2:listener:443' && Value=='$CERT_ARN']]" --output table

echo "-----------------------------------------"
echo "Check complete."
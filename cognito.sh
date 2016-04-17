#!/bin/bash


#region for everything else
REGION=ap-southeast-2

#Cognito
POOL_NAME=check1
#region for Cognito (limited region availability)
COGNITO_REGION=us-east-1

#S3
S3_BUCKET=cognitodemo.gsat.technology
BUCKET_POLICY=./bucket_policy.json
WEBSITE_CONFIG=./website_config.json


create_resources()
{
  aws cognito-identity create-identity-pool --region $COGNITO_REGION \
			 --identity-pool-name $POOL_NAME \
			 --no-allow-unauthenticated-identities

  aws s3 mb --region $REGION \
            s3://$S3_BUCKET

#Creates the S3 bucket policy (json file) for s3 bucket
  cat >$BUCKET_POLICY  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
    "Sid": "PublicReadForGetBucketObjects",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$S3_BUCKET/*"
  }
  ]
}
EOF

  #Allow public access to bucket
  aws s3api put-bucket-policy --region $REGION \
                              --bucket $S3_BUCKET \
                              --policy file://$BUCKET_POLICY

  #Creates the S3 website config for bucket 1
  cat >$WEBSITE_CONFIG <<EOF
{
  "IndexDocument": {
    "Suffix": "index.html"
  },
  "ErrorDocument": {
    "Key": "error.html"
  }
}
EOF

  #Enable website hosting on bucket 1
  aws s3api put-bucket-website --region $REGION \
                               --bucket $S3_BUCKET \
                               --website-configuration file://$WEBSITE_CONFIG

  aws s3 cp index.html s3://$S3_BUCKET
  aws s3 cp error.html s3://$S3_BUCKET

  #tidy up
  rm $BUCKET_POLICY
  rm $WEBSITE_CONFIG  
}


remove_resources()
{
  ID=$(aws cognito-identity list-identity-pools --region $COGNITO_REGION \
	                                     --max-results 60 \
                         	             --query "IdentityPools[?IdentityPoolName==\`$POOL_NAME\`].IdentityPoolId | [0]")

  #strip quotation marks
  ID="${ID%\"}"
  ID="${ID#\"}"
  
  aws cognito-identity delete-identity-pool --region $COGNITO_REGION \
                                            --identity-pool-id $ID

  aws s3 rb --region $REGION \
            s3://$S3_BUCKET \
            --force
      
 
}

case "$1" in

    create)
	create_resources
	exit 0
	;;
    remove)
	remove_resources
	exit 0
	;;
    *)
	echo "Usage: supply 'create' or 'remove'"
	exit 0
	;;
    esac

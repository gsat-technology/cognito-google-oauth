#!/bin/bash


#region for everything else
REGION=ap-southeast-2

#Cognito
POOL_NAME=check1
#region for Cognito (limited region availability)
COGNITO_REGION=us-east-1
COGNITO_AUTH_ROLE_NAME=$POOL_NAME-AuthRole
COGNITO_AUTH_ASSUME_ROLE_DOC=./cognito-auth-role-doc.json
COGNITO_AUTH_ROLE_POLICY=./cognito-auth-role-policy

#S3
S3_BUCKET=cognitodemo.gsat.technology
BUCKET_POLICY=./bucket_policy.json
WEBSITE_CONFIG=./website_config.json


create_resources()
{
  POOL_ID=$(aws cognito-identity create-identity-pool --region $COGNITO_REGION \
			 --identity-pool-name $POOL_NAME \
			 --no-allow-unauthenticated-identities --query IdentityPoolId)

  #strip quotation marks
  POOL_ID="${POOL_ID%\"}"
  POOL_ID="${POOL_ID#\"}"
    
  cat >$COGNITO_AUTH_ASSUME_ROLE_DOC <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "$POOL_ID"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF

  cat >$COGNITO_AUTH_ROLE_POLICY <<EOF
{
  "Version": "2012-10-17",
 "Statement": [
  {
    "Effect": "Allow",
    "Action": [
        "mobileanalytics:PutEvents",
	"cognito-sync:*",
	"cognito-identity:*"
	],
    "Resource": [
      "*"
      ]
  }
  ]
}
EOF
  
  #create the role for cognito authenticated users
  AUTH_ROLE_ARN=$(aws iam create-role --role-name $COGNITO_AUTH_ROLE_NAME \
                      --assume-role-policy-document file://$COGNITO_AUTH_ASSUME_ROLE_DOC --query Role.Arn)

  echo $AUTH_ROLE_ARN
  
  aws iam put-role-policy --role-name $COGNITO_AUTH_ROLE_NAME \
                          --policy-name $COGNITO_AUTH_ROLE_NAME-policy \
                          --policy-document file://$COGNITO_AUTH_ROLE_POLICY

  aws cognito-identity set-identity-pool-roles --region $COGNITO_REGION \
                                               --identity-pool-id $POOL_ID \
                                               --roles authenticated=$AUTH_ROLE_ARN
      
  
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
  rm $COGNITO_AUTH_ASSUME_ROLE_DOC
  rm $COGNITO_AUTH_ROLE_POLICY
}


remove_resources()
{
  POOL_ID=$(aws cognito-identity list-identity-pools --region $COGNITO_REGION \
	                                     --max-results 60 \
                         	             --query "IdentityPools[?IdentityPoolName==\`$POOL_NAME\`].IdentityPoolId | [0]")

  #strip quotation marks
  POOL_ID="${POOL_ID%\"}"
  POOL_ID="${POOL_ID#\"}"
  
  aws cognito-identity delete-identity-pool --region $COGNITO_REGION \
                                            --identity-pool-id $POOL_ID

  aws s3 rb --region $REGION \
            s3://$S3_BUCKET \
            --force

  aws iam delete-role-policy --role-name $COGNITO_AUTH_ROLE_NAME \
                             --policy-name $COGNITO_AUTH_ROLE_NAME-policy
  
  aws iam delete-role --role-name $COGNITO_AUTH_ROLE_NAME
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

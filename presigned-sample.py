import boto3
from botocore.exceptions import ClientError
import sys

if len(sys.argv) < 2:
    print("Usage: python presigned_generator.py <aws-profile> [<bucket-name> <prefix>]")
    exit(1)

# AWS profile passed as the first argument
aws_profile = sys.argv[1]

# Optional bucket name and prefix (if provided as additional arguments)
bucketName = sys.argv[2] if len(sys.argv) > 2 else "BUCKET-NAME"
bucketPrefix = sys.argv[3] if len(sys.argv) > 3 else "TABLENAME/ANS/DynamoDB/UNIQUEID/date/"

presignedExpirationInSeconds = 600

# Use the specified AWS profile
session = boto3.Session(profile_name=aws_profile)
s3_client = session.client('s3')

try:
    objects = s3_client.list_objects_v2(Bucket=bucketName, Prefix=bucketPrefix)
    presignedUrls = []
    for object in objects.get('Contents', []):
        objectName = object['Key']
        try:
            response = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': bucketName, 'Key': objectName},
                ExpiresIn=presignedExpirationInSeconds
            )
            presignedUrls.append(response)
        except ClientError as e:
            print(f"Error generating presigned URL for {objectName}: {e}")
            exit(1)

    print(presignedUrls)
except ClientError as e:
    print(f"Error listing objects in bucket: {e}")
    exit(1)
import boto3

# Use Amazon S3
s3 = boto3.resource('s3')
bucket = s3.Bucket('guilesdemo-boto3-bucket')
# Delete bucket
bucket.delete()

# Print out all bucket names
for bucket in s3.buckets.all():
    print(bucket.name)

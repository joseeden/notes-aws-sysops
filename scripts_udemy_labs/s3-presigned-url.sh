# s3-presigned-url.sh

#  these are the steps to generate a pre-signed URL for an object in your S3 bucket.

# first, configure the AWS CLI to generate a 
# signature version -sigv4 whihc allows the generated URL to be # compatible with KMS-encrypted object/s
aws configure set default.s3.signature_version s3v4

# second, generate the pre-signed url
# note that you can specify the timeout to 300 seconds or 5 mins
# you also NEED to specify the region where the bucket is
aws s3 presign s3://<insert-bucket-name>/<insert-filename> \
--expires-in <insert-time-in-seconds> \
--region <insert-region-here>


# Here is an example:
aws s3 presign s3://myfavoritefilm/index.html \
--expires-in 60 \
--region ap-southeast-1
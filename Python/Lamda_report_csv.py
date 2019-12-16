import boto3
import time

region = 'eu-west-1'
strCSV = "TagName, ResourceId, ResourceType, Value"
timeFile = time.strftime("%Y-%m-%d_%H%M%S")
file_lb = '/tmp/test.csv'
file_s3 = 'report_'+timeFile+'.csv'

boto3.setup_default_session(region_name=region)
def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)
    s3 = boto3.client('s3', region_name=region)

    bucket_name = 'tagcheckreport'
    tags = ec2.describe_tags()['Tags']

    with open(file_lb,"w+") as f1:
        f1.write(strCSV)
        f1.write('\n')
        for res in tags:
            if (((res['Key']) == 'env') and (res['Value'] != 'production')):
                l1 = list(res.values())
                s1=str(l1).lstrip('[')
                s1=s1.rstrip(']')
                f1.write(s1)
                f1.write('\n')

    s3.upload_file(file_lb, bucket_name, file_s3)


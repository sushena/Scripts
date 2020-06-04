import boto3
import json
import time
region='eu-west-1'
profile='sushena-cloud'

#Define Boto Clients
boto3.setup_default_session(profile_name=profile, region_name=region)
elb=boto3.client('elb', region_name=region)
alb = boto3.client('elbv2', region_name=region)

#Define Global Variables
ELB_LIST = []
INACTIVE_ALB_ARN = []
ACTIVE_ALB_ARN = []

# Check Unused Classic Load Balancers
response = elb.describe_load_balancers()['LoadBalancerDescriptions']
for i in response:
    target = i['Instances']
    print(target)
    if len(target) == 0:
        ELB_NAME = i['LoadBalancerName']
        ELB_LIST.append(ELB_NAME)

#print(ELB_LIST)	

# Delete Unused Classic Load Balancers
for lb in ELB_LIST:
    response = elb.delete_load_balancer(LoadBalancerName=lb)
    print(response)

# Check unused Network and Application/Network Load Balancers

# Get Load Balancer ARN
response = alb.describe_load_balancers()['LoadBalancers']
for i in response:
    lb_arn = i['LoadBalancerArn']
    tg = alb.describe_target_groups(LoadBalancerArn=lb_arn)
    
    for i in tg['TargetGroups']:
        tg_arn = i['TargetGroupArn']
        instance_check = alb.describe_target_health(TargetGroupArn=tg_arn)['TargetHealthDescriptions']
        if len(instance_check) == 0:
            INACTIVE_ALB_ARN.append(lb_arn)
        else:
            ACTIVE_ALB_ARN.append(lb_arn)

#Remove Common ARNs between 2 Lists

x = set(INACTIVE_ALB_ARN) & set(ACTIVE_ALB_ARN)
x = list(x)
for i in x:
    INACTIVE_ALB_ARN.remove(i)
#print(INACTIVE_ALB_ARN)

# Delete unused Application/Network Load Balancer
for lb in INACTIVE_ALB_ARN:
    if lb != x:
        tg = alb.describe_target_groups(LoadBalancerArn=lb)
        #Delete Target Group
        for i in tg['TargetGroups']:
            tg_arn = i['TargetGroupArn']
            #print(lb, tg_arn)
            alb.delete_load_balancer(LoadBalancerArn=lb)  
            time.sleep(30)
            alb.delete_target_group(TargetGroupArn=tg_arn)

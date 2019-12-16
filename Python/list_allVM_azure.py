#!/usr/lib/python3.7

from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient

TENANT_ID = 'e7457ffb-b317-402b-b281-c1d9aa7f6fc6'
CLIENT = '72222397-9a01-4003-a002-41155a6c5739'
KEY = 'NI3ovSDT:]AAGn17oP7dFerp]qY:B41r'

credentials = ServicePrincipalCredentials(
    client_id = CLIENT,
    secret = KEY,
    tenant = TENANT_ID
)

subscription_id = '85daaf46-467a-40d0-9fb4-84066ea9986f'
compute_client = ComputeManagementClient(credentials, subscription_id)

# List all de VMs in subscription
print('\nList VMs in subscription')
for vm in compute_client.virtual_machines.list_all():
    print("\tVM Name: {}".format(vm.name))

# List VM in resource group
#print('\nList VMs in resource group')
#for vm in compute_client.virtual_machines.list(GROUP_NAME):
#    print("\tVM: {}".format(vm.name))

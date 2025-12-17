#!/usr/bin/env python3
"""
AWS EC2 Dynamic Inventory for Ansible
Fetches EC2 instances from AWS and generates Ansible inventory
"""

import json
import boto3
import argparse

def get_ec2_instances():
    """Get all running EC2 instances with inventory-manager tag"""
    ec2 = boto3.client('ec2', region_name='us-east-1')
    
    inventory = {
        'ec2_instances': {
            'hosts': [],
            'vars': {
                'ansible_user': 'ec2-user',
                'ansible_ssh_common_args': '-o StrictHostKeyChecking=no',
                'ansible_python_interpreter': '/usr/bin/python3'
            }
        },
        '_meta': {
            'hostvars': {}
        }
    }
    
    try:
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Project', 'Values': ['inventory-manager']},
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                public_ip = instance.get('PublicIpAddress', '')
                private_ip = instance.get('PrivateIpAddress', '')
                
                if public_ip:
                    inventory['ec2_instances']['hosts'].append(public_ip)
                    inventory['_meta']['hostvars'][public_ip] = {
                        'ansible_host': public_ip,
                        'ec2_instance_id': instance_id,
                        'ec2_private_ip': private_ip,
                        'ec2_instance_type': instance.get('InstanceType', ''),
                        'ec2_availability_zone': instance.get('Placement', {}).get('AvailabilityZone', ''),
                        'ec2_tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    }
                    
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        return {}
    
    return inventory

def main():
    parser = argparse.ArgumentParser(description='AWS EC2 Dynamic Inventory')
    parser.add_argument('--list', action='store_true', help='List all instances')
    parser.add_argument('--host', help='Get variables for specific host')
    args = parser.parse_args()
    
    if args.list:
        inventory = get_ec2_instances()
        print(json.dumps(inventory, indent=2))
    elif args.host:
        # Return empty dict for specific host (vars are in _meta)
        print(json.dumps({}))
    else:
        print(json.dumps({}))

if __name__ == '__main__':
    main()

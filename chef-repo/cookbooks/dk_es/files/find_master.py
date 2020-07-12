import boto3
import yaml

def get_es_ip():
    session = boto3.session.Session(region_name='us-east-1')
    ec2 = session.resource('ec2')
    instances = ec2.instances.filter(Filters=[{'Name':'tag:Name', 'Values':['ES_POC']}])
    es_node_ip = []
    for instance in instances:
        if(instance.private_ip_address != None):
            es_node_ip.append(instance.private_ip_address)
    return es_node_ip

my_dict = {}
with open('/etc/elasticsearch/elasticsearch.yml','r') as f:
    my_dict = yaml.safe_load(f)
    ip_list = get_es_ip()
    print(ip_list)
    [str(i) for i in ip_list]
    my_dict['cluster.initial_master_nodes']= ip_list
    

with open('/etc/elasticsearch/elasticsearch.yml','w') as f:
    yaml.dump(my_dict, f )
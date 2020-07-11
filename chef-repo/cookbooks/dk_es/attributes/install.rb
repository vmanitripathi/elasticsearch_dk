default["dk_es"]["version"] = "7.x"
default["dk_es"]["clustername"] = "dk_es_Cluster"
default["dk_es"]["directory"]["conf"] = "/etc/elasticsearch/"
default["dk_es"]["directory"]["data"]="/var/lib/elasticsearch"
default["dk_es"]["directory"]["log"]="/var/log/elasticsearch"
default['dk_es']['user']['name']="elasticsearch"
default['dk_es']['user']['group']="elasticsearch"
default["dk_es"]["node"]["data"]="true"
default["dk_es"]["node"]["master"]="true"
default["dk_es"]["nodename"]="dk_es_node"
default["dk_es"]["jvm"]["xms"] = "128m"
default["dk_es"]["jvm"]["xmx"] = "512m"
default["dk_es"]["network"]["host"]="localhost"
default["dk_es"]["http"]["port"]=9200
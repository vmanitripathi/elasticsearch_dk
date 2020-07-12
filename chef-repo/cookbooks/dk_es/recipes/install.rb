#Installing elasticsearch software
es_install = bash "download_and_install_elasticsearch" do
    code <<-EOH
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    sudo apt-get install apt-transport-https
    echo "deb https://artifacts.elastic.co/packages/#{node["dk_es"]["version"]}/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-#{node["dk_es"]["version"]}.list
    sudo apt-get update && sudo apt-get install elasticsearch
      EOH
    not_if { ::File.exist?("/usr/share/elasticsearch/bin/" )}
  end
  Chef::Log.info "installed elasticsearch" if es_install.updated_by_last_action?


#Adding Elasticsearch YML
  template "#{node["dk_es"]["directory"]["conf"]}" + "/elasticsearch.yml" do
  source "elasticsearch.yml.erb"
  mode '0775'
  owner node['dk_es']['user']['name']
  group node['dk_es']['user']['group']['name']
  variables(
    clustername: "#{node["dk_es"]["clustername"]}", 
    nodename: "#{node["dk_es"]["nodename"]}-#{node["ipaddress"]}",
    nodemaster: node["dk_es"]["node"]["data"]['master'],
    nodedata: node["dk_es"]["node"]["data"],
    networkhost: node["ipaddress"],
    datadirectory:node["dk_es"]["directory"]["data"],
    logdirectory: node["dk_es"]["directory"]["log"],
    elasticsearchport: node["dk_es"]["http"]["port"],
    isSecurityEnabled: node["dk_es"]["security"]["enabled"],
    isHttpsEnabled: node["dk_es"]["security"]["http"]["ssl"]["enabled"],
    keystorepath: node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"],
    ec2tagvalue: node["dk_es"]["ec2"]["name"],
    initmasternode: node["ipaddress"],
    transportstorepath: node["dk_es"]["security"]["transport"]["ssl"]["kestore"]["path"],
    transportverificatiomode: node["dk_es"]["security"]["transport"]["ssl"]["verfication"]["mode"]
  )
end


#Adding Elasticsearch JVM settings
template "#{node["dk_es"]["directory"]["conf"]}" + "/jvm.options" do
  source "jvm.options.erb"
  mode '0775'
  owner node['dk_es']['user']['name']
  group node['dk_es']['user']['group']['name']
  variables(
    xms: "#{node["dk_es"]["jvm"]["xms"]}",
    xmx: "#{node["dk_es"]["jvm"]["xmx"]}", 
  )
end


#Adding Elasticsearch superuser (Authentication and Authorisation)
add_user = bash "adding es authorised user" do
    code <<-EOH
    /usr/share/elasticsearch/bin/elasticsearch-users useradd #{node["dk_es"]["auth"]["user"]["name"]} -p #{node["dk_es"]["auth"]["user"]["password"]} -r #{node["dk_es"]["auth"]["user"]["group"]}
      EOH
    #  not_if { ::File.exist?("/etc/elasticsearch/users" )}
  end
  Chef::Log.info "added es authorised user" if add_user.updated_by_last_action?


#Enabling support for Elasticsearch cluster
  install_discovery_plugin = bash "installing ec2 discovery plugin" do
    code <<-EOH
    yes Y | /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2
      EOH
  end
  Chef::Log.info "added ec2 discovery plugin" if install_discovery_plugin.updated_by_last_action?


# Enabling support for HTTPS communication with self signed certificate (Recommended using PKI)
cookbook_file "#{node["dk_es"]["directory"]["conf"]}#{node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"]}" do
	source "#{node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"]}"
	mode '0755'
	action :create
end


# Enabling support for intranode TLS communication using self signed certificate (Recommended using PKI)
cookbook_file "#{node["dk_es"]["directory"]["conf"]}#{node["dk_es"]["security"]["transport"]["ssl"]["kestore"]["path"]}" do
	source "#{node["dk_es"]["security"]["transport"]["ssl"]["kestore"]["path"]}"
	mode '0755'
	action :create
end


# Adding custom script to discover master nodes in runtime
template "#{node["dk_es"]["directory"]["conf"]}" + "/find_master.py" do
  source "find_master.py.erb"
  mode '0775'
  owner node['dk_es']['user']['name']
  group node['dk_es']['user']['group']['name']
  variables(
    ec2tagvalue: node["dk_es"]["ec2"]["name"], 
  )
end


# Updating elasticsearch YML file with master node ips
update_config = bash "updating elasticsearch master node ip" do
  code <<-EOH
    sudo apt-get install -y python3-pip
    pip3 install boto3
    python3 /etc/elasticsearch/find_master.py
  EOH
  #  not_if { ::File.exist?("/etc/elasticsearch/users" )}
end
Chef::Log.info "updated elasticsearch master node ip" if update_config.updated_by_last_action?


# Starting elasticsearch service
service 'elasticsearch' do
    action :start
  end
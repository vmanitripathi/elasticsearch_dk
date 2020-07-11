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
    networkhost: node["dk_es"]["network"]["host"],
    datadirectory:node["dk_es"]["directory"]["data"],
    logdirectory: node["dk_es"]["directory"]["log"],
    elasticsearchport: node["dk_es"]["http"]["port"],
    isSecurityEnabled: node["dk_es"]["security"]["enabled"],
    isHttpsEnabled: node["dk_es"]["security"]["http"]["ssl"]["enabled"],
    keystorepath: node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"]
  )
end


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

add_user = bash "adding es authorised user" do
    code <<-EOH
    /usr/share/elasticsearch/bin/elasticsearch-users useradd #{node["dk_es"]["auth"]["user"]["name"]} -p #{node["dk_es"]["auth"]["user"]["password"]} -r #{node["dk_es"]["auth"]["user"]["group"]}
      EOH
  end
  Chef::Log.info "Added elasticsearch superuser" if add_user.updated_by_last_action?

cookbook_file "#{node["dk_es"]["directory"]["conf"]}#{node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"]}" do
	source "#{node["dk_es"]["security"]["http"]["ssl"]["kestore"]["path"]}"
	mode '0755'
	action :create
end

service 'elasticsearch' do
    action :start
  end
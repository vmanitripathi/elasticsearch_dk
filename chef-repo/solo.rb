current_dir = File.dirname(__FILE__)
log_level :info
log_location "#{current_dir}/chef-solo.log"
cookbook_path ["#{current_dir}/cookbooks/"]
file_cache_path ["#{current_dir}/.chef/cache"]
environment_path ["#{current_dir}/environments"]
#
# Cookbook Name:: gitlab
# Recipe:: debian
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe	"git"

################################################################################
# Install rbenv & ruby_build
################################################################################
include_recipe	"rbenv::default"
include_recipe	"rbenv::ruby_build"

rbenv_ruby "1.9.3-p392" do
	global			"true"
end

rbenv_gem "bundler" do
	ruby_version	"1.9.3-p392"
end

################################################################################
# Install the required packages
################################################################################
%w{
	build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev
	libncurses5-dev libffi-dev curl git-core openssh-server redis-server postfix
	checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev
}.each do |pkg|
	package pkg do
		action :install
	end
end

################################################################################
# Setup System User
################################################################################
user node['gitlab']['gitlab_user'] do
	comment	"GitLab"
	home	node['gitlab']['gitlab_user_dir']
	system  true
end

directory node['gitlab']['gitlab_user_dir'] do
	owner node['gitlab']['gitlab_user']
	group node['gitlab']['gitlab_user']
	mode  0755
	action :create
end

################################################################################
# Setup Gitlab-Shell
################################################################################
git node['gitlab']['gitlab_shell']['install_dir'] do
	user node['gitlab']['gitlab_user']
	group node['gitlab']['gitlab_user']
	repository node['gitlab']['gitlab_shell']['repo_url']
	reference node['gitlab']['gitlab_shell']['reference']
	action :checkout
end

template "#{node['gitlab']['gitlab_shell']['install_dir']}/config.yml" do
	source	"gitlab-shell.yml.erb"
	user	node['gitlab']['gitlab_user']
	group	node['gitlab']['gitlab_user']
	mode	0644
end

execute "install gitlab-shell" do
	command	"./bin/install"
	cwd		node['gitlab']['gitlab_shell']['install_dir']
	user	node['gitlab']['gitlab_user']
end

################################################################################
# Setup Database
################################################################################
%w{mysql-server mysql-client libmysqlclient-dev}.each do |pkg|
	package pkg do
		action :install
	end
end

execute "execute_gitlab_db_setting_sql" do
	command "mysql --user=root < /home/git/gitlab_db_setting.sql"
	action :nothing
end

template "/home/git/gitlab_db_setting.sql" do
	source "gitlab.mysql.erb"
	notifies :run, "execute[execute_gitlab_db_setting_sql]", :immediately
end

# include_recipe "openssl"
# include_recipe "database::mysql"
# #include_recipe "mysql::server"
# mysql_connection_info = {:host => "localhost",
#                          :username => 'root',
#                          :password => 'Bizo-Do'}

# mysql_database_user "'gitlab'@'localhost'" do
# 	connection mysql_connection_info
# 	password 'password'
# 	action :create
# end

# database 'gitlabhq_production' do
# 	connection mysql_connection_info
# 	encoding `utf8`
# 	collation `utf8_unicode_ci`
# 	provider Chef::Provider::Database::Mysql
# 	action :create
# end

# #mysql_database 'gitlabhq_production' do
# #	connection mysql_connection_info
# #	sql "ALTER DATABASE 'gitlabhq_production' DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`"
# #	action :query
# #end

# database_user "'gitlab'@'localhost'" do
# 	connection mysql_connection_info
# 	password 'password'
# 	database_name 'gitlabhq_production'
# 	privileges [:select, :insert, :update, :delete, :create, :drop, :index]
# 	provider Chef::Provider::Database::MysqlUser
# 	action :grant
# end

################################################################################
# Setup Gitlabhq
################################################################################
git node['gitlab']['gitlabhq']['install_dir'] do
	user node['gitlab']['gitlab_user']
	group node['gitlab']['gitlab_user']
	repository node['gitlab']['gitlabhq']['repo_url']
	reference node['gitlab']['gitlabhq']['reference']
	action :checkout
end

# Make sure to change "localhost" to the fully-qualified domain name of your
# host serving GitLab where necessary
template "#{node['gitlab']['gitlabhq']['install_dir']}/config/gitlab.yml" do
	source "gitlab.yml.erb"
	owner node['gitlab']['gitlab_user']
end

# Make sure GitLab can write to the log/ and tmp/ directories
execute "fixup /log owner" do
	command "chown -R #{node['gitlab']['gitlab_user']} log/"
	cwd node['gitlab']['gitlabhq']['install_dir']
	only_if { Etc.getpwuid(File.stat("#{node['gitlab']['gitlabhq']['install_dir']}/log").uid).name != node['gitlab']['gitlab_user'] }
end

execute "fixup /tmp owner" do
	command "chown -R #{node['gitlab']['gitlab_user']} tmp/"
	cwd node['gitlab']['gitlabhq']['install_dir']
	only_if { Etc.getpwuid(File.stat("#{node['gitlab']['gitlabhq']['install_dir']}/tmp").uid).name != node['gitlab']['gitlab_user'] }
end

execute "fixup /log mode" do
	command "chmod -R u+rwX log/"
	cwd node['gitlab']['gitlabhq']['install_dir']
end

execute "fixup /tmp mode" do
	command "chmod -R u+rwX tmp/"
	cwd node['gitlab']['gitlabhq']['install_dir']
end

# Create directory for satellites
directory "#{node['gitlab']['gitlab_user_dir']}/gitlab-satellites" do
	owner node['gitlab']['gitlab_user']
	action :create
end

# Create directory for pids and make sure GitLab can write to it
directory "#{node['gitlab']['gitlabhq']['install_dir']}/tmp/pids/" do
	owner node['gitlab']['gitlab_user']
	action :create
end
execute "fixup /tmp/pids mode" do
	command "chmod -R u+rwX tmp/pids/"
	cwd node['gitlab']['gitlabhq']['install_dir']
end

# Setup Unicorn config
template "#{node['gitlab']['gitlabhq']['install_dir']}/config/unicorn.rb" do
	source "unicorn.rb.erb"
	owner node['gitlab']['gitlab_user']
end

# Setup database config(mysql)
template "#{node['gitlab']['gitlabhq']['install_dir']}/config/database.yml" do
	source "database.mysql.erb"
	owner node['gitlab']['gitlab_user']
end

# Install Gems
rbenv_gem "charlock_holmes" do
	ruby_version	"1.9.3-p392"
	version '0.6.9'
end
# For MySQL (note, the option says "without")
execute "Install Gems(for mysql)" do
	command "bundle install --deployment --without development test postgres"
	cwd node['gitlab']['gitlabhq']['install_dir']
	user node['gitlab']['gitlab_user']
end

# Initialise Database and Activate Advanced Features
execute "Initialise Database" do
	command "bundle exec rake gitlab:setup RAILS_ENV=production force=yes"
	cwd node['gitlab']['gitlabhq']['install_dir']
	user node['gitlab']['gitlab_user']
end

# Install Init Script
bash "setup_init_script" do
	code <<-EOH
		chmod +x /etc/init.d/gitlab
		update-rc.d gitlab defaults 21
	EOH
	action :nothing
end
template "/etc/init.d/gitlab" do
	source "gitlab.init.script.erb"
	notifies :run, "bash[setup_init_script]", :immediately
end

# Start Your GitLab Instance
service "gitlab" do
	action :start
end

################################################################################
# Setup Nginx
################################################################################
package "nginx" do
	action :install
end

# Site Configuration
bash "setup_nginx_config" do
	code <<-EOH
		ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab
	EOH
	action :nothing
end
template "/etc/nginx/sites-available/gitlab" do
	source "gitlab.nginx.erb"
	notifies :run, "bash[setup_nginx_config]", :immediately
end

service "nginx" do
	action :restart
end
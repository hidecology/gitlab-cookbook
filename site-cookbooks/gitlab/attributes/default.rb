#
# Cookbook Name:: gitlab
# Attributes:: default
#
# Author:: Hideki Nakamura
#
# Copyright 2013, Hideki Nakamura
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default[:gitlab][:gitlab_user]					= "git"
default[:gitlab][:gitlab_user_dir]				= "/home/#{node['gitlab']['gitlab_user']}"

default[:gitlab][:mysql][:db_root_password]		= "root_password"
default[:gitlab][:mysql][:db_user_name]			= "gitlab"
default[:gitlab][:mysql][:db_user_password]		= "user_password"
default[:gitlab][:mysql][:db_production_name]	= "gitlabhq_production"

default[:gitlab][:gitlab_shell][:install_dir]	= "#{node['gitlab']['gitlab_user_dir']}/gitlab-shell"
default[:gitlab][:gitlab_shell][:repo_url]		= "https://github.com/gitlabhq/gitlab-shell.git"
default[:gitlab][:gitlab_shell][:reference]		= "v1.1.0"
default[:gitlab][:gitlab_shell][:satellites_path]	= "#{node['gitlab']['gitlab_user_dir']}/gitlab-satellites"
default[:gitlab][:gitlab_shell][:repo_path]		= "#{node['gitlab']['gitlab_user_dir']}/repositories"

default[:gitlab][:gitlabhq][:install_dir]		= "#{node['gitlab']['gitlab_user_dir']}/gitlabhq"
default[:gitlab][:gitlabhq][:repo_url]			= "https://github.com/gitlabhq/gitlabhq.git"
default[:gitlab][:gitlabhq][:reference]			= "5-0-stable"
default[:gitlab][:gitlabhq][:ipaddress]			= "192.168.50.12"
default[:gitlab][:gitlabhq][:port_number]		= "80"
default[:gitlab][:gitlabhq][:svr_fqdn_name]		= "localhost"
default[:gitlab][:gitlabhq][:host_name]			= "#{node['gitlab']['gitlabhq']['svr_fqdn_name']}"
default[:gitlab][:gitlabhq][:email_address]		= "gitlab@localhost"
default[:gitlab][:gitlabhq][:use_subdirectory]	= false
default[:gitlab][:gitlabhq][:subdirectory]		= "gitlab"
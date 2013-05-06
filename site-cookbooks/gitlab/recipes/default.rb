#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
begin
	include_recipe	"gitlab::#{node["platform_family"]}"
rescue Chef::Exceptions::RecipeNotFound
	Chef::Log.warn "A GitLab recipe does not exist for platform_family: #{node['platform_family']}"
end

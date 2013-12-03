# Cookbook Name:: drop-the-base
# Recipe:: ohai_plugins
#
# Copyright 2013, ModCloth, Inc.
# Licensed MIT
#
# O HAI! I NEED TEH CPU AND TEH MEMORY STATZ!

include_recipe 'ohai'

# Even though there could be guard statements, an if statement is required.
# Without it, chef-client tries to look for the templates for Ubuntu and fails,
# even though they will not actually get used.
if node['platform'] == 'smartos'
  template "#{node['ohai']['plugin_path']}/cpu.rb" do
    source 'plugins/cpu.rb.erb'
    owner 'root'
    group 'root'
    mode 0755
  end

  template "#{node['ohai']['plugin_path']}/memory.rb" do
    source 'plugins/memory.rb.erb'
    owner 'root'
    group 'root'
    mode 0755
  end
end

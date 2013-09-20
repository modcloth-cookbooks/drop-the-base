#
# Cookbook Name:: drop-the-base
# Recipe:: default
#
# Copyright 2013, ModCloth Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

include_recipe 'users'
include_recipe 'drop-the-base::link_awk'
include_recipe 'drop-the-base::link_grep'
include_recipe 'drop-the-base::link_sudo'
include_recipe 'drop-the-base::ohai_plugins'

users_manage 'root' do
  group_id 0
  action :create
end

cookbook_file '/root/.profile' do
  source 'dot_profile'
end

cookbook_file '/root/.bashrc' do
  source 'dot_bashrc'
end

cookbook_file '/root/.bash_profile' do
  source 'dot_bash_profile'
end

case node['platform']
when 'smartos'
  service 'name-service-cache' do
    action :disable
    supports :enable => true, :disable => true, :restart => true
  end
when *%w(centos ubuntu)
  service 'ntpd' do
    supports [ :enable, :disable, :restart ]
    action [ :enable ]
  end

  cookbook_file '/etc/ntp.conf' do
    source 'ntp.conf'
    notifies :restart, resources(:service => 'ntpd'), :immediately
  end

  if node['platform'] == 'ubuntu'
    service 'apache2' do
      supports [ :start, :stop, :restart ]
      action [ :stop ]
    end
  end
end

# this recipe tests the `splunk_file_acl_posix` resource in Test Kitchen

package 'acl'

directory '/var/log/nginx'

splunk_file_acl_posix '/var/log/nginx'

splunk_file_acl_posix 'set_acl_nginx_user_splunk' do
  path '/var/log/nginx'
  scope :user
  mask 'w'
  action :create
end

splunk_file_acl_posix 'reset_acl_nginx_user_splunk' do
  path '/var/log/nginx'
  action [:remove, :create]
end

file '/var/log/messages' do
  action :create_if_missing
end

splunk_file_acl_posix '/var/log/messages' do
  scope :user
  mask 'r'
end

splunk_file_acl_posix '/var/log/messages' do
  scope :other
  mask ''
end

directory '/var/log/httpd'

group 'monitor' do
  members 'splunk'
  action :create
end

splunk_file_acl_posix 'set_acl_apache_group_monitor' do
  path '/var/log/httpd'
  default true
  scope :group
  subject 'monitor'
  mask nil
end

file '/var/log/httpd/access.log' do
  action :create_if_missing
end

file '/var/log/httpd/error.log' do
  action :create_if_missing
end

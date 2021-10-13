#
# Cookbook:: chef-splunk
# Attributes:: default
#
# Copyright:: 2014-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Assume default use case is a Universal Forwarder (client).
default['splunk']['accept_license'] = false
default['splunk']['is_server']      = false
default['splunk']['receiver_port']  = '9997'
default['splunk']['mgmt_port']      = '8089'
default['splunk']['web_port']       = '443'
default['splunk']['ratelimit_kilobytessec'] = '2048'
default['splunk']['disabled'] = false
default['splunk']['data_bag'] = 'vault'
default['splunk']['enable_boot_start_umask'] = '18'

default['splunk']['setup_auth'] = true
default['splunk']['service_name'] = 'splunk' # Splunk changes this to Splunkd or SplunkForwarder on systemd-managed servers
default['splunk']['startup_script'] = '/etc/init.d/splunk' # Splunk changes this to Splunkd or SplunkForwarder on systemd-managed servers
default['splunk']['user'] = {
  'username' => 'splunk',
  'comment' => 'Splunk Server',
  'home' => '/opt/splunkforwarder',
  'shell' => '/bin/bash',
  'uid' => 396,
}

default['splunk']['ssl_options'] = {
  'enable_ssl' => false,
  'data_bag' => 'vault',
  'data_bag_item' => 'splunk_certificates',
  'keyfile' => 'self-signed.example.com.key',
  'crtfile' => 'self-signed.example.com.crt',
}

default['splunk']['clustering'] = {
  'enabled' => false,
  'label' => 'cluster1',
  'num_sites' => 1,   # multisite is true if num_sites > 1
  'mgmt_uri' => "https://#{node['fqdn']}:8089",
  'mode' => 'master', # master|slave|searchhead
  'replication_port' => '9887',
  # Following two params only applicable if num_sites = 1 (multisite is false)
  'replication_factor' => 3,
  'search_factor' => 2,
  # Following three params only applicable if num_sites > 1 (multisite is true)
  'site' => 'site1',
  'site_replication_factor' => 'origin:2,total:3',
  'site_search_factor' => 'origin:1,total:2',
}

default['splunk']['shclustering'] = {
  'app_dir' => '/opt/splunk/etc/apps/0_autogen_shcluster_config',
  'captain_elected' => false,
  'deployer_url' => '',
  'enabled' => false,
  'label' => 'shcluster1',
  'mgmt_uri' => "https://#{node['fqdn']}:8089",
  'mode' => 'member', # member|captain|deployer
  'replication_factor' => 3,
  'replication_port' => 9900,
  'shcluster_members' => [],
}

# Add key value pairs to this to add configuration pairs to the output.conf file
# 'sslCertPath' => '$SPLUNK_HOME/etc/certs/cert.pem'
default['splunk']['outputs_conf'] = {
  'forwardedindex.0.whitelist' => '.*',
  'forwardedindex.1.blacklist' => '_.*',
  'forwardedindex.2.whitelist' => '_audit',
  'forwardedindex.filter.disable' => 'false',
}

# Add a host name if you need inputs.conf file to be configured
# Note: if host is empty the inputs.conf template will not be used.
default['splunk']['inputs_conf']['host'] = ''
default['splunk']['inputs_conf']['ports'] = []

# Add key-value pairs to each section for the deploymentclient.conf file
# Note: the file is removed if both [endpoint] and [targetUri] remain nil
default['splunk']['deploymentclient_conf'] = {
  'default' => {                # [default]
  },
  'client' => {                 # [deployment-client]
    'disabled' => 'false',
    'endpoint' => nil,
  },
  'server' => {                 # [target-broker:deploymentServer]
    'targetUri' => nil,
  }
}

# If the `is_server` attribute is set (via an overridable location
# like a role), then set particular attribute defaults based on the
# server, rather than Universal Forwarder. We hardcode the path
# because we don't want to rely on automagic.
default['splunk']['user']['home'] = '/opt/splunk' if node['splunk']['is_server']

default['splunk']['splunk_servers'] = []

default['splunk']['forwarder'] = {
  'url' => value_for_platform_family(
    %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
    'debian' => 'https://download.splunk.com/products/universalforwarder/releases/8.0.1/linux/splunkforwarder-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
  ),
  'version' => '8.0.1',
}

default['splunk']['server'] = {
  'runasroot' => true,
  'url' => value_for_platform_family(
    %w(rhel fedora suse amazon) => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-x86_64.rpm',
    'debian' => 'https://download.splunk.com/products/splunk/releases/8.0.1/linux/splunk-8.0.1-6db836e2fb9e-linux-2.6-amd64.deb'
  ),
  'version' => '8.0.1',
}

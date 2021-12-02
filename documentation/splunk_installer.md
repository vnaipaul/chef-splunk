[Back to resource list](../README.md#Resources)

# splunk_installer

The Splunk Enterprise and Splunk Universal Forwarder package installation is
the same, save for the name of the package and the URL to download.

This custom resource abstracts the package installation to a common baseline.

Any new platform installation support should be added by modifying the custom
resource as appropriate.

One goal of this custom resource is to have a single occurrence of a `package`
resource, using the appropriate 'local package file' provider per platform. For
example, on RHEL, we use `rpm` and on Debian we use `dpkg`.

Package files will be downloaded to Chef's file cache path (e.g.,
`file_cache_path` in `/etc/chef/client.rb`, `/var/chef/cache` by default).

## Actions

- `:run` - Install the splunk server or splunk universal forwarder
- `:remove` - Uninstall the splunk server or splunk universal forwarder
- `:upgrade` - Upgrade an existing splunk or splunk universal forwarder package

## Properties

| Name                | Type           | Default        | Description                                                                                                                         |
| ------------------- | -------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `package_name`      | String         | resource name  | Splunk package name, e.g. `splunk`, `splunkforwarder`                                                                               |
| `url`               | String         | `nil`          | Package URL                                                                                                                         |
| `version`           | String         | `nil`          | Splunk version, in the filename '`package_name`-`version`' of an existing locally cached package, if `url` is not given             |

## Examples

```ruby
splunk_installer 'splunkforwarder' do
  if upgrade_enabled?
    action :upgrade
    url node['splunk']['forwarder']['upgrade']['url']
    version node['splunk']['forwarder']['upgrade']['version']
  else
    url node['splunk']['forwarder']['url']
    version node['splunk']['forwarder']['version']
  end
  not_if { server? }
end
```

```ruby
splunk_installer 'splunk' do
  if upgrade_enabled?
    action :upgrade
    url node['splunk']['server']['upgrade']['url']
    version node['splunk']['server']['upgrade']['version']
  else
    url node['splunk']['server']['url']
    version node['splunk']['server']['version']
  end
  only_if { server? }
end
```

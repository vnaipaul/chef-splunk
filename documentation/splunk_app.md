[Back to resource list](../README.md#Resources)

# splunk_app

This resource will install a Splunk app or deployment app into the appropriate
locations on a Splunk Enterprise server.

Some custom "apps" simply install with a few files to override default Splunk
settings, which is desirable for maintaining settings after an upgrade of the
Splunk Enterprise server software.

Note that the restart of the Splunk service (by notifying the `service[splunk]`
resource) is left to the discretion of the caller--some app updates might not
require a service restart, for one.

## Actions

- `:install` - Installs a Splunk app or deployment app. This action will also update existing app config files, as needed
- `:remove` - Completely removes a Splunk app or deployment app from the Splunk Enterprise server

## Properties

| Name                 | Type            | Default                            | Description                                                                                                    |
| -------------------- | --------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `app_name`           | String          | resource name                      | Splunk application name                                                                                        |
| `app_dependencies`   | Array           | `[]`                               | Names of dependency packages, in the platform-native format, suitable for installation with `package`          |
| `app_dir`            | String          | `/opt/splunk/etc/apps/#{app_name}` | Application installation root, in which a `local` subdirectory is created automatically                        |
| `checksum`           | String          | `nil`                              | Checksum of `cookbook_file`, `local_file`, or `remote_file`--whichever one is given, as an application package |
| `cookbook`           | String          | `nil`                              | Cookbook against which to resolve `cookbook_file` and `templates`                                              |
| `cookbook_file`      | String          | `nil`                              | Cookbook-sourced application package, as a gzip'd tar archive, with a `.spl`, `.tgz`, or `.tar.gz` extension   |
| `files_mode`         | String, Integer | `nil`                              | Pass-through `files_mode` or `mode` for the installed application files                                        |
| `local_file`         | String          | `nil`                              | Node-sourced application package, as a gzip'd tar archive, with a `.spl`, `.tgz`, or `.tar.gz` extension       |
| `remote_directory`   | String          | `nil`                              | Cookbook-sourced directory (under `files`) [comprising an application](https://dev.splunk.com/enterprise/docs/developapps/createapps/appanatomy/#The-directory-structure-of-a-Splunk-app), named `app_name` for example |
| `remote_file`        | String          | `nil`                              | Remotely-sourced application package, as a gzip'd tar archive, with a `.spl`, `.tgz`, or `.tar.gz` extension   |
| `templates`          | Array, Hash     | `[]`                               | Either an array of template names (e.g. `['server.conf.erb']`) or a hash mapping destination paths (relative to `app_dir`) to (source) template names (e.g. `{ 'local/server.conf' => 'server.conf.erb' }` |
| `template_variables` | Hash            | `{ 'default' => {} }`              | Variables used in rendering of templates from `templates`, organized as a hash of hashes, with the top-level keys corresponding to template names from `templates` (except for the "default" variables, which apply to any template without its own) |

## Examples

Pass a unique Hash of variables/values into the `foo.erb` template, and the `default` Hash of variables/values into all other templates.

```ruby
splunk_app 'my app' do
  templates %w(foo.erb bar.erb server.conf.erb app.conf.erb outputs.conf.erb)
  template_variables {
    {
      'default' => { 'var1' => 'value1', 'var2' => 'value2' },
      'foo.erb' => { 'x' => 'snowflake template' }
    }
  }
end
```

Install and enable a deployment client configuration that overrides default Splunk Enterprise configurations

Given a wrapper cookbook *MyDeploymentClientBase* with the folder structure as below ...

```
MyDeploymentClientBase
    /templates
        /MyDeploymentClientBase
            deploymentclient.conf.erb
```

... render the template `deploymentclient.conf.erb` from the cookbook *MyDeploymentClientBase* as `/opt/splunk/etc/apps/MyDeploymentClientBase/local/deploymentclient.conf` with the following:

```ruby
splunk_app 'MyDeploymentClientBase' do
  templates ['deploymentclient.conf.erb']
  cookbook 'MyDeploymentClientBase'
  action :install
end
```

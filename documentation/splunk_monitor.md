[Back to resource list](../README.md#Resources)

# splunk_monitor

Adds a Splunk monitor stanza into a designated `inputs.conf` file in a "chef-erized" way using standard Chef DSL vernacular. This resource also validates supported monitors and index names as documented by Splunk.

Upon convergence, this resource will add a new stanza to the `inputs.conf` file, as needed, and modify or add new lines to the section based on properties given to the resource. If the current stanza in the `inputs.conf` file has any extra lines that are not listed as a valid property in this resource, those lines are automatically removed.

## Actions

- `:create` - Installs or updates a `monitor://` stanza in the `inputs.conf` file
- `:remove` - Removes a `monitor://` stanza from the `inputs.conf` file

## Properties

| Name                | Type           | Default        | Description                                                                                                                         |
| ------------------- | -------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `monitor_name`      | String         | resource name  | Path (file or directory) for the file monitor input stanza (without a "monitor://" input processor prefix)                          |
| `inputs_conf_path`  | String         | `nil`          | Path to the `inputs.conf` file                                                                                                      |
| `backup`            | Integer, False | `5`            | Number of backups of the `inputs.conf` file to keep, or `false` to keep none                                                        |
| `host`              | String         | `nil`          | Host on which `monitor_name` originates, or `nil` for the FQDN or IP address (see also `host_regex`, `host_segment`)                |
| `index`             | String         | `_internal`    | Index in which to store events from `monitor_name`                                                                                  |
| `sourcetype`        | String         | `nil`          | [Pretrained source type](https://docs.splunk.com/Documentation/Splunk/latest/Data/Listofpretrainedsourcetypes#Pretrained_source_types) or `nil` to let Splunk assign an [automatically recognized source type](https://docs.splunk.com/Documentation/Splunk/latest/Data/Listofpretrainedsourcetypes#Automatically_recognized_source_types) |
| `queue`             | String         | `parsingQueue` | Apply parsing rules (`parsingQueue`) to data from `monitor_name` first, or forward directly to the index (`indexQueue`)             |
| `_TCP_ROUTING`      | String         | `*`            | CSV list of _tcpout_ groups defined in `outputs.conf`, with `*` for the `defaultGroup` list in the _tcpout_ stanza                  |
| `host_regex`        | String         | `nil`          | Regex with a capture group for the host, to which `host` is set upon a successful match against the filename in `monitor_name`      |
| `host_segment`      | Integer        | `nil`          | 1-based index into the path segments of `monitor_name`, identifying a segment to which `host` is then set                           |
| `source`            | String         | `nil`          | Path which supplants `monitor_name` as `source::` (meant for use with the Windows-only `MonitorNoHandle` input processor)           |
| `crcSalt`           | String         | `<SOURCE>`     | CRC qualifier for uniqueness (file path, with `<SOURCE>`), to index files otherwise ignored on duplicate CRC                        |
| `ignoreOlderThan`   | String         | `nil`          | File modification time depth limit for indexing, as a number of (d)ay, (h)our, (m)inute, or (s)econd units, e.g. `7d`               |
| `followTail`        | Integer        | `0`            | Read a newly monitored file from the head (`0`) or tail (`1`)                                                                       |
| `whitelist`         | String         | `nil`          | Regex for filenames to monitor, in a directory given for `monitor_name`                                                             |
| `blacklist`         | String         | `nil`          | Regex for filenames to not monitor, in a directory given for `monitor_name`                                                         |
| `alwaysOpenFile`    | Integer        | `0`            | Check if a file has been indexed by opening it (`1`), or by relying on the file modification time (`0`) (meant for Windows)         |
| `recursive`         | True, False    | `true`         | Recurse over subdirectories, in a directory given for `monitor_name`                                                                |
| `time_before_close` | Integer        | `3`            | Seconds to wait for more writes before closing a file.  Raise if events are truncated, lower to reduce FD usage or indexing latency |
| `followSymlink`     | True, False    | `true`         | Follow symbolic links (`true`) or not (`false`), in a directory given for `monitor_name`                                            |

### See also

For additional information on the `inputs.conf` configuration settings exposed
by these properties (except for `monitor_name`, `inputs_conf_path`, `backup`),
refer to the Splunk documentation:

- [Configuration settings](https://docs.splunk.com/Documentation/Splunk/latest/Data/Monitorfilesanddirectorieswithinputs.conf#Configuration_settings)
- [Monitor syntax](https://docs.splunk.com/Documentation/Splunk/latest/Data/Monitorfilesanddirectorieswithinputs.conf#Monitor_syntax)

## Examples

```ruby
splunk_monitor '/var/log/httpd/access.log' do
  inputs_conf_path "#{splunk_dir}/etc/apps/SplunkUniversalForwarder/default/inputs.conf"
  sourcetype 'access_combined'
  index 'access_combined'
  only_if { ::File.exist?('/var/log/httpd/access.log') }
end
```

```ruby
splunk_monitor '/var/log/httpd/error.log' do
  inputs_conf_path "#{splunk_dir}/etc/apps/SplunkUniversalForwarder/default/inputs.conf"
  sourcetype 'apache_error'
  index 'alert-web_1'
  only_if { ::File.exist?('/var/log/httpd/error.log') }
end
```

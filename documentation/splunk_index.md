[Back to resource list](../README.md#Resources)

# splunk_index

This resource helps manage Splunk indexes that are defined in an `indexes.conf` file in a "chef way" using standard Chef DSL vernacular.

Upon convergence, this resource will add a new stanza to the `indexes.conf` file, as needed, and modify or add new lines to the section based on properties given to the resource. If the current stanza in the `indexes.conf` file has any extra lines that are not listed as a valid property in this resource, those lines are automatically removed.

## Actions

- `:create` - Installs or updates a stanza in the `indexes.conf` file
- `:remove` - Removes a stanza from the `indexes.conf` file

## Properties

| Name                | Type           | Default        | Description                                                                                                                         |
| ------------------- | -------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `index_name`        | String         | resource name  | (Virtual) Index name (or `default`, for global settings), by which the stanza is named.  Note the [naming requirements](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf#PER_INDEX_OPTIONS) imposed by Splunk:  *Index names must consist of only numbers, lowercase letters, underscores, and hyphens. They cannot begin with an underscore or hyphen, or contain the word "kvstore".* |
| `indexes_conf_path` | String         | `nil`          | Path to the `indexes.conf` file                                                                                                     |
| `backup`            | Integer, False | `5`            | Number of backups of the `indexes.conf` file to keep, or `false` to keep none                                                       |
| `options`           | Hash           | `{}`           | Index options, as key-value pairs from amongst the [Global Settings](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf#GLOBAL_SETTINGS), [Per Index Options](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf#PER_INDEX_OPTIONS), and (for virtual indexes) [Per Virtual Index Options](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf#PER_VIRTUAL_INDEX_OPTIONS), as comprehensively described in the Splunk documentation |

### See also

- [Splunk Configuration File Reference on indexes.conf](https://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf#indexes.conf)

## Examples

```ruby
splunk_index 'linux_messages_syslog' do
  indexes_conf_path "#{splunk_dir}/etc/apps/chef_splunk_indexes/local/indexes.conf"
  options(
    'homePath' => '$SPLUNK_DB/syslog/db',
    'coldPath' => '$SPLUNK_DB/syslog/colddb',
    'thawedPath' => '$SPLUNK_DB/splunk/indexer_thaweddata/syslog/thaweddb',
    'frozenTimePeriodInSecs' => 31536000,
    'repFactor' => 'auto'
  )
  only_if { ::File.exist?("#{splunk_dir}/etc/apps/chef_splunk_indexes/local/indexes.conf") }
end
```

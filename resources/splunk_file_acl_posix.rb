# Credit to https://github.com/ncerny/facl for inspiration

resource_name :splunk_file_acl_posix
provides :splunk_file_acl_posix, os: 'linux'
# If other splunk_file_acl_* implementations are introduced
# provides :splunk_file_acl, os: 'linux'

unified_mode true

property :path, String, name_property: true,
         callbacks: {
           'must be an absolute path' => ->(p) { ::File.absolute_path(p) == p },
         }

property :scope, Symbol, default: :user, desired_state: false,
         callbacks: {
           'must be either :user, :group, or :other' => lambda { |s|
             [:user, :group, :other].include?(s)
           },
         }

# For simplicity, and to focus on ACLs' sweet-spot (the named variety), base
# ACLs (empty subject, producing "user::r" for example) are not accommodated,
# beyond scope :other (which on a file, could counteract its parent directory's
# permissive default ACL like default:other::r-x)
#
# Note setfacl itself fails on an invalid user/group, so upfront validation
# can be minimal
#
property :subject, String, default: 'splunk', desired_state: false,
         callbacks: {
           'must be a valid user/group name' => ->(s) { s.match(/^\w{3,}/) },
         }

property :default, [true, false], default: false, desired_state: false

property :mask, [String, Integer], default: 'rX', desired_state: false

# Easier to compare/converge by ACL spec, rather than the component properties
# themselves (hence their desired_state: false)
#
property :spec, String, identity: true, skip_docs: true, # Internal-use only
         coerce: proc { |s| s.empty? ? nil : s }

SETFACL_MODIFY = 'setfacl -m'.freeze
SETFACL_REMOVE = 'setfacl -x'.freeze

default_action :create

load_current_value do |new_resource|
  cmd = shell_out("getfacl --no-effective #{new_resource.path}")

  current_value_does_not_exist! if cmd.error!

  new_default = new_resource.default ? 'default:' : ''

  spec_re = case new_resource.scope
            when :user  then /^#{new_default}user:#{new_resource.subject}:/
            when :group then /^#{new_default}group:#{new_resource.subject}:/
            when :other then /^#{new_default}other::/
            end

  spec cmd.stdout.lines.map(&:chomp).find { |x| x.match(spec_re) } if spec_re
end

action :create do
  new_resource.mask = coerce_mask(new_resource.mask)

  set_spec = derive_spec(
               new_resource.default,
               new_resource.scope,
               new_resource.subject,
               new_resource.mask
             )

  # "X" in the mask given to setfacl is returned as "x"
  # (or '-' if the file is not otherwise executable) by getfacl
  # Set using "X" but use "x" for converge_if_changed?
  #
  new_resource.spec = coerce_spec(set_spec, mask_X_to_x: true)

  include_recipe 'chef-splunk::user'

  if ::File.directory?(new_resource.path)
    converge_if_changed :spec do
      execute "splunk_create_dir_acl#{new_resource.path.gsub('/', '_')}" do
        command "#{SETFACL_MODIFY} '#{set_spec}' #{new_resource.path}"
        live_stream true
        action :run
      end

      # Departing from historical setfacl --default behaviour here for broader
      # usefullness ... apply the new default ACL to immediate files, but not
      # subdirectories (which could be addressed by separate calls) or lower
      #
      if new_resource.default
        ::Dir.new(new_resource.path)
             .entries
             .map { |e| ::File.join(new_resource.path, e) }
             .select { |f| ::File.file?(f) }
             .each do |log_file|
          execute "splunk_create_dirent_acl#{log_file.gsub('/', '_')}" do
            command "#{SETFACL_MODIFY} '#{set_spec.sub(/^default:/, '')}' #{log_file}"
            live_stream true
            action :run
          end
        end
      end
    end
  else
    converge_if_changed :spec do
      execute "splunk_create_file_acl#{new_resource.path.gsub('/', '_')}" do
        command "#{SETFACL_MODIFY} '#{set_spec}' #{new_resource.path}"
        live_stream true
        action :run
      end
    end
  end
end

action :remove do
  # Drop the mask for SETFACL_REMOVE, but not from current_resource.spec
  # or new_resource.spec, to be safe, in case of action [:remove, :create]
  #
  current_spec = coerce_spec(current_resource.spec, drop_mask: true)
  set_spec     = derive_spec(
                   new_resource.default,
                   new_resource.scope,
                   new_resource.subject
                 )

  if current_spec == set_spec
    if ::File.directory?(new_resource.path)
      execute "splunk_remove_dir_acl#{new_resource.path.gsub('/', '_')}" do
        command "#{SETFACL_REMOVE} '#{set_spec}' #{new_resource.path}"
        live_stream true
        action :run
      end

      if new_resource.default
        ::Dir.new(new_resource.path)
             .entries
             .map { |e| ::File.join(new_resource.path, e) }
             .select { |f| ::File.file?(f) }
             .each do |log_file|
          execute "splunk_remove_dirent_acl#{log_file.gsub('/', '_')}" do
            command "#{SETFACL_REMOVE} '#{set_spec.sub(/^default:/, '')}' #{log_file}"
            live_stream true
            action :run
          end
        end
      end
    else
      execute "splunk_remove_file_acl#{new_resource.path.gsub('/', '_')}" do
        command "#{SETFACL_REMOVE} '#{set_spec}' #{new_resource.path}"
        live_stream true
        action :run
      end
    end
  end
end

action_class do
  def coerce_mask(mask, mask_X_to_x: false)
    mask = mask.oct if mask.respond_to?('oct') && mask.oct > 0

    mask_coerced = ''

    if mask.respond_to?('index')
      mask_coerced << %w(r w).map { |c| mask.index(c).nil? ? '-' : c }.join
      mask_coerced << if mask_X_to_x
                        mask.match(/[Xx]/) ? 'x' : '-'
                      else
                        (%w(x X).find { |c| !mask.index(c).nil? } || '-')
                      end
    elsif mask.respond_to?('integer')
      mask_coerced << mask & 00400 ? 'r' : '-'
      mask_coerced << mask & 00020 ? 'w' : '-'
      mask_coerced << mask & 00001 ? 'x' : '-'
    else
      mask_coerced << '---'
    end

    mask_coerced
  end

  # Coerce abbreviated spec words, e.g.
  # d:user:USER:r -> default:user:USER:r--
  # u:USER:rX     ->         user:USER:r-X    (mask_X_to_x == false)
  # u:USER:rX     ->         user:USER:r-x    (mask_X_to_x == true)
  #
  def coerce_spec(spec, mask_X_to_x: false, drop_mask: false)
    s = spec.to_s.split(/:/)

    spec_coerced = []

    if s.length >= 3 && (s[0][0] == 'd' || s[0] == 'default')
      spec_coerced << 'default'
      s.shift
    end

    if s.length >= 2 && (!s[1].empty? || s[0][0] == 'o')
      spec_coerced << case s[0][0]
                      when 'u' then 'user'
                      when 'g' then 'group'
                      when 'o' then 'other'
                      end

      spec_coerced << s[1]

      if s.length == 3 && !drop_mask
        spec_coerced << coerce_mask(s[2], mask_X_to_x: mask_X_to_x)
      end
    end

    spec_coerced.join(':')
  end

  def derive_spec(default, scope, subject, mask = nil)
    [
      default ? 'default' : nil,
      case scope
      when :user  then ['user',  subject]
      when :group then ['group', subject]
      when :other then ['other', '']
      end,
      mask,
    ].compact.join(':')
  end
end

# installs scripts to help with the admin/consumption of Puppet
class utility_scripts (
  # Class parameters are populated from External(hiera)/Defaults/Fail

  # Scripts path prefix
  String $scripts_path_prefix,

  # Create any intermediate directory paths
  #Collection $required_paths,

  # Perl config
  String $perl_path,
  String $perl_lib_path,

  # Inventory scripts
  Boolean $inventory_scripts_install,
  Data $api_access_config_default,

  # Backup dumpfile location
  Boolean $master_backup_scripts_install,
  String $backup_destination_path,

  # Classifier
  String $puppet_classify_environment,
  String $roles_parent_group,

  # Script configs
  String $scripts_config_path              = "${scripts_path_prefix}/etc",

  # Script locations
  String $dump_classifier_path             = "${scripts_path_prefix}/sbin/dump_classifier",
  String $backup_master_to_fs              = "${scripts_path_prefix}/sbin/backup_puppet_master_db.sh",
  String $puppet_db_script_path            = "${scripts_path_prefix}/bin/puppet_db",
  String $puppet_list_nodes_script_path    = "${scripts_path_prefix}/sbin/puppet_list_nodes",
  String $puppet_rundeck_lists_script_path = "${scripts_path_prefix}/sbin/puppet_rundeck_lists",
  String $node_maint_script_path           = "${scripts_path_prefix}/sbin/puppet_node_maintenance",
  String $role_maint_script_path           = "${scripts_path_prefix}/sbin/puppet_role_maintenance",

  # Get the script paths for Perl scripts
  String $puppet_promote_script_path       = "${scripts_path_prefix}/bin/puppet_promote_code.sh",
  String $puppet_promote_config_path       = "${scripts_config_path}/puppet_promote_code_settings",

  # API access
  String $api_access_config_path           = "${scripts_config_path}/puppet_api_access.yaml",

  # CMDB inventory collection
  String $send_cmdb_data_path = "${scripts_path_prefix}/sbin/puppet_send_cmdb_data",
  Data $cmdb_import_mappings = {},
  Collection $cmdb_email_to = [],

  # Permissions of the files
  String $file_owner = 'root',
  String $file_group = 'root',
  String $data_mode = '0640',
  String $script_mode = '0755',
) {


  # Populate using deep lookup command as we want to merge data from multiple hiera configs
  $puppet_promote_config     = lookup('utility_scripts::puppet_promote_config', Data, deep, {})
  $api_access_config_hiera = lookup('utility_scripts::api_access_config', Data, deep, {})
  $api_access_config = $api_access_config_default + $api_access_config_hiera

  #file { $required_paths:
  #ensure => directory,
  #owner  => $::settings::user,
  #group  => $::settings::user,
  #mode   => '0775',
  #}

  # Config file for API access to the Puppet Master
  if !empty( $api_access_config ){
    file { $api_access_config_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $data_mode,
      content => inline_template('<%= @api_access_config.to_yaml %>'),
    }
  }

  ################################################################################
  #    ____             _
  #   | __ )  __ _  ___| | ___   _ _ __
  #   |  _ \ / _` |/ __| |/ / | | | '_ \
  #   | |_) | (_| | (__|   <| |_| | |_) |
  #   |____/ \__,_|\___|_|\_\\__,_| .__/
  #                               |_|
  ################################################################################

  if $master_backup_scripts_install {
    file { $dump_classifier_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp('utility_scripts/backup/dump_classifier.pl.epp', {
        api_access_config_path => $api_access_config_path,
        perl_path              => $perl_path,
        perl_lib_path          => $perl_lib_path,
        }
      ),
    }

    file { $backup_master_to_fs:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp('utility_scripts/backup/backup.sh.epp', {
        destination_path => $backup_destination_path,
        }
      ),
    }
  }

  ################################################################################
  #    _   _ _   _ _ _ _   _
  #   | | | | |_(_) (_) |_(_) ___  ___
  #   | | | | __| | | | __| |/ _ \/ __|
  #   | |_| | |_| | | | |_| |  __/\__ \
  #    \___/ \__|_|_|_|\__|_|\___||___/
  # 
  ################################################################################

  # Let's assume we want to install the scripts if the config is found in hiera
  if !empty($puppet_promote_config) {

    # Config file for Puppet promote code script
    file { $puppet_promote_config_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $data_mode,
      content => epp('utility_scripts/promote_code/puppet_promote_code_settings.epp', {
        config => $puppet_promote_config,
        }
      ),
    }

    file { $puppet_promote_script_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp( 'utility_scripts/promote_code/puppet_promote_code.sh.epp', {
        config_path => $puppet_promote_config_path,
        }
      ),
    }
  }

  # The rest of the scripts will be installed if asked to from Hiera
  if $inventory_scripts_install {
    file { $puppet_list_nodes_script_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp( 'utility_scripts/puppet_db.pl.epp', {
        api_access_config_path => $api_access_config_path,
        perl_path              => $perl_path,
        perl_lib_path          => $perl_lib_path,
        }
      ),
    }

    file { $puppet_db_script_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp( 'utility_scripts/puppet_db.pl.epp', {
        api_access_config_path => $api_access_config_path,
        perl_path              => $perl_path,
        perl_lib_path          => $perl_lib_path,
        }
      ),
    }

    # Role Maintenance script
    file { $role_maint_script_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp('utility_scripts/role_maintenance.pl.epp', {
        api_access_config_path      => $api_access_config_path,
        puppet_classify_environment => $puppet_classify_environment,
        roles_parent_group          => $roles_parent_group,
        perl_path                   => $perl_path,
        perl_lib_path               => $perl_lib_path,
      }),
    }

    # Puppet server to rundeck host list script
    file { $puppet_rundeck_lists_script_path:
      ensure  => file,
      owner   => $file_owner,
      group   => $file_group,
      mode    => $script_mode,
      content => epp('utility_scripts/puppet_db.pl.epp', {
        api_access_config_path => $api_access_config_path,
        perl_path              => $perl_path,
        perl_lib_path          => $perl_lib_path,
      }),
    }

    # CMDB inventory collection
    if !empty( $cmdb_email_to ) {
      file { $send_cmdb_data_path:
        ensure  => file,
        mode    => $script_mode,
        content => epp('utility_scripts/send_cmdb_data.pl.epp', {
          api_access_config_path => $api_access_config_path,
          cmdb_import_mappings   => $cmdb_import_mappings,
          cmdb_email_to          => $cmdb_email_to,
          perl_path              => $perl_path,
          perl_lib_path          => $perl_lib_path,
        }),
      }
    }

  }

}

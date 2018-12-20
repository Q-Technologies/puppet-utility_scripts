# installs scripts to help with the admin/consumption of Puppet
class utility_scripts (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Boolean $install                                     = false,

  # Generic variables
  String $puppet_service                                              = 'pe-puppetserver',

  # Manage custom oid mappings
  Data $oid_mapping                                                   = {},

  # Perl config
  String $perl_path                                                   = '/usr/bin/perl',
  Boolean $perl_mods_install                                          = true,
  String $perl_mods_path                                              = '/usr/local/lib/perl5',

  # API access
  String $api_access_config_path                                      = '/usr/local/etc/puppet_api_access.yaml',
  Data $api_access_config                                             = {},

  # Backup dumpfile location
  String $backup_destination_path                                     = '/var/backup/puppetlabs',

  # Script locations
  String $scripts_path                                                = '/usr/local/sbin',
  String $dump_classifier_path                                        = '/usr/local/bin/dump_classifier.pl',
  String $backup_master_to_fs                                        = '/usr/local/bin/backup_puppet_master_db.sh',
  String $puppet_db_script_path                                       = '/usr/local/bin/puppet_db.pl',

  # Get the script paths for Perl scripts
  Boolean $puppet_promote_install                                     = true,
  String $puppet_promote_script_path                                  = '',
  String $puppet_promote_config_path                                  = '',

) {

  if $install {

  # Config file for API access to the Puppet Master
  file { 'api_access_config_path':
    ensure  => file,
    path    => $api_access_config_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => inline_template('<%= @api_access_config.to_yaml %>'),
  }

  ################################################################################
  #    ____             _
  #   | __ )  __ _  ___| | ___   _ _ __
  #   |  _ \ / _` |/ __| |/ / | | | '_ \
  #   | |_) | (_| | (__|   <| |_| | |_) |
  #   |____/ \__,_|\___|_|\_\\__,_| .__/
  #                               |_|
  ################################################################################

  file { $dump_classifier_path:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => epp('utility_scripts/backup/dump_classifier.pl.epp', { api_access_config_path =>  $api_access_config_path }),
  }

  file { $backup_master_to_fs:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => epp('utility_scripts/backup/backup.sh.epp', { destination_path => $backup_destination_path }),
  }

  ################################################################################
  #    _   _ _   _ _ _ _   _
  #   | | | | |_(_) (_) |_(_) ___  ___
  #   | | | | __| | | | __| |/ _ \/ __|
  #   | |_| | |_| | | | |_| |  __/\__ \
  #    \___/ \__|_|_|_|\__|_|\___||___/
  # 
  ################################################################################

  # Location to install the script configuration files - this is hardcoded in the scripts so cannot be overridden
  $scripts_config_path = '/usr/local/etc'

  # Need to make sure the parameters have decent defaults and the correct hiera is being sourced
  # We need to exit this class cleanly when data not set, but notify the admin something is not right
  if ( empty(puppet_perl_config) and $perl_mods_install ) or
    ( empty(puppet_promote_config) and $puppet_promote_install )
    {
    notify { 'Data not set correctly!  Make sure the hiera data is populated':
    }
  } else {

    # Populate using deep lookup command as we want to merge data from multiple hiera configs
    $puppet_perl_config        = lookup('utility_scripts::puppet_perl_config', Data, deep, {})
    $puppet_promote_config     = lookup('utility_scripts::puppet_promote_config', Data, deep, {})

    # Config file for Puppet promote code script
    file { 'puppet_promote_config':
      ensure  => file,
      path    => "${scripts_config_path}/puppet_promote_code_settings",
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => epp('utility_scripts/promote_code/puppet_promote_code_settings.epp', { config => $puppet_promote_config } ),
    }

    file { 'puppet_promote_code.sh':
      ensure  => file,
      path    => "${scripts_path}/puppet_promote_code.sh",
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => epp( 'utility_scripts/promote_code/puppet_promote_code.sh.epp', {
                        config_path => "${scripts_config_path}/puppet_promote_code_settings",
                      } ),
    }

    file { 'puppet_perl_config':
      ensure  => file,
      path    => "${scripts_config_path}/puppet_perl_config_settings.yaml",
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => inline_template('<%= @puppet_perl_config.to_yaml %>'),
    }

    file { 'puppet_list_nodes.pl':
      ensure  => file,
      path    => "${scripts_path}/puppet_list_nodes.pl",
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => epp( 'utility_scripts/puppet_list_nodes.pl.epp', {
                      config_path => "${scripts_config_path}/puppet_perl_config_settings.yaml",
                      } ),
    }

  }
  }

}

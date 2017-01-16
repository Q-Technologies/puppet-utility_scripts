# maintains local scripts on the Puppet master
class master_utilities (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Collection $required_paths             = [],

  # Whether to actually install anything
  Boolean $perl_mods_install             = true,
  String $perl_mods_path                 = '/usr/local/lib/perl5',
  String $scripts_path                   = '/usr/local/sbin',
  Boolean $baseline_selection_install    = true,
  Boolean $puppet_promote_install        = true,

  # Get the script paths for Perl scripts
  String $baseline_selection_script_path = '',
  String $baseline_selection_config_path = '',

  # Get the script paths for Perl scripts
  String $puppet_promote_script_path     = '',
  String $puppet_promote_config_path     = '',

) {
  # Location to install the script configuration files - this is hardcoded in the scripts so cannot be overridden
  $scripts_config_path = '/usr/local/etc'

  # Need to make sure the parameters have decent defaults and the correct hiera is being sourced
  # We need to exit this class cleanly when data not set, but notify the admin something is not right
  if ( empty(puppet_perl_config) and $perl_mods_install ) or 
     ( empty(baseline_selection_config) and $baseline_selection_install ) or
     ( empty(puppet_promote_config) and $puppet_promote_install )
     {
    notify { 'Data not set correctly!  Make sure the hiera data is populated': 
    }
  } else {

    # Make sure all the parent directories exist for the files we are managing in this modules
    file { $required_paths:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    # Populate using hiera_hash command as we want to merge data from multiple hiera configs
    $puppet_perl_config        = hiera_hash('master_utilities::puppet_perl_config', {})
    $baseline_selection_config = hiera_hash('master_utilities::baseline_selection_config', {})
    $puppet_promote_config     = hiera_hash('master_utilities::puppet_promote_config', {})

    # Config file for Puppet promote code script
    file { 'puppet_promote_config':
      ensure  => file,
      path    => "${scripts_config_path}/puppet_promote_code_settings",
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => epp('master_utilities/puppet_promote_code_settings.epp', { config => $puppet_promote_config } ),
    }

    # Config file for Baseline Selection script
    $configs = [ 'baseline_selection_config', 'puppet_perl_config' ];
    $configs.each | $config | {
      file { "master util config: ${config}":
        ensure  => file,
        path    => "${scripts_config_path}/${config}.json",
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => inline_template("<%= @${config}.to_json %>"),
      }
    }

    # install included scripts
    $scripts = [ 'puppet_baseline_selection.pl', 'puppet_list_nodes.pl', 'puppet_promote_code.sh' ];
    $scripts.each | $script | {
      file { "master util script: ${script}":
        ensure  => file,
        path    => "${scripts_path}/${script}",
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => "puppet:///modules/master_utilities/${script}"
      }
    }

    # install included Perl Modules
    $perl_mods = [ 'Puppet/DB.pm', 'Puppet/Classify.pm', 'Puppet/Cert.pm', 'String/ShortHostname.pm', 'Log/MixedColor.pm' ];
    $perl_mods.each | $perl_mod | {
      file { "master util perl module: ${perl_mod}":
        ensure  => file,
        path    => "${perl_mods_path}/${perl_mod}",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => file("master_utilities/${perl_mod}"),
      }
    }

  }

}

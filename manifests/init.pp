# maintains local scripts on the Puppet master
class master_utilities (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  Collection $required_paths             = [],

  # Whether to actually install anything
  Boolean $perl_mods_install             = true,
  String $perl_mods_path                 = '/usr/local/lib/perl5',
  Boolean $baseline_selection_install    = true,
  Boolean $puppet_promote_install        = true,

  # Get the script paths for Perl scripts
  String $baseline_selection_script_path = '',
  String $baseline_selection_config_path = '',

  # Get the script paths for Perl scripts
  String $puppet_promote_script_path     = '',
  String $puppet_promote_config_path     = '',

) {

  # Need to make sure the parameters have decent defaults and the correct hiera is being sourced
  # We need to exit this class cleanly when data not set, but notify the admin something is not right
  if $baseline_selection_script_path == '' or 
     $baseline_selection_config_path == '' or
     $puppet_promote_script_path     == '' or
     $puppet_promote_config_path     == ''
     {
    notify { 'Data not set correctly!  Make sure the hiera data is populated': }
  } else {

    # Populate using hiera_hash command as we want to merge data from multiple hiera configs
    $baseline_selection_config = hiera_hash('master_utilities::baseline_selection_config', {})
    $puppet_promote_config     = hiera_hash('master_utilities::puppet_promote_config', {})

    # Make sure all the parent directories exist for the files we are managing in this modules
    file { $required_paths:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    # Puppet promote code script
    file { 'puppet_promote':
      ensure  => file,
      path    => $puppet_promote_script_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => 'puppet:///modules/master_utilities/puppet_promote_code.sh'
    }

    # Config file for Puppet promote code script
    file { 'puppet_promote_config':
      ensure  => file,
      path    => $puppet_promote_config_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => epp('master_utilities/puppet_promote_code_settings.epp', { config => $puppet_promote_config } ),
    }

    # Baseline Selection script
    file { 'baseline_selection':
      ensure  => file,
      path    => $baseline_selection_script_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      content => file('master_utilities/baseline_selection.pl')
    }

    # Config file for Baseline Selection script
    file { 'baseline_selection_config':
      ensure  => file,
      path    => $baseline_selection_config_path,
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => inline_template("<%= @baseline_selection_config.to_json %>"),
    }

    # Included Perl Modules
    $perl_mods = [ 'Puppet/DB.pm', 'Puppet/Classify.pm', 'Puppet/Cert.pm', 'String/ShortHostname.pm' ];
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

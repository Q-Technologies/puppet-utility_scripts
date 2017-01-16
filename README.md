# puppet-master_utilities
Puppet module that provides some Puppet Master utility scripts.

## Features

### Baseline Selection
The Baseline selection script provides a command line interface to move groups of machines into and out of
OS baseline groups. See https://github.com/Q-Technologies/lobm for more information about how to create an OS baseline.

#### Usage
1. Set up a certificate that can be used to interact with the Node Classifier.  Follow the documentation here: https://docs.puppet.com/pe/latest/nc_forming_requests.html#whitelisted-certificate (Note: I needed to do a full restart rather than just a reload for the certificate to be recognized).  Specify the name of the certificate in the hiera data as per the Configuration Instructions.

1. Create the parent group in Enterprise Console. You need to make sure the repo_class you have specified in hiera is in the environment you specified:
    ```
    puppet_baseline_selection.pl -a init_baseline
    ```
1. Add a group matching an OS Baseline you have already created
    ```
    puppet_baseline_selection.pl -a add_group -g 2017-01-13
    ```
1. Pin nodes to this group so they receive the correct repositories
    ```
    puppet_baseline_selection.pl -a add_to_group -g 2017-01-13 dev015.localdomain
    ```
More options are available.  See `puppet_baseline_selection.pl -h` for more details.

### Code Promotion
This is a bash script that facilitates a process whereby change records can be recorded as part of promoting code.  At
 the moment it is passive, but it can be extended to reach into the service management tool to ensure the 
change is valid at the time it is being performed.

#### Usage
T.B.A

## Instructions

### Installation
Install this module how you would normally include a Puppet module.

### Configuration
Set the following hiera data in context of your Puppet Master:

Paths required for the subsequent scripts - they may or may not be needed depending on
what has been defined elsewhere in the puppet code.
```
master_utilities::required_paths: 
  - /usr/local/sbin
  - /usr/local/lib
  - /usr/local/lib/perl5
  - /usr/local/lib/perl5/Puppet
```

Perl modules deployed as part of puppet-master_utilities.  The first item
determines whether the files should be installed or not (defaults to true).
```
master_utilities::perl_mods_install: true
master_utilities::puppet_db_perlmod_path: /usr/local/lib/perl5/Puppet/DB.pm
master_utilities::puppet_classify_perlmod_path: /usr/local/lib/perl5/Puppet/Classify.pm
master_utilities::puppet_cert_perlmod_path: /usr/local/lib/perl5/Puppet/Cert.pm
```

Perl scripts deployed as part of puppet-master_utilities.  Need to set the locallibs below 
to the location of the perl modules above.  The first item determines whether the files 
should be installed or not (defaults to true).
```
master_utilities::baseline_selection_install: true
master_utilities::baseline_selection_script_path: /usr/local/sbin/puppet_baseline_selection.pl
master_utilities::baseline_selection_config_path: /usr/local/etc/baseline_selection_config.json
master_utilities::baseline_selection_config:
  puppet_classify_port: 4433
  puppet_classify_cert: api_access
  puppetdb_host: localhost 
  puppetdb_port: 8080
  locallibs: [ /usr/local/lib/perl5 ]
  def_baseline_date: '2017-01-13'
  repo_class: profile::repos
  environment: dev
  baseline_group_prefix: Baseline
  baseline_match_nodes: 
    - 'and'
    - [ '~', ['facts','os', 'release', 'major'], '^[67]$']
    - [ '=', ['facts','os', 'family'], 'RedHat']
```
The baseline_selection_config data will be merged across hiera, so if your code is servicing multiple 
Puppet Masters, you can put master specific information in a hiera node file also:
```
master_utilities::baseline_selection_config:
  puppet_classify_host: dev015.localdomain
```

Shell scripts deployed as part of puppet-master_utilities.  This assumes the repo account
has the SSH keys of the admins using this script installed in the git repo. The first item
determines whether the files should be installed or not (defaults to true).
```
master_utilities::puppet_promote_install: true
master_utilities::puppet_promote_script_path: /usr/local/sbin/puppet_promote_code.sh
master_utilities::puppet_promote_config_path: /usr/local/etc/puppet_promote_code_settings
master_utilities::puppet_promote_config:
  repo_account: test1
  repo_key_file_path: /tmp/test1_id
  repo_server: gitblit
  repo_port: 7999
  repo_path: /pup/control-repo
  repo_working_directory: /tmp
```
#### Require Perl Modules
The following perl modules are required for the scripts to work. For Centos, they are available from base and EPEL.
You can use your preferred way to pull them onto your Puppet master.  I like to use: 
https://github.com/Q-Technologies/puppet-packages, which would use the following hiera data
```
packages::add:
  RedHat:
    - perl-Moose
    - perl-Class-Load
    - perl-Data-OptList
    - perl-Params-Util
    - perl-Sub-Install
    - perl-Module-Implementation
    - perl-Module-Runtime
    - perl-Try-Tiny
    - perl-Class-Load
    - perl-Class-Load-XS
    - perl-Package-DeprecationManager
    - perl-MRO-Compat
    - perl-Sub-Name
    - perl-Eval-Closure
    - perl-Sub-Exporter
    - perl-Devel-GlobalDestruction
    - perl-Sub-Exporter-Progressive
    - perl-Package-Stash
```

## Issues
This module is using hiera data that is embedded in the module rather than using a params class.  This may not play nicely with other modules using the same technique unless you are using hiera 3.0.6 and above (PE 2015.3.2+).

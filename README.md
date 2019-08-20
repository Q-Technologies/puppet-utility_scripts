# puppet-utility_scripts
Puppet module that provides some utility scripts and files.

<!-- vim-markdown-toc GFM -->

* [Features](#features)
  * [Puppet Reports](#puppet-reports)
  * [Puppet Facts](#puppet-facts)
  * [Puppet Classifier Groups](#puppet-classifier-groups)
  * [Inactive nodes](#inactive-nodes)
  * [List nodes in Puppet](#list-nodes-in-puppet)
  * [Rundeck Lists](#rundeck-lists)
  * [Code Promotion](#code-promotion)
* [Instructions](#instructions)
  * [Installation](#installation)
  * [Configuration](#configuration)
    * [Require Perl Modules](#require-perl-modules)
* [Issues](#issues)

<!-- vim-markdown-toc -->

## Features

### Puppet Reports

Script to easily summarise recent puppet runs or jobs.  Show output across multiple nodes allowing you to 
narrow down to just what you want to see.

```
./puppet_reports [-s status] [-v] [-d] [-g|-j] node|group|job

	-j get reports for all nodes in a puppet job
	-g get reports for all nodes in a puppet group
	-s match status (provide a regex string with 'failure', 'success' or 'noop')
	-r match resource type (provide a regex string)
	-n match name of resource (provide a regex string)
	-m match message (provide a regex string)
	-t show the time the puppet run ended
	-e show the puppet environment used for the puppet run
	-v show additional messages
	-d show potentially destructive changes only (removals)
```

### Puppet Facts
This script outputs facts from the PuppetDB according to query criteria.  The advantage over the Puppet provided tools is it
provides more options for output, makes the queries simpler and combines information from the classifier.

```
./puppet_facts [-f json|yaml|csv ] -a action [group|fact name|node] [fact value]

The following actions are supported:
		all
		in_group
		match_fact
		match_host

	'group' is a Puppet Enterprise Console group
	'fact name' is a PuppetDB fact in dot notation
	'node' is a Puppet node - i.e. clientcert
	'fact value' is required when matching a fact

	-r restrict the fact fields to display ( supply a comma seperated list)
	-f data format to output (defaults to yaml, can also be csv or json)

	-v is to show verbose messages
	-d is to show debug messages
```

### Puppet Classifier Groups
Script to make it easier to get/set information from the Puppet classifier.

```
./puppet_groups [-f csv|yaml|json] -a action [group name]


	-a the action to perform

The following actions are supported:
		add_agent_env
		delete_group
		list_groups
		get_group_id
	-f data format to output (defaults to json) (when listing groups)
When listing the groups the 'group name' will be treated as a sub string
```

### Inactive nodes
Script to list nodes that are not reporting according to the time you specify.
```
./puppet_inactive_nodes [-a age]

	-a age of last report (default 24 hours)
```

### List nodes in Puppet
Simple script to just list nodes according to criteria.

```
./puppet_list_nodes -a action [group|fact name|node] [fact value]

The following actions are supported:
		all
		in_group
		match_fact
		match_host

	'group' is a Puppet Enterprise Console group
	'fact name' is a PuppetDB fact in dot notation
	'node' is a Puppet node - i.e. clientcert
	'fact value' is required when matching a fact

	-v is to show verbose messages
	-d is to show debug messages
```

### Rundeck Lists
Script to produce rundeck node lists from PuppetDB.
```
./puppet_rundeck_lists -a action [group|fact name|node] [fact value]

The following actions are supported:
		all
		in_group
		match_fact
		match_host

	'group' is a Puppet Enterprise Console group
	'fact name' is a PuppetDB fact in dot notation
	'node' is a Puppet node - i.e. clientcert
	'fact value' is required when matching a fact

	-f data format to output (defaults to yaml)

	-v is to show verbose messages
	-d is to show debug messages

-u the user to use for SSH access for Rundeck
```

### Code Promotion
This is a bash script that facilitates a process whereby change records can be recorded as part of promoting code.  At
 the moment it is passive, but it can be extended to reach into the service management tool to ensure the 
change is valid at the time it is being performed.

## Instructions

### Installation
Install this module how you would normally include a Puppet module.

### Configuration

#### Require Perl Modules
The following perl modules are required for the scripts to work. For Centos, they are available from base and EPEL.
You can use your preferred way to pull them onto your Puppet master.  I like to use: 
https://github.com/Q-Technologies/puppet-packages, which would use the following hiera data.  At the time of writing, this list may be incomplete.  
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

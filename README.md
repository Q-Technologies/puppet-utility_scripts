# puppet-utility_scripts
Puppet module that provides some utility scripts and files.

<!-- vim-markdown-toc GFM -->

* [Features](#features)
  * [Code Promotion](#code-promotion)
    * [Usage](#usage)
* [Instructions](#instructions)
  * [Installation](#installation)
  * [Configuration](#configuration)
    * [Require Perl Modules](#require-perl-modules)
* [Issues](#issues)

<!-- vim-markdown-toc -->

## Features

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

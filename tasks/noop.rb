#!/opt/puppetlabs/puppet/bin/ruby

# Script to toggle NOOP for Puppet

# It has 3 modes:
#   Turn on
#   Turn off
#   Revert to the previous setting prior to the last on/off

require 'facter'
require 'puppet'
require 'puppet/util/inifile'

if Facter.value(:kernel) == 'windows'
  PUPPET_CONF = 'C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf'.freeze
  NOOP_SAVE = 'C:\ProgramData\PuppetLabs\puppet\etc\.noop.conf'.freeze
else
  PUPPET_CONF = '/etc/puppetlabs/puppet/puppet.conf'.freeze
  NOOP_SAVE = '/etc/puppetlabs/puppet/.noop.conf'.freeze
end

FILE = Puppet::Util::IniConfig::File.new
FILE.read(PUPPET_CONF)

def restore_previous_setting
  puts 'Seeing if there was a previous noop setting'
  if File.exist?(NOOP_SAVE)
    noop = File.read(NOOP_SAVE).chomp
  end
  if noop =~ %r{^(0|1|true|false)$}i
    puts "It was found to be '#{noop}', restoring it to the puppet.conf file"
    save_noop_puppet_conf(noop)
  else
    puts "There was no previous setting - setting to default: 'false'"
    save_noop_puppet_conf('false')
  end
end

def save_noop_puppet_conf(noop)
  puts "Setting the noop setting to '#{noop}'"
  FILE['agent']['noop'] = noop
  FILE.store
end

def save_previous_setting
  puts 'Seeing if there is a current noop setting'
  noop = FILE['agent']['noop']
  if noop.nil?
    puts 'There is no current setting'
  else
    puts "The current setting is '#{noop}', saving it so the new setting can be reverted later"
    open(NOOP_SAVE, 'w') { |f| f.puts noop }
  end
end

case ENV['PT_action']
when 'off'
  save_previous_setting
  save_noop_puppet_conf('false')
when 'on'
  save_previous_setting
  save_noop_puppet_conf('true')
when 'revert'
  restore_previous_setting
when 'show'
  puts FILE['agent']['noop'] || 'unset'
else
  STDERR.puts 'Unknown action or it was not specified'
  exit 1
end

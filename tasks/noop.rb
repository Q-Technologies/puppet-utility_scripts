#!/opt/puppetlabs/puppet/bin/ruby

# Script to toggle NOOP for Puppet

# It has 3 modes:
#   Turn on
#   Turn off
#   Revert to the previous setting prior to the last on/off

require 'facter'
require 'puppet'
require 'puppet/util/inifile'

$puppet_conf = "/etc/puppetlabs/puppet/puppet.conf"
$noop_save = "/etc/puppetlabs/puppet/.noop.conf"
if Facter.value(:kernel) == 'windows'
  $puppet_conf = 'C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf'
  $noop_save = 'C:\ProgramData\PuppetLabs\puppet\etc\.noop.conf'
end
$file = Puppet::Util::IniConfig::File.new
$file.read($puppet_conf)

def restore_previous_setting
  puts "Seeing if there was a previous noop setting"
  if File.exists?($noop_save)
    noop = File.read($noop_save).chomp
  end
  if noop =~ /^(0|1|true|false)$/i
    puts "It was found to be '#{noop}', restoring it to the puppet.conf file"
    save_noop_puppet_conf( noop )
  else
    puts "There was no previous setting - setting to default: 'false'"
    save_noop_puppet_conf( "false" )
  end
end

def save_noop_puppet_conf(noop)
  puts "Setting the noop setting to '#{noop}'"
  $file['agent']['noop'] = noop
  $file.store
end

def save_previous_setting
  puts "Seeing if there is a current noop setting"
  noop = $file['agent']['noop']
  if noop.nil?
    puts "There is no current setting"
  else
    puts "The current setting is '#{noop}', saving it so the new setting can be reverted later"
    open($noop_save, 'w') { |f|
      f.puts noop
    }
  end
end

case ENV['PT_action']
when 'off'
  save_previous_setting
  save_noop_puppet_conf( "false" )
when 'on'
  save_previous_setting
  save_noop_puppet_conf( "true" )
when 'revert'
  restore_previous_setting
when 'show'
  puts $file['agent']['noop'] || "unset"
else
  STDERR.puts "Unknown action or it was not specified"
  exit 1
end

#!/opt/puppetlabs/puppet/bin/ruby
require 'facter'
require 'socket'

puts 'The hostname of this ' + Facter.value(:kernel) + ' node is ' + Socket.gethostname

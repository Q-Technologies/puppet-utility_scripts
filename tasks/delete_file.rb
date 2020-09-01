#!/opt/puppetlabs/puppet/bin/ruby

File.delete(ENV['PT_file']) if File.exist?(ENV['PT_file'])

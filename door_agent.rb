#!/usr/bin/env ruby
require 'bundler'
Bundler.require

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'door_agent'

if __FILE__ == $0
  args = Slop.parse(autocreate: true).to_hash
  DoorAgent.new(args).run
end
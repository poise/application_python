#
# Author:: Jonathon W. Marshall <jonathon@bnotions.com>
# Cookbook Name:: application_python
# Resource:: uwsgi
#

include ApplicationCookbook::ResourceBase

attribute :packages, :kind_of => [Array, Hash], :default => []
attribute :requirements, :kind_of => [NilClass, String, FalseClass], :default => nil
attribute :settings_template, :kind_of => [String, NilClass], :default => nil
attribute :app_module, :kind_of => [String, NilClass], :default => nil
attribute :master, :kind_of => [TrueClass, FalseClass], :default => true
attribute :socket, :kind_of => [String, Array], :default => ':8080'
attribute :protocol, :kind_of => String, :default => 'http'
attribute :workers, :kind_of => Integer, :default => (node['cpu'] && node['cpu']['total']) && [node['cpu']['total'].to_i * 4, 8].min || 8
attribute :virtualenv, :kind_of => String, :default => nil
attribute :directory, :kind_of => [String, NilClass], :default => nil
attribute :autostart, :kind_of => [TrueClass, FalseClass], :default => false
attribute :extra_options, :kind_of => [Hash, NilClass], :default => nil

#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'shellwords'

require 'chef/provider'
require 'chef/resource'
require 'poise'

require 'poise_application_python/service_mixin'


module PoiseApplicationPython
  module Resources
    # (see Gunicorn::Resource)
    # @since 4.0.0
    module Gunicorn
      class Resource < Chef::Resource
        include PoiseApplicationPython::ServiceMixin
        provides(:application_gunicorn)

        attribute(:app_module, kind_of: [String, NilClass], default: lazy { default_app_module })
        attribute(:bind, kind_of: [String, Array], default: '0.0.0.0:80')
        attribute(:config, kind_of: [String, NilClass])
        attribute(:preload_app, equal_to: [true, false], default: false)
        attribute(:version, kind_of: [String, TrueClass, FalseClass], default: true)

        # Helper to set {#bind} with just a port number.
        #
        # @param val [String, Integer] Port number to use.
        # @return [void]
        def port(val)
          bind("0.0.0.0:#{val}")
        end

        private

        # Compute the default application module to pass to gunicorn. This
        # checks the app state and then looks for commonly used filenames.
        # Raises an exception if no default can be found.
        #
        # @return [String]
        def default_app_module
          # If set in app_state, use that.
          return app_state[:python_wsgi_module] if app_state[:python_wsgi_module]
          files = Dir.exist?(path) ? Dir.entries(path) : []
          # Try to find a known filename.
          candidate_file = %w{wsgi.py main.py app.py application.py}.find {|file| files.include?(file) }
          # Try the first Python file. Do I really want this?
          candidate_file ||= files.find {|file| file.end_with?('.py') }
          if candidate_file
            ::File.basename(candidate_file, '.py')
          else
            nil
          end
        end

      end

      class Provider < Chef::Provider
        include PoiseApplicationPython::ServiceMixin
        provides(:application_gunicorn)

        def action_enable
          notifying_block do
            install_gunicorn
          end
          super
        end

        private

        def install_gunicorn
          return unless new_resource.version
          python_package 'gunicorn' do
            python_from_parent new_resource
            version new_resource.version if new_resource.version.is_a?(String)
          end
        end

        def gunicorn_command_options
          # Based on http://docs.gunicorn.org/en/latest/settings.html
          [].tap do |cmd|
            # What options are common enough to deal with here?
            # %w{config backlog workers worker_class threads worker_connections timeout graceful_timeout keepalive}.each do |opt|
            %w{config}.each do |opt|
              val = new_resource.send(opt)
              if val && !(val.respond_to?(:empty?) && val.empty?)
                cmd_opt = opt.gsub(/_/, '-')
                cmd << "--#{cmd_opt} #{Shellwords.escape(val)}"
              end
            end
            # Can be given multiple times.
            Array(new_resource.bind).each do |bind|
              cmd << "--bind #{bind}" if bind
            end
            # --preload doesn't take an argument and the name doesn't match.
            if new_resource.preload_app
              cmd << '--preload'
            end
          end
        end

        # (see PoiseApplication::ServiceMixin#service_options)
        def service_options(resource)
          super
          raise PoiseApplicationPython::Error.new("Unable to determine app module for #{new_resource}") unless new_resource.app_module
          resource.command("#{new_resource.python} -m gunicorn.app.wsgiapp #{gunicorn_command_options.join(' ')} #{new_resource.app_module}")
        end

      end
    end
  end
end

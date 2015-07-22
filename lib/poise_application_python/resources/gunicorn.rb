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

require 'chef/provider'
require 'chef/resource'
require 'poise'
require 'poise_application/service_mixin'
require 'poise_python/python_command_mixin'


module PoiseApplicationPython
  module Resources
    # (see Gunicorn::Resource)
    # @since 4.0.0
    module Gunicorn
      class Resource < Chef::Resource
        include PoiseApplication::ServiceMixin
        include PoisePython::PythonCommandMixin
        provides(:application_gunicorn)

        attribute(:path, kind_of: String, name_attribute: true)
        attribute(:app_module, kind_of: String, default: lazy { default_app_module })
        attribute(:port, kind_of: [String, Integer], default: 80)
        attribute(:version, kind_of: [String, TrueClass, FalseClass], default: true)

        def default_app_module
          # If set in app_state, use that.
          return app_state[:python_app_module] if app_state[:python_app_module]
          files = Dir.entries(path)
          # Try to find a known filename.
          candidate_file = %w{wsgi.py main.py app.py application.py}.find {|file| files.include?(file) }
          # Try the first Python file. Do I really want this?
          candidate_file ||= files.find {|file| file.end_with?('.py') }
          if candidate_file
            ::File.basename(candidate_file, '.py')
          else
            raise PoiseApplicationPython::Error.new("Unable to determine app module for #{self}")
          end
        end

      end

      class Provider < Chef::Provider
        include PoiseApplication::ServiceMixin
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
            # Set the parent, could be either a resource or path string.
            if new_resource.parent_python
              parent_python new_resource.parent_python
            elsif new_resource.python
              python new_resource.python
            end
            version new_resource.version if new_resource.version.is_a?(String)
          end
        end

        # (see PoiseApplication::ServiceMixin#service_options)
        def service_options(resource)
          super
          resource.command("#{new_resource.python} -m gunicorn.app.wsgiapp --bind 0.0.0.0:#{new_resource.port} #{new_resource.app_module}")
        end

      end
    end
  end
end

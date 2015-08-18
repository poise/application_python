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

require 'poise_application_python/service_mixin'


module PoiseApplicationPython
  module Resources
    # (see CeleryWorker::Resource)
    # @since 4.0.0
    module CeleryWorker
      class Resource < Chef::Resource
        include PoiseApplicationPython::ServiceMixin
        provides(:application_celery_worker)

        attribute(:app_module, kind_of: [String, NilClass], default: lazy { default_app_module })

        private

        # Compute the default application module to pass to gunicorn. This
        # checks the app state and then looks for commonly used filenames.
        # Raises an exception if no default can be found.
        #
        # @return [String]
        def default_app_module
          # If set in app_state, use that.
          return app_state[:python_celery_module] if app_state[:python_celery_module]
          # If a Django settings module is set, use everything by the last
          # dotted component of it. to_s handles nil since that won't match.
          return $1 if app_state_environment[:DJANGO_SETTINGS_MODULE].to_s =~ /^(.+?)\.[^.]+$/
          files = Dir.exist?(path) ? Dir.entries(path) : []
          # Try to find a known filename.
          candidate_file = %w{tasks.py task.py celery.py main.py app.py application.py}.find {|file| files.include?(file) }
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
        provides(:application_celery_worker)

        private

        # (see PoiseApplication::ServiceMixin#service_options)
        def service_options(resource)
          super
          raise PoiseApplicationPython::Error.new("Unable to determine app module for #{new_resource}") unless new_resource.app_module
          resource.command("#{new_resource.python} -m celery --app=#{new_resource.app_module} worker")
        end

      end
    end
  end
end

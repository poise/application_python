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

require 'poise_python/resources/python_execute'

require 'poise_application_python/app_mixin'


module PoiseApplicationPython
  module Resources
    # (see PythonExecute::Resource)
    # @since 4.0.0
    module PythonExecute
      # An `application_python_execute` resource to run Python commands inside an
      # Application cookbook deployment.
      #
      # @provides application_python_execute
      # @action run
      # @example
      #   application '/srv/myapp' do
      #     python_execute 'setup.py install'
      #   end
      class Resource < PoisePython::Resources::PythonExecute::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_python_execute)

        def initialize(*args)
          super
          # Clear some instance variables so my defaults work.
          remove_instance_variable(:@cwd)
          remove_instance_variable(:@group)
          remove_instance_variable(:@user)
        end

        # #!attribute cwd
        #   Override the default directory to be the app path if unspecified.
        #   @return [String]
        attribute(:cwd, kind_of: [String, NilClass, FalseClass], default: lazy { parent && parent.path })

        # #!attribute group
        #   Override the default group to be the app group if unspecified.
        #   @return [String, Integer]
        attribute(:group, kind_of: [String, Integer, NilClass, FalseClass], default: lazy { parent && parent.group })

        # #!attribute user
        #   Override the default user to be the app owner if unspecified.
        #   @return [String, Integer]
        attribute(:user, kind_of: [String, Integer, NilClass, FalseClass], default: lazy { parent && parent.owner })
      end

      # The default provider for `application_python_execute`.
      #
      # @see Resource
      # @provides application_python_execute
      class Provider < PoisePython::Resources::PythonExecute::Provider
        provides(:application_python_execute)

        private

        # Override environment to add the application envivonrment instead.
        #
        # @return [Hash]
        def environment
          super.tap do |environment|
            # Don't use the app_state_environment_python because we already have
            # those values in place.
            environment.update(new_resource.app_state_environment)
            # Re-apply the resource environment for correct ordering.
            environment.update(new_resource.environment) if new_resource.environment
          end
        end
      end

    end
  end
end

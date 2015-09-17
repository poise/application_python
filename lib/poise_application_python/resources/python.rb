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

require 'poise_python/resources/python_runtime'

require 'poise_application_python/app_mixin'


module PoiseApplicationPython
  module Resources
    # (see Python::Resource)
    # @since 4.0.0
    module Python
      # An `application_python` resource to manage Python runtimes
      # inside an Application cookbook deployment.
      #
      # @provides application_python
      # @provides application_python_runtime
      # @action install
      # @action uninstall
      # @example
      #   application '/app' do
      #     python '2'
      #   end
      class Resource < PoisePython::Resources::PythonRuntime::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_python)
        provides(:application_python_runtime)
        container_default(false)
        subclass_providers!

        # Set this resource as the app_state's parent python.
        #
        # @api private
        def after_created
          super.tap do |val|
            app_state_python(self)
          end
        end

      end
    end
  end
end

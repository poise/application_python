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

require 'poise_python/resources/python_virtualenv'

require 'poise_application_python/app_mixin'


module PoiseApplicationPython
  module Resources
    # (see Virtualenv::Resource)
    # @since 4.0.0
    module Virtualenv
      # An `application_virtualenv` resource to manage Python virtual
      # environments inside an Application cookbook deployment.
      #
      # @provides application_virtualenv
      # @provides application_python_virtualenv
      # @action create
      # @action delete
      # @example
      #   application '/app' do
      #     virtualenv
      #   end
      class Resource < PoisePython::Resources::PythonVirtualenv::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_virtualenv)
        provides(:application_python_virtualenv)
        container_default(false)
        subclass_providers!

        # @!attribute path
        #   Override the normal path property to use name/.virtualenv for better
        #   compatibility with the application resource DSL.
        #   @return [String]
        attribute(:path, kind_of: String, default: lazy { default_path })

        # Set this resource as the app_state's parent python.
        #
        # @api private
        def after_created
          super.tap do |val|
            # Force evaluation so we get any current parent if set.
            parent_python
            app_state_python(self)
          end
        end

        private

        # Default value for the {#path} property.
        #
        # @return [String]
        def default_path
          # @todo This should handle relative paths as a name.
          ::File.join(name, '.virtualenv')
        end

      end
    end
  end
end

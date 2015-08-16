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

require 'poise/backports'
require 'poise/utils'
require 'poise_application/app_mixin'
require 'poise_python/python_command_mixin'


module PoiseApplicationPython
  # A helper mixin for Python application resources and providers.
  #
  # @since 4.0.0
  module AppMixin
    include Poise::Utils::ResourceProviderMixin

    # A helper mixin for Python application resources.
    module Resource
      include PoiseApplication::AppMixin::Resource
      include PoisePython::PythonCommandMixin::Resource

      # @!attribute parent_python
      #   Override the #parent_python from PythonCommandMixin to grok the
      #   application level parent as a default value.
      #   @return [PoisePython::Resources::PythonRuntime::Resource, nil]
      parent_attribute(:python, type: :python_runtime, optional: true, default: lazy { app_state_python.equal?(self) ? nil : app_state_python })

      # @attribute app_state_python
      #   The application-level Python parent.
      #   @return [PoisePython::Resources::PythonRuntime::Resource, nil]
      def app_state_python(python=Poise::NOT_PASSED)
        unless python == Poise::NOT_PASSED
          app_state[:python] = python
        end
        app_state[:python]
      end

      # A merged hash of environment variables for both the application state
      # and parent python.
      #
      # @return [Hash<String, String>]
      def app_state_environment_python
        env = app_state_environment
        env = env.merge(parent_python.python_environment) if parent_python
        env
      end
    end

    # A helper mixin for Python application providers.
    module Provider
      include PoiseApplication::AppMixin::Provider
    end
  end
end

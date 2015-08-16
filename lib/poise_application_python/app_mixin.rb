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

require 'chef/mash'
require 'poise/backports'
require 'poise/utils'
require 'poise_application/app_mixin'
require 'poise_python/python_command_mixin'


module PoiseApplicationPython
  module AppMixin
    include Poise::Utils::ResourceProviderMixin

    module Resource
      include PoiseApplication::AppMixin::Resource
      include PoisePython::PythonCommandMixin::Resource

      parent_attribute(:python, type: :python_runtime, optional: true, default: lazy { app_state_python.equal?(self) ? nil : app_state_python })

      # @attribute app_state_python
      def app_state_python(python=Poise::NOT_PASSED)
        unless python == Poise::NOT_PASSED
          app_state[:python] = python
        end
        app_state[:python]
      end

      def app_state_environment_python
        env = app_state_environment
        env = env.merge(parent_python.python_environment) if parent_python
        env
      end
    end

    module Provider
      include PoiseApplication::AppMixin::Provider
    end
  end
end

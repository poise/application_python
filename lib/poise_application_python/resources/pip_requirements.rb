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

require 'poise_python/resources/pip_requirements'

require 'poise_application_python/app_mixin'


module PoiseApplicationPython
  module Resources
    # (see PipRequirements::Resource)
    # @since 4.0.0
    module PipRequirements
      # An `application_pip_requirements` resource to manage Python virtual
      # environments inside an Application cookbook deployment.
      #
      # @provides application_pip_requirements
      # @provides application_virtualenv
      # @action install
      # @action upgrade
      # @example
      #   application '/app' do
      #     pip_requirements
      #   end
      class Resource < PoisePython::Resources::PipRequirements::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_pip_requirements)
        subclass_providers!

        # @todo This should handle relative paths against parent.path.
      end
    end
  end
end

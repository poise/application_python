#
# Copyright 2015-2016, Noah Kantrowitz
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

require 'uri'

require 'chef/provider'
require 'chef/resource'
require 'poise'
require 'poise_application'
require 'poise_python'

require 'poise_application_python/app_mixin'
require 'poise_application_python/service_mixin'
require 'poise_application_python/error'


module PoiseApplicationPython
  module Resources
    # (see CeleryConfig::Resource)
    # @since 4.1.0
    module FlowerConfig
      # An `application_flower_config` resource to configure flower monitoring app.
      #
      # @since 4.1.0
      # @provides application_flower_config
      # @action deploy
      # @example
      #   application '/srv/myapp' do
      #     git '...'
      #     pip_requirements
      #     flower_config do
      #       options do
      #         btoker '...'
      #       end
      #     end
      #   end
      class Resource < Chef::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_flower_config)
        actions(:deploy)

        attribute('', template: true, default_source: 'flowerconfig.py.erb')
        # @!attribute group
        #   Owner for the Flower application, defaults to application group.
        #   @return [String]
        attribute(:group, kind_of: String, default: lazy { parent && parent.group })
        # @!attribute owner
        #   Owner for the Flower application, defaults to application owner.
        #   @return [String]
        attribute(:owner, kind_of: String, default: lazy { parent && parent.owner })
        attribute(:path, kind_of: String, default: lazy { default_path })

        private

        def default_path
          if ::File.directory?(name)
            ::File.join(name, 'flowerconfig.py')
          else
            name
          end
        end
      end

      # Provider for `application_flower_config`.
      #
      # @since 4.1.0
      # @see Resource
      # @provides application_flower_config
      class Provider < Chef::Provider
        include PoiseApplicationPython::AppMixin
        provides(:application_flower_config)

        # `deploy` action for `application_flower_config`. Writes config file.
        #
        # @return [void]
        def action_deploy
          notifying_block do
            write_config
          end
        end

        private

        def write_config
          file new_resource.path do
            content new_resource.content
            mode '640'
            owner new_resource.owner
            group new_resource.group
          end
        end

      end
    end
  end
end

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

require 'uri'

require 'chef/provider'
require 'chef/resource'
require 'poise'
require 'poise_application'
require 'poise_python'

require 'poise_application_python/app_mixin'
require 'poise_application_python/error'


module PoiseApplicationPython
  module Resources
    # (see CeleryConfig::Resource)
    # @since 4.0.0
    module CeleryConfig
      # An `application_celery_config` resource to configure Celery workers.
      #
      # @since 4.0.0
      # @provides application_celery_config
      # @action deploy
      # @example
      #   application '/srv/myapp' do
      #     git '...'
      #     pip_requirements
      #     celery_config do
      #       options do
      #         broker_url '...'
      #       end
      #     end
      #     celeryd
      #   end
      class Resource < Chef::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_celery_config)
        actions(:deploy)

        attribute('', template: true, default_source: 'celeryconfig.py.erb')
        # @!attribute group
        #   Owner for the Django application, defaults to application group.
        #   @return [String]
        attribute(:group, kind_of: String, default: lazy { parent && parent.group })
        # @!attribute owner
        #   Owner for the Django application, defaults to application owner.
        #   @return [String]
        attribute(:owner, kind_of: String, default: lazy { parent && parent.owner })
        attribute(:path, kind_of: String, default: lazy { default_path })

        private

        def default_path
          if ::File.directory?(name)
            ::File.join(name, 'celeryconfig.py')
          else
            name
          end
        end
      end

      # Provider for `application_celery_config`.
      #
      # @since 4.0.0
      # @see Resource
      # @provides application_celery_config
      class Provider < Chef::Provider
        include PoiseApplicationPython::AppMixin
        provides(:application_celery_config)

        # `deploy` action for `application_celery_config`. Writes config file.
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

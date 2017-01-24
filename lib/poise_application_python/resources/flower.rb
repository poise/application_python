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
    # (see FlowerConfig::Resource)
    # @since 4.1.0
    module Flower
      # @since 4.1.0
      class Resource < Chef::Resource
        include PoiseApplicationPython::ServiceMixin
        provides(:application_flower)
        attribute(:config_file, kind_of: [String, NilClass], default: lazy { default_path })

        private

        def default_path
          if ::File.directory?(name)
            ::File.join(name, 'flowerconfig.py')
          else
            name
          end
        end
      end

      class Provider < Chef::Provider
        include PoiseApplicationPython::ServiceMixin
        provides(:application_flower)

        private

        def service_options(resource)
            super
            raise PoiseApplicationPython::Error.new("Unable to determine configuration file for #{new_resource}") unless new_resource.config_file
            resource.command("#{new_resource.python} -m flower --conf=#{new_resource.config_file}")
        end
      end
    end
  end
end

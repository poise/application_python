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

require 'poise_application_python/resources/celery_worker'


module PoiseApplicationPython
  module Resources
    # (see CeleryBeat::Resource)
    # @since 4.0.0
    module CeleryBeat
      class Resource < PoiseApplicationPython::Resources::CeleryWorker::Resource
        provides(:application_celery_beat)
      end

      class Provider < PoiseApplicationPython::Resources::CeleryWorker::Provider
        provides(:application_celery_beat)

        private

        # (see PoiseApplication::ServiceMixin#service_options)
        def service_options(resource)
          super
          resource.command("#{new_resource.python} -m celery --app=#{new_resource.app_module} beat")
        end

      end
    end
  end
end

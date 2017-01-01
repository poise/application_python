#
# Copyright 2015-2017, Noah Kantrowitz
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

include_recipe 'poise-python'

# For netstat in serverspec.
package 'net-tools'

application '/opt/wsgi1' do
  file '/opt/wsgi1/main.py' do
    content <<-'EOH'
def application(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    return ['Hello world!\n']
EOH
  end
  gunicorn do
    port 8000
  end
  gunicorn 'wsgi1b' do
    path parent.path
    service_name 'wsgi1b'
    app_module 'main'
    port 8001
  end
end

application '/opt/wsgi2' do
  file "#{path}/main.py" do
    content <<-'EOH'
import sys
def application(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    return ['\n'.join(sys.path)]
EOH
  end
  gunicorn do
    port 8002
  end
end

application '/opt/wsgi3' do
  file "#{path}/requirements.txt" do
    content <<-EOH
requests
six
EOH
  end
  virtualenv
  pip_requirements
  file "#{path}/main.py" do
    content <<-'EOH'
import sys
import requests
def application(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    return ['\n'.join(sys.path)]
EOH
  end
  gunicorn do
    port 8003
  end
end

include_recipe '::django'
include_recipe '::flask'

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

require 'net/http'

require 'serverspec'
set :backend, :exec

describe 'django' do
  describe port(9000) do
    it { is_expected.to be_listening }
  end

  let(:http) { Net::HTTP.new('localhost', 9000) }

  describe '/foo' do
    subject { http.get('/foo') }
    its(:code) { is_expected.to eq '404' }
  end

  describe '/admin/login/' do
    subject { http.get('/admin/login/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to include 'Polls Administration' }
  end

  describe '/polls/' do
    subject { http.get('/polls/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to include 'No polls are available.' }
  end

  describe '/static/polls/style.css' do
    subject { http.get('/static/polls/style.css') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to include 'color: green;' }
  end

  describe '/static/polls/images/background.gif' do
    subject { http.get('/static/polls/images/background.gif') }
    its(:code) { is_expected.to eq '200' }
  end
end

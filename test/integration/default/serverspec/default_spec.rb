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

describe 'wsgi1' do
  describe port(8000) do
    it { is_expected.to be_listening }
  end

  let(:http) { Net::HTTP.new('localhost', 8000) }

  describe '/' do
    subject { http.get('/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to eq "Hello world!\n" }
  end
end

describe 'wsgi1b' do
  describe port(8001) do
    it { is_expected.to be_listening }
  end

  let(:http) { Net::HTTP.new('localhost', 8001) }

  describe '/' do
    subject { http.get('/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to eq "Hello world!\n" }
  end
end

describe 'wsgi2' do
  describe port(8002) do
    it { is_expected.to be_listening }
  end

  let(:http) { Net::HTTP.new('localhost', 8002) }

  describe '/' do
    subject { http.get('/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to include '/opt/wsgi2' }
    its(:body) { is_expected.to include '/lib/python2.7' }
    its(:body) { is_expected.to match %r'/(opt/rh|usr)/.*?/lib/python2.7/(site|dist)-packages' }
  end
end

describe 'wsgi3' do
  describe port(8003) do
    it { is_expected.to be_listening }
  end

  let(:http) { Net::HTTP.new('localhost', 8003) }

  describe '/' do
    subject { http.get('/') }
    its(:code) { is_expected.to eq '200' }
    its(:body) { is_expected.to include '/opt/wsgi3' }
    its(:body) { is_expected.to include '/lib/python2.7' }
    its(:body) { is_expected.to include  '/opt/wsgi3/.virtualenv/lib/python2.7' }
    its(:body) { is_expected.to_not match %r'/(opt/rh|usr)/.*?/lib/python2.7/(site|dist)-packages' }
  end
end

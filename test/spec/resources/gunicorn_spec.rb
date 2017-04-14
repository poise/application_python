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

require 'spec_helper'

describe PoiseApplicationPython::Resources::Gunicorn do
  describe PoiseApplicationPython::Resources::Gunicorn::Resource do
    describe '#default_app_module' do
      let(:app_state) { {} }
      let(:files) { [] }
      let(:test_resource) { described_class.new('/test', nil) }
      before do
        allow(test_resource).to receive(:app_state).and_return(app_state)
        allow(Dir).to receive(:exist?).and_return(!files.empty?)
        allow(Dir).to receive(:entries).and_return(files)
      end
      subject { test_resource.send(:default_app_module) }

      context 'with an app_state key' do
        let(:app_state) { {python_wsgi_module: 'django'} }
        it { is_expected.to eq 'django' }
      end # /context with an app_state key

      context 'with a wsgi.py' do
        let(:files) { %w{wsgi.py} }
        it { is_expected.to eq 'wsgi' }
      end # /context with a wsgi.py

      context 'with an app.py and main.py' do
        let(:files) { %w{app.py main.py} }
        it { is_expected.to eq 'main' }
      end # /context with an app.py and main.py

      context 'with a foo.txt and bar.py' do
        let(:files) { %w{foo.txt bar.py} }
        it { is_expected.to eq 'bar' }
      end # /context with a foo.txt and bar.py

      context 'with a foo.txt' do
        let(:files) { %w{foo.txt } }
        it { is_expected.to be_nil }
      end # /context with a foo.txt
    end # /describe #default_app_module
  end # /describe PoiseApplicationPython::Resources::Gunicorn::Resource

  describe PoiseApplicationPython::Resources::Gunicorn::Provider do
    let(:new_resource) { double('new_resource') }
    let(:test_provider) { described_class.new(new_resource, nil) }

    describe '#gunicorn_command_options' do
      let(:props) { {} }
      let(:new_resource) { PoiseApplicationPython::Resources::Gunicorn::Resource.new('/test', nil) }
      subject { test_provider.send(:gunicorn_command_options).join(' ') }
      before do
        props.each {|key, value| new_resource.send(key, value) }
      end

      context 'with defaults' do
        it { is_expected.to eq '--bind 0.0.0.0:80' }
      end # /context with defaults

      context 'with a config file' do
        let(:props) { {config: '/test/myconfig.py'} }
        it { is_expected.to eq '--config /test/myconfig.py --bind 0.0.0.0:80' }
      end # /context with a config file

      context 'with a blank config file' do
        let(:props) { {config: ''} }
        it { is_expected.to eq '--bind 0.0.0.0:80' }
      end # /context with a blank config file

      context 'with two binds' do
        let(:props) { {bind: %w{0.0.0.0:80 0.0.0.0:81}} }
        it { is_expected.to eq '--bind 0.0.0.0:80 --bind 0.0.0.0:81' }
      end # /context with two binds

      context 'with a config file and preload' do
        let(:props) { {config: '/test/myconfig.py', preload_app: true} }
        it { is_expected.to eq '--config /test/myconfig.py --bind 0.0.0.0:80 --preload' }
      end # /context with a config file and preload
    end # /describe #gunicorn_command_options
  end # /describe PoiseApplicationPython::Resources::Gunicorn::Provider
end

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

require 'spec_helper'

describe PoiseApplicationPython::Resources::Gunicorn do
  describe PoiseApplicationPython::Resources::Gunicorn::Resource do
    describe '#default_app_module' do
      let(:app_state) { {} }
      let(:files) { [] }
      let(:test_resource) { described_class.new(nil, nil) }
      before do
        allow(test_resource).to receive(:app_state).and_return(app_state)
        allow(Dir).to receive(:entries).and_return(files)
      end
      subject { test_resource.send(:default_app_module) }

      context 'with an app_state key' do
        let(:app_state) { {python_app_module: 'django'} }
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
        it { expect { subject }.to raise_error PoiseApplicationPython::Error }
      end # /context with a foo.txt
    end # /describe #default_app_module
  end # /describe PoiseApplicationPython::Resources::Gunicorn::Resource
end

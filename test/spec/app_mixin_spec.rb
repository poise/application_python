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
require 'poise_application/cheftie'
require 'poise_python/cheftie'

describe PoiseApplicationPython::AppMixin do
  describe '#parent_python' do
    resource(:poise_test) do
      include described_class
    end
    provider(:poise_test)

    context 'with an app_state python' do
      recipe do
        python_runtime 'outer'
        application '/test' do
          app_state[:python] = PoisePython::Resources::PythonRuntime::Resource.new('inner', run_context)
          poise_test
        end
        python_runtime 'after'
        poise_test 'after'
        application '/other'
        poise_test 'other'
      end
      let(:python) { chef_run.application('/test').app_state[:python] }

      it { is_expected.to run_poise_test('/test').with(parent_python: python) }
      it { is_expected.to run_poise_test('after').with(parent_python: python) }
      it { is_expected.to run_poise_test('other').with(parent_python: chef_run.python_runtime('after')) }
      it { expect(python).to be_a Chef::Resource }
    end # /context with an app_state python

    context 'with a global python' do
      recipe do
        python_runtime 'outer'
        application '/test' do
          poise_test
        end
      end

      it { is_expected.to run_poise_test('/test').with(parent_python: chef_run.python_runtime('outer')) }
    end # /context with a global python

    context 'with no python' do
      recipe do
        application '/test' do
          poise_test
        end
      end

      it { is_expected.to run_poise_test('/test').with(parent_python: nil) }
    end # /context with no python
  end # /describe #parent_python
end

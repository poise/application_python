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

describe PoiseApplicationPython::Resources::Virtualenv do
  shared_examples 'application_virtualenv' do
    it { is_expected.to create_application_virtualenv('/test').with(path: '/test/.virtualenv') }
    it { expect(chef_run.application('/test').app_state[:python]).to eq chef_run.application_virtualenv('/test') }
  end # /shared_examples application_virtualenv

  context 'with #python_virtualenv' do
    recipe do
      application '/test' do
        python_virtualenv
      end
    end

    it_behaves_like 'application_virtualenv'
  end # /context with #python_virtualenv

  context 'with #virtualenv' do
    recipe do
      application '/test' do
        virtualenv
      end
    end

    it_behaves_like 'application_virtualenv'
  end # /context with #virtualenv
end

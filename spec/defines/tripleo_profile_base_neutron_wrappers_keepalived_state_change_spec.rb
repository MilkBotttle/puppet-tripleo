#
# Copyright (C) 2018 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

require 'spec_helper'

describe 'tripleo::profile::base::neutron::wrappers::keepalived_state_change' do

  let :title do
    'keepalived_state_change'
  end

  shared_examples_for 'tripleo::profile::base::neutron::wrappers::keepalived_state_change' do

    context 'creates wrapper file' do
      let(:params) {
        {
          :keepalived_state_change_wrapper  => '/usr/local/bin/keepalived-state-change',
          :bind_socket                      => 'unix:///run/another/docker.sock'
        }
      }

      it 'should generate a wrapper file' do
        is_expected.to contain_file('/usr/local/bin/keepalived-state-change').with(
          :mode   => '0755'
        )
        is_expected.to contain_file('/usr/local/bin/keepalived-state-change').with_content(
          /ip.netns.exec.*neutron-keepalived-state-change/
        )
        is_expected.to contain_file('/usr/local/bin/keepalived-state-change').with_content(
          /export DOCKER_HOST="unix:...run.another.docker.sock/
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::wrappers::keepalived_state_change'
    end
  end
end

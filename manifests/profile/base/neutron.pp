# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron
#
# Neutron server profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host fqdns
#   Defaults to hiera('rabbitmq_node_names')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('neutron::rabbit_port', 5672

class tripleo::profile::base::neutron (
  $step         = hiera('step'),
  $rabbit_hosts = hiera('rabbitmq_node_names', undef),
  $rabbit_port  = hiera('neutron::rabbit_port', 5672),
) {

  # TODO(jaosorior): Remove this when we pass it via t-h-t
  if hiera('enable_internal_tls', false) {
    $bind_host = 'localhost'
  } else {
    # This is executed in all of the nodes that use something neutron-related,
    # so we set the defalut, since the bind_host is only available in the
    # controllers. Either way, this will be removed and set properly via t-h-t
    # in a subsequent commit.
    $bind_host = hiera('neutron::bind_host', $::os_service_default)
  }

  if $step >= 3 {
    $rabbit_endpoints = suffix(any2array($rabbit_hosts), ":${rabbit_port}")
    class { '::neutron' :
      bind_host    => $bind_host,
      rabbit_hosts => $rabbit_endpoints,
    }
    include ::neutron::config
  }
}

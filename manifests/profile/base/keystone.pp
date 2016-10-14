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
# == Class: tripleo::profile::base::keystone
#
# Keystone profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('keystone::rabbit_port', 5672)

class tripleo::profile::base::keystone (
  $bootstrap_node  = hiera('bootstrap_nodeid', undef),
  $manage_db_purge = hiera('keystone_enable_db_purge', true),
  $step            = hiera('step'),
  $rabbit_hosts    = hiera('rabbitmq_node_ips', undef),
  $rabbit_port     = hiera('keystone::rabbit_port', 5672),
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
    $manage_roles = true
    $manage_endpoint = true
    $manage_domain = true
  } else {
    $sync_db = false
    $manage_roles = false
    $manage_endpoint = false
    $manage_domain = false
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    class { '::keystone':
      sync_db          => $sync_db,
      enable_bootstrap => $sync_db,
      rabbit_hosts     => suffix($rabbit_hosts, ":${rabbit_port}")
    }

    include ::keystone::config
    include ::keystone::wsgi::apache
    include ::keystone::cors

    if $manage_roles {
      include ::keystone::roles::admin
    }

    if $manage_endpoint {
      include ::keystone::endpoint
    }

  }

  if $step >= 5 and $manage_db_purge {
    include ::keystone::cron::token_flush
  }

  if $step >= 5 and $manage_domain {
    if hiera('heat_engine_enabled', false) {
      # if Heat and Keystone are collocated, so we want to
      # both configure heat.conf and create Keystone resources.
      # note: domain_password is given via Hiera.
      if defined(Class['::tripleo::profile::base::heat']) {
        include ::heat::keystone::domain
      } else {
        # if Heat and Keystone are not collocated, we want Puppet
        # to only create Keystone resources on the Keystone node
        # but not try to configure Heat, to avoid leaking the password.
        class { '::heat::keystone::domain':
          domain_name     => $::os_service_default,
          domain_admin    => $::os_service_default,
          domain_password => $::os_service_default,
        }
      }
      Class['::keystone::roles::admin'] -> Class['::heat::keystone::domain']
    }
  }

  if $step >= 5 and $manage_endpoint{
    if hiera('aodh_api_enabled', false) {
      include ::aodh::keystone::auth
    }
    if hiera('ceilometer_api_enabled', false) {
      include ::ceilometer::keystone::auth
    }
    if hiera('ceph_rgw_enabled', false) {
      include ::ceph::rgw::keystone::auth
    }
    if hiera('cinder_api_enabled', false) {
      include ::cinder::keystone::auth
    }
    if hiera('glance_api_enabled', false) {
      include ::glance::keystone::auth
    }
    if hiera('gnocchi_api_enabled', false) {
      include ::gnocchi::keystone::auth
    }
    if hiera('heat_api_enabled', false) {
      include ::heat::keystone::auth
    }
    if hiera('heat_api_cfn_enabled', false) {
      include ::heat::keystone::auth_cfn
    }
    if hiera('ironic_api_enabled', false) {
      include ::ironic::keystone::auth
    }
    if hiera('manila_api_enabled', false) {
      include ::manila::keystone::auth
    }
    if hiera('mistral_api_enabled', false) {
      include ::mistral::keystone::auth
    }
    if hiera('neutron_api_enabled', false) {
      include ::neutron::keystone::auth
    }
    if hiera('nova_api_enabled', false) {
      include ::nova::keystone::auth
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::keystone::auth
    }
    if hiera('swift_proxy_enabled', false) {
      include ::swift::keystone::auth
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::keystone::auth
    }
  }
}


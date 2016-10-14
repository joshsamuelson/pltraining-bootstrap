class bootstrap::profile::virt (
  $admin_user = $bootstrap::params::admin_user
){

  $image_location   = '/var/lib/libvirt/images'
  $image_source     = '/usr/src/vms'
  $wifi_iface       = 'wlp3s0'

  # Set up libvirt and network
  user {$admin_user:
    groups  => ['libvirt'],
    require => Class['libvirt'],
  }
  class { 'libvirt':
    defaultnetwork     => true,
    auth_unix_rw       => 'none',
    qemu_user          => $admin_user,
    qemu_group         => 'libvirt',
    qemu_vnc_listen    => '0.0.0.0',
    listen_tcp         => true,
    unix_sock_group    => 'libvirt',
    unix_sock_rw_perms => '0770',
  }
  libvirt_pool { 'default':
    ensure    => present,
    type      => 'dir',
    active    => true,
    autostart => true,
    target    => '/var/lib/libvirt/images/',
  }

  # Add a hosts entry for the main ip so that dnsmasq will work
  host { $::fqdn:
    ip => $::ipaddress
  }

  # Use local dns first
  file { '/etc/resolv.conf.head':
    ensure  => file,
    content => "nameserver 192.168.122.1",
  }

  file { '/etc/hostapd/hostapd.conf':
    ensure       => file,
    content      => epp('bootstrap/hostapd.conf.epp',{
      iface      => $wifi_iface,
      hw_mode    => 'g',
      channel    => '1',
      ssid       => 'classroom_in_a_box',
      passphrase => fqdn_rand_string(10,'abcdefghijklmonpqrstuvwxyz0123456789.'),
      bridge     => 'virbr0',
      }),
    require => Package['hostapd'],
    before  => Service['hostapd'],
  }

  package {['kvm','hostapd','iw']:
    ensure  => present,
    require => Class['epel'],
  }

  file { '/etc/systemd/system/multi-user.target.wants/hostapd.service':
    ensure  => file,
    source  => 'puppet:///modules/bootstrap/hostapd.service',
    before  => Service['hostapd'],
    require => Package['hostapd'],
  }

  service {'hostapd':
    ensure => running,
    enable => true,
  }

  # Set dnsmasq to use the libvirt default network
#  file { '/etc/dnsmasq.conf':
#    ensure   => file,
#    content  => 'interface=virbr0',
#    require  => Package['dnsmasq'],
#  }
#
  # Download VMs
  file { [$image_source,$image_location]:
    ensure  => directory,
    owner   => $admin_user,
    group   => 'libvirt',
  }
  file { "${image_source}/windows.vhd":
    ensure => file,
    source => 'http://int-resources.ops.puppetlabs.net/EducationBeta/Windows/9600.16415.amd64fre.winblue_refresh.130928-2229_server_serverdatacentereval_en-us.vhd',
  }
  exec { 'convert windows image':
    command => "qemu-img convert -f vpc -O raw ${image_source}/windows.vhd windows.img",
    cwd     => $image_location,
    path    => '/bin',
    creates => "${image_location}/windows.img",
    require => File["${image_source}/windows.vhd"],
    before  => File["${image_location}/windows.img"],
  }
  file {"${image_location}/windows.img":
    ensure => file,
    owner  => $admin_user,
    group  => 'libvirt',
  }
  
#  file { "${image_source}/github.qcow2":
#    ensure => file,
#    owner  => 'training',
#    group  => 'libvirt',
#    #    source => 'https://github-enterprise.s3.amazonaws.com/kvm/releases/github-enterprise-2.7.4.qcow2',
#    source => 'http://int-resources.ops.puppetlabs.net/EducationBeta/Beta/github_base.qcow2',
#    notify => Exec['convert github image']
#  }
#  exec { 'convert github image':
#    command => "qemu-img convert -f qcow2 -O raw ${image_source}/github.qcow2 github.img",
#    cwd     => $image_location,
#    path    => '/bin',
#    creates => "${image_location}/github.img",
#    require => File["${image_source}/github.qcow2"],
#    before  => File["${image_location}/github.img"],
#  }
#  file {"${image_location}/github.img":
#    ensure => file,
#    owner  => 'training',
#    group  => 'libvirt',
#  }
#

  file { "${image_source}/puppet-master.ova":
    ensure => file,
    source => 'https://s3-us-west-2.amazonaws.com/puppetlabs-vms/puppet-2016.4.0-rc2-20-g910023a-master-5.6.ova',
    notify => Exec['expand master image']
  }
  exec { 'expand master image':
    command     => "tar xvf ${image_source}/puppet-master.ova *.vmdk",
    cwd         => $image_source,
    path        => '/bin',
    refreshonly => true,
    require     => File["${image_source}/puppet-master.ova"],
  }
  exec { 'convert master image':
    command => "qemu-img convert -f vmdk -O raw ${image_source}/*.vmdk master.img && rm -rf ${image_source}/*.vmdk",
    cwd     => $image_location,
    path    => '/bin',
    creates => "${image_location}/master.img",
    require => Exec['expand master image'],
    before  => File["${image_location}/master.img"],
  }
  file {"${image_location}/master.img":
    ensure => file,
    owner  => $admin_user,
    group  => 'libvirt',
  }

}

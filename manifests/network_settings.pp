# Set DHClient to be robust on skytap
# Per: http://help.skytap.com/#Linux_VM_Connectivity_Issues.html

class bootstrap::network_settings {
  file_line { 'DHCLIENTARGS':
    path    => '/etc/sysconfig/network-scripts/ifcfg-eth0',
    line    => 'DHCLIENTARGS="-nw"',
    match   => '^DHCLIENTARGS.*',
  }
  file_line { 'PERSISTENT_DHCLIENT':
    path    => '/etc/sysconfic/network-scripts/ifcfg-eth0',
    line    => 'PERSISTENT_DHCLIENT=yes',
    match   => '^PERSISTENT_DHCLIENT.*',
  }
}


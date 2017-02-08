class bootstrap::profile::classroom_scripts {
  # Populate the VM with our helper scripts.
  File {
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }
  file {'/usr/local/bin':
    ensure  => directory,
    recurse => true,
    replace => false,
    source  => 'puppet:///modules/bootstrap/scripts/classroom-only',
  }
}

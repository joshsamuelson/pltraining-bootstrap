class bootstrap::profile::lms_base {
  file {'/etc/profile.d/profile.sh':
    ensure => present,
    mode   => 755,
    source => 'puppet:///modules/bootstrap/lms/profile.sh',
  }
}

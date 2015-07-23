# -------
# Fetch and unzip 32bit agent installer
# Pinned to el6
# -------

class bootstrap::profile::get_32bit_agent(
  $version        = '2015.2.0',
  $architecture   = $::architecture,
  $file_cache     = '/vagrant/file_cache'
) {
  $puppet_dir   = '/opt/puppetlabs'
  $data_dir     = "${puppet_dir}/data"
  $repo_dir     = "${data_dir}/packages"
  $public_dir   = "${repo_dir}/public"
  $version_dir  = "${public_dir}/${version}"
  $agent_arch   = "el-6-i386"
  $agent_dir    = "puppet-agent-${agent_arch}"
  $agent_file   = "${agent_dir}.tar.gz"
  $url          = "https://s3.amazonaws.com/pe-builds/released/${version}"

  Staging::File {
    require => Class['bootstrap::profile::installer_staging']
  }

  file { [$puppet_dir,$data_dir,$repo_dir,$public_dir,$version_dir]:
    ensure => directory
  }
  staging::extract { $agent_file:
    target  => $public_dir,
    creates => "${public_dir}/${agent_dir}",
    require => [File[$public_dir],Staging::File[$agent_file]]
  }
  #our nice symlink to make the .repo files happy
  file { "${version_dir}/el-6-i386":
    ensure  => link,
    target  => "${public_dir}/${agent_dir}/agent_packages/${installer_build}",
    require => [Staging::Extract[$agent_file],File[$version_dir]],
  }
}

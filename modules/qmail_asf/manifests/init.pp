##/etc/puppet/modules/qmail_asf/manifests/init.pp

class qmail_asf (

  $username                      = 'apmail',
  $user_present                  = 'present',
  $groupname                     = 'apmail',
  $group_present                 = 'present',
  $groups                        = [],
  $shell                         = '/bin/bash',

  # override below in yaml
  $parent_dir    = '/x1',
  $ezmlm_version = '',

  # override below in eyaml
  $stats_url = '',
  $mm_auth   = '',
  $ap_user   = '',
  $ap_pw     = '',

  $required_packages = [
    'qmail',
    'dot-forward',
    'daemontools',
    'ucspi-tcp',
    'rbldnsd',
    'djbdns',
    'dnscache-run',
    'dnsmasq',
    'clamav',
    'clamav-freshclam',
    'qpsmtpd',
    'libnet-ldap-perl'
  ],
){

  # install required packages:

  package {
    $required_packages:
      ensure => 'present',
  }

  # apmail specific

  $apmail_home        = "${parent_dir}/${username}"
  $bin_dir            = "${apmail_home}/bin"
  $lib_dir            = "${apmail_home}/lib"
  $lists_dir          = "${apmail_home}/lists"
  $logs2_dir          = "${apmail_home}/logs2"
  $json_dir           = "${apmail_home}/json"
  $svn_dot_dir        = "${apmail_home}/.subversion2"
  $mailqsize_port     = '8083'

  # ezmlm specific

  $tarball            = "ezmlm-idx-${ezmlm_version}.tar.gz"
  $download_dir       = '/tmp'
  $downloaded_tarball = "${download_dir}/${tarball}"
  $download_url       = "https://untroubled.org/ezmlm/archive/${ezmlm_version}/ezmlm-idx-${ezmlm_version}.tar.gz"
  $install_dir        = "${parent_dir}/ezmlm-idx-${ezmlm_version}"
  $default            = "${install_dir}/lang/default"

  # qmail specific 

  $qmail_dir          = '/var/lib/qmail'
  $control_dir        = "${qmail_dir}/control"

  # qpsmtpd  specific

  $qpsmtpd_dir        = '/etc/qpsmtpd'
  $qpsmtpd_log_dir    = '/var/log/qmail/qpsmtpd'

  user {
    $username:
      ensure     => $user_present,
      name       => $username,
      home       => $apmail_home,
      shell      => $shell,
      groups     => $groups,
      managehome => true,
      require    => Group[$groupname],
      system     => true,
  }

  group {
    $groupname:
      ensure => $group_present,
      name   => $groupname,
  }

  # smtpd

  ### - Download, extract, configure, compile and install ezmlm-idx - ###

  # download ezmlm
  exec {
    'download-ezmlm':
      command => "/usr/bin/wget -O ${downloaded_tarball} ${download_url}",
      creates => $downloaded_tarball,
      timeout => 1200,
  }

  file { $downloaded_tarball:
    ensure  => file,
    require => Exec['download-ezmlm'],
  }

  # extract the download and move it
  exec {
    'extract-ezmlm':
      command => "/bin/tar -xvzf ${tarball} && mv ezmlm-idx-${ezmlm_version} ${parent_dir}",
      cwd     => $download_dir,
      user    => 'root',
      creates => "${install_dir}/INSTALL",
      timeout => 1200,
      require => [File[$downloaded_tarball],File[$parent_dir]],
  }

  # make, make man, ezmlm-test and make install
  -> exec {
    'make-ezmlm':
      command => 'make clean && make && make man',
      path    => '/bin:/usr/bin',
      cwd     => $install_dir,
      user    => root,
      creates => "${install_dir}/makeso",
      timeout => 1200,
      require => Exec['extract-ezmlm'],
      notify  => Exec['ezmlm-test'],
  }

  -> exec {
    'ezmlm-test':
      command     => 'ezmlm-test',
      path        => "/bin:/usr/bin:${install_dir}",
      cwd         => $install_dir,
      user        => root,
      timeout     => 1200,
      refreshonly => true,
      returns     => 0,
      require     => [File[$default], Exec['make-ezmlm']],
  }

  -> exec {
    'install-ezmlm':
      command => 'make install',
      path    => '/bin:/usr/bin',
      cwd     => $install_dir,
      user    => root,
      creates => '/usr/bin/ezmlm-make',
      timeout => 1200,
      require => Exec['ezmlm-test'],
  }

  ### - End of Download, extract, configure, compile and install ezmlm-idx - ###

  # various files or dirs needed

  file {

  # directories

    $parent_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    $bin_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/apmail/bin',
      require => User[$username];
    $lib_dir:
      ensure  => directory,
      recurse => true,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/apmail/lib',
      require => User[$username];
    $lists_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $logs2_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $json_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    "${json_dir}/output":
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    $svn_dot_dir:
      ensure  => directory,
      owner   => $username,
      group   => $username,
      mode    => '0755',
      require => User[$username];
    "${svn_dot_dir}/auth":
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      mode    => '0750',
      require => File[$svn_dot_dir];
    "${svn_dot_dir}/auth/svn.simple":
      ensure  => directory,
      owner   => $username,
      group   => $groupname,
      mode    => '0750',
      require => File["${svn_dot_dir}/auth"];
    "${svn_dot_dir}/auth/svn.simple/d3c8a345b14f6a1b42251aef8027ab57":
      ensure  => present,
      owner   => $username,
      group   => $groupname,
      mode    => '0640',
      content => template('qmail_asf/svn-credentials.erb'),
      require => File["${svn_dot_dir}/auth/svn.simple"];
    $install_dir:
      ensure  => directory,
      recurse => true,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/ezmlm/conf',
      require => [User[$username] , Exec[extract-ezmlm]];
    $qpsmtpd_log_dir:
      ensure  => directory,
      owner   => 'qmaill',
      group   => 'qmail',
      mode    => '2755';
    $qmail_dir:
      ensure  => directory,
      owner   => root,
      group   => qmail,
      mode    => '0755',
      require => Package['qmail'];
    $control_dir:
      ensure  => directory,
      owner   => $username,
      group   => qmail,
      mode    => '0755',
      require => [User[$username], Package['qmail']];

  # template files

  # common.conf - global variables other scripts should use.

    "${bin_dir}/common.conf":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/common.conf.erb'),
      mode    => '0644';

  # Other template files needed for other reasons, perhaps they contain
  # passwords or tokens and other stuff

    "${bin_dir}/infod.py":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/infod.py.erb'),
      mode    => '0755';

    "${bin_dir}/makelist-apache.sh":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/makelist-apache.sh.erb'),
      mode    => '0755';

    "${bin_dir}/massmove-apache.pl":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/massmove-apache.pl.erb'),
      mode    => '0755';

    "${apmail_home}/.ezmlmrc":
      owner   => $username,
      group   => $groupname,
      content => template('qmail_asf/ezmlmrc.erb'),
      mode    => '0644';

    # qpsmtpd startup and logging scripts

    "$qpsmtpd_dir/log":
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0755';
    "$qpsmtpd_dir/log/run":
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/qpsmtpd/log/run';
    "$qpsmtpd_dir/run":
      owner   => 'root',
      group   => 'root',
      recurse => true,
      mode    => '0755',
      source  => 'puppet:///modules/qmail_asf/qpsmtpd/run';

  # qpsmtpd config scripts

    "$qpsmtpd_dir/plugins":
      owner   => 'root',
      group   => 'root',
      recurse => true,
      mode    => '0644',
      source  => 'puppet:///modules/qmail_asf/qpsmtpd/plugins';

  # symlinks

    "/home/${username}":
      ensure => link,
      target => $apmail_home;

    # ezmlm-test fails unless default is symlinked to en_US

    $default:
      ensure  => link,
      target  => "${install_dir}/lang/en_US",
      require => Exec['extract-ezmlm'];

    '/etc/service/qpsmtpd':
      ensure  => link,
      target  => $qpsmtpd_dir,
      require => Package['qpsmtpd'];
  }

  exec { 'control-files':
    command => "svn co https://svn.apache.org/repos/infra/infrastructure/trunk/qmail/control/ --config-dir=${svn_dot_dir}",
    path    => '/usr/bin/',
    cwd     => $qmail_dir,
    user    => $username,
    group   => $groupname,
    creates => "${control_dir}/me.asf",
    require => [ Package['subversion'], User[$username] , File[$control_dir]],
  }

}

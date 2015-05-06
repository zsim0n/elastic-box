Exec {
  path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
}

Package {
  ensure => 'present',
}

class { 'apt':
  update => {
    frequency => 'always',
  },
}

exec { 'apt-get update':
  command => '/usr/bin/apt-get update -y',
}

# dotfiles

exec { 'dotfiles':
  command => '/usr/bin/git clone https://github.com/zsim0n/dotfiles.git && cd /home/vagrant/dotfiles && chmod +x ./bootstrap.sh && ./bootstrap.sh -f && rm -Rf /home/vagrant/dotfiles',
  cwd  => '/home/vagrant',
  user => 'vagrant',
  require => Exec['apt-get update']
}


# Java is required
class { 'java': }

# Elasticsearch

class { 'elasticsearch':
  manage_repo  => true,
  repo_version => '1.5',
}

elasticsearch::instance { 'es-01':
  config => { 
  'cluster.name' => 'vagrant_elasticsearch',
  'index.number_of_replicas' => '0',
  'index.number_of_shards'   => '1',
  'network.host' => '0.0.0.0'
  },        # Configuration hash
  init_defaults => { }, # Init defaults hash
  before => Exec['kibana-start']
}

elasticsearch::plugin{'royrusso/elasticsearch-HQ':
  module_dir => 'HQ',
  instances  => 'es-01'
}

# Logstash

class { 'logstash':
#  autoupgrade  => true,
  ensure       => 'present',
  manage_repo  => true,
  repo_version => '1.4',
  status => 'disabled',
  require      => [ Class['java'], Class['elasticsearch']],
}


file { '/etc/profile.d/logstash-path.sh':
    mode    => 644,
    content => 'PATH=$PATH:/opt/logstash/bin',
    require => Class['logstash'],
}

# Kibana
package { 'curl':
}

file { '/home/vagrant/kibana':
  ensure => 'directory',
  group  => 'vagrant',
  owner  => 'vagrant',
}

exec { 'kibana-download':
  command => '/usr/bin/curl -L https://download.elasticsearch.org/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz | /bin/tar xvz -C /home/vagrant/kibana',
  require => [ Package['curl'], File['/home/vagrant/kibana'],Class['elasticsearch'] ],
  timeout     => 1800
}

exec {'kibana-start':
  command => '/bin/sleep 10 && /home/vagrant/kibana/kibana-4.0.2-linux-x64/bin/kibana & ',
  require => [ Exec['kibana-download']]
}

# nodejs
$npm_packages = ['yo', 'serve','bower','grunt-cli']

exec {'nodejs-setup': 
  command => '/usr/bin/curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -',
  require => Exec['apt-get update']
}->
package { 'nodejs' :
}->
exec { 'nodejs-post-install':
  command => 'npm install -g npm && sudo npm -g config set prefix /home/vagrant/npm',
}->
file { '/etc/profile.d/nodejs-path.sh' :
  ensure  => present,
  mode    => 644,
  content => template('/vagrant/puppet/templates/nodejs-path.sh.erb'),
  owner   => 'vagrant',
  group   => 'vagrant',
}->
package { $npm_packages:
  provider => 'npm',
}

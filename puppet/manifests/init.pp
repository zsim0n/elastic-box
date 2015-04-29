# Update APT Cache

class { 'apt':
  update => {
    frequency => 'always',
  },
}

exec { 'apt-get update':
  command => '/usr/bin/apt-get update -y',
  before  => [ Class['logstash'] ],
}

#file { '/home/vagrant/elasticsearch':
#  ensure => 'directory',
#  group  => 'vagrant',
#  owner  => 'vagrant',
#}

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
  before => Exec['start kibana']
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
  require      => [ Class['java'], Class['elasticsearch'] ],
}

file { '/etc/logstash/conf.d/logstash':
  ensure  => '/vagrant/confs/logstash/logstash.conf',
  require => [ Class['logstash'] ],
}

file { '/home/vagrant/kibana':
  ensure => 'directory',
  group  => 'vagrant',
  owner  => 'vagrant',
}

package { 'curl':
  ensure  => 'present',
  require => [ Class['apt'] ],
}

exec { 'download_kibana':

  command => '/usr/bin/curl -L https://download.elasticsearch.org/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz | /bin/tar xvz -C /home/vagrant/kibana',
  require => [ Package['curl'], File['/home/vagrant/kibana'],Class['elasticsearch'] ],
  timeout     => 1800
}

exec {'start kibana':
  command => '/bin/sleep 10 && /home/vagrant/kibana/kibana-4.0.2-linux-x64/bin/kibana & ',
  require => [ Exec['download_kibana']]
}

# dotfiles

exec { 'dotfiles':
  command => '/usr/bin/git clone https://github.com/zsim0n/dotfiles.git && cd /home/vagrant/dotfiles && chmod +x ./bootstrap.sh && ./bootstrap.sh -f && rm -Rf /home/vagrant/dotfiles',
  cwd  => '/home/vagrant',
  user => 'vagrant',
}

file { '/etc/profile.d/logstash-path.sh':
    mode    => 644,
    content => 'PATH=$PATH:/opt/logstash/bin',
}

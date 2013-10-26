$:.push File.expand_path("../lib", __FILE__)

require "zabbix-cloudwatch/version"

Gem::Specification.new do |s|
  s.name        = "zabbix-cloudwatch"
  s.version     = ZabbixCloudwatch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Randy D. Wallace Jr."]
  s.email       = ["randy@randywallace.com"]
  s.homepage    = "http://github.com/randywallace/zabbix-cloudwatch"
  s.summary     = %q{A library for getting cloudwatch metrics into Zabbix}
  s.description = %q{A library for getting cloudwatch metrics into Zabbix}

  s.add_runtime_dependency "aws-sdk", "~> 1.21.0"
  s.add_runtime_dependency "getopt", "~> 1.4.1"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

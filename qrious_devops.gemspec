$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "qrious_devops/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "qrious_devops"
  s.version     = QriousDevops::VERSION
  s.authors     = ["Kliment Mamykin"]
  s.email       = ["kmamyk@qrio.us"]
  s.homepage    = "http://github.com/kmamykin/qrious_devops"
  s.summary     = "DevOps stack for Qrious apps"
  s.description = "DevOps stack for Qrious apps"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "> 3.2.0"
end

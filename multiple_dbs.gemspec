$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "multiple_dbs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "multiple_dbs"
  s.version     = MultipleDbs::VERSION
  s.authors     = ["Yonga9121"]
  s.email       = ["jorgeggayon@gmail.com"]
  s.homepage    = "https://github.com/yonga9121/multiple_dbs.git"
  s.summary     = "Management of multiple databases."
  s.description = "Management of multiple databases."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0"

  s.add_development_dependency "pg"
end

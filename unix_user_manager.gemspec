# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unix_user_manager/version'

Gem::Specification.new do |spec|
  spec.name          = "unix_user_manager"
  spec.version       = UnixUserManager::VERSION
  spec.authors       = ["mr.The"]
  spec.email         = ["me@mrthe.name"]

  spec.summary       = %q{Management tool for unix users.}
  spec.description   = %q{Management tool for unix users. Manually edits `/etc/passwd`, `/etc/shadow` and `/etc/groups`.}
  spec.homepage      = "http://github.com/mrThe/unix_user_manager"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1.0"
  spec.add_development_dependency "rake", "~> 12.3.3"
end

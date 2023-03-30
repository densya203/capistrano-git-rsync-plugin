
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-git-rsync-plugin"
  spec.version       = "0.0.1"
  spec.authors       = ["Tad Kam"]
  spec.email         = ["densya203@skult.jp"]

  spec.summary       = %q{Plugin for Capitsrano 3.7+ to deploy with git and rsync }
  spec.description   = %q{Plugin for Capistrano 3.7+ to deploy with git and rsync. Customized for Having Many Files Site.

  Ideally suited to deploying static sites made with static-site-generators.}
  spec.homepage      = "https://github.com/densya203/capistrano-git-rsync-plugin"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.0.0.pre'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
end

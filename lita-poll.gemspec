Gem::Specification.new do |spec|
  spec.name          = "lita-poll"
  spec.version       = "1.0.1"
  spec.authors       = ["Michael Chua"]
  spec.email         = ["chua.mbt@gmail.com"]
  spec.summary       = %q{Plugin that enables polling functionality for a lita bot.}
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }
  spec.homepage      = "https://github.com/chua-mbt/lita-poll"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 3.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end

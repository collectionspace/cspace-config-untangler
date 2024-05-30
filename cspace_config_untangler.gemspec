# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cspace_config_untangler/version"

Gem::Specification.new do |spec|
  spec.name = "cspace_config_untangler"
  spec.version = CspaceConfigUntangler::VERSION
  spec.authors = ["Kristina Spurgin"]
  spec.email = ["kristina.spurgin@lyrasis.org"]

  spec.summary = "Generate data dictionary info from CSpace configs"
  spec.homepage = "https://github.com/lyrasis/cspace_config_untangler"
  spec.license = "MIT"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] =
    "https://github.com/lyrasis/cspace_config_untangler"
  spec.metadata["changelog_uri"] =
    "https://github.com/lyrasis/cspace_config_untangler"

  # Specify which files should be added to the gem when it is
  # released. The `git ls-files -z` loads the files in the RubyGem
  # that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "collectionspace-client"
  spec.add_runtime_dependency "dry-configurable"
  spec.add_runtime_dependency "facets"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "thor"
end

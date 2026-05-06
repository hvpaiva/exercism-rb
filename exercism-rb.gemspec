# frozen_string_literal: true

require_relative "lib/exercism/rb/version"

Gem::Specification.new do |spec|
  spec.name = "exercism-rb"
  spec.version = Exercism::Rb::VERSION
  spec.authors = ["hvpaiva"]
  spec.email = ["hvpaiva@users.noreply.github.com"]
  spec.summary = "Exercism Ruby workflow helper CLI"
  spec.description = "A small command-line helper that keeps Exercism Ruby exercises easy to open, test, inspect, and submit."
  spec.homepage = "https://github.com/hvpaiva/exercism-rb"
  spec.license = "MIT"
  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true",
    "source_code_uri" => spec.homepage
  }

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["lib/**/*.rb", "bin/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.bindir = "bin"
  spec.executables = ["xrb"]

  spec.add_development_dependency "minitest", "~> 5.25"
  spec.add_development_dependency "rake", "~> 13.2"
end

# frozen_string_literal: true

require_relative "lib/bundler/override/version"

Gem::Specification.new do |spec|
  spec.name = "bundler-override"
  spec.version = Bundler::Override::VERSION
  spec.authors = ["Cezary Tarnowski", "Tomasz Wojcik", "Marek Jakubowski"]
  spec.email = ["non-exiting@email.dont.use"]

  spec.summary = "This bundler plugin allows to change dependencies for a gem. It can be helpful in situation when a developer needs to use some other dependency than default for the gem."
  spec.homepage = "https://github.com/tarnowsc/bundler-override"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tarnowsc/bundler-override"
  spec.metadata["changelog_uri"] = "https://github.com/tarnowsc/bundler-override/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "colorize"
  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",     "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end

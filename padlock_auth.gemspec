require_relative "lib/padlock_auth/version"

Gem::Specification.new do |spec|
  spec.name = "padlock_auth"
  spec.version = PadlockAuth::VERSION
  spec.authors = ["Ben Morrall"]
  spec.email = ["bemo56@hotmail.com"]
  spec.homepage = "http://github.com/bmorrall/padlock_auth"
  spec.summary = "Secure your Rails application using access tokens provided by an external provider."
  spec.description = "PadlockAuth allows you to secure your Rails application using access tokens provided by an external provider."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bmorrall/padlock_auth"
  spec.metadata["changelog_uri"] = "https://github.com/bmorrall/padlock_auth/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.2.1"

  spec.add_development_dependency "yard"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard", ">= 1.41.1"
end

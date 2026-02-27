# frozen_string_literal: true

source "https://rubygems.org"

def lyrasis_staff?
  ghpath = `which gh`
  return false if ghpath.empty?

  orgs = `gh org list`
  return true if orgs.split("\n").include?("dts-hosting")

  false
end

gem "collectionspace-client", github: "collectionspace/collectionspace-client",
  branch: "main"

if lyrasis_staff?
  gem "aws-sdk-dynamodb"
  gem "aws-sdk-ssm"
  gem "openssl", "3.3.1"
end

group :development do
  gem "almost_standard", github: "kspurgin/almost_standard", branch: "main"
end

group :test do
  gem "rspec-custom", github: "kspurgin/rspec-custom", branch: "main"
end

# Specify your gem's dependencies in cspace_config_untangler.gemspec
gemspec

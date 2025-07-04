source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'spree', '~> 5.1', '< 5.2', github: 'spree/spree'
gem 'searchkick'

gem 'rails-controller-testing'

gemspec

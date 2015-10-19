# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_cyberpac_payment'
  s.version     = SpreeCyberpacPayment::VERSION
  s.summary     = 'Add Cyberpac payment method to Spree Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 2.0.0'

  s.author    = 'Ruben Sierra'
  s.email     = 'ruben@simplelogica.net'
  s.homepage  = 'http://www.simplelogica.net'

  s.files       = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.5.beta'

  s.add_development_dependency 'capybara', '~> 2.4'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl', '~> 4.5'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 3.1'
  s.add_development_dependency 'sass-rails', '~> 5.0.0.beta1'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end

source ENV.fetch('GEM_SOURCE', 'https://rubygems.org')

ruby '2.1.1'

# process runner
gem 'foreman'

# web server
gem 'unicorn'

# application microframework
gem 'sinatra'

# database
gem 'hiredis'
gem 'redis', require: %w(redis redis/connection/hiredis)

# message management
gem 'bunny'

# talkin' sweet HTTP
gem 'faraday'
gem 'faraday_middleware'

# configuration through environement
gem 'dotenv'

group :development do 
  # SSL support for local development
  gem 'tunnels',        require: false
  # unit/functional tests
  gem 'rspec',          require: false
  # integration tests
  gem 'rack-test',      require: false
  # running tests automatically
  gem 'guard-rspec',    require: false
  # testing outbound HTTP
  gem 'webmock',        require: false
  # support time-dependent tests
  gem 'timecop',        require: false
  # better REPL
  gem 'pry'
  gem 'pry-nav'
  gem 'pry-remote'
end
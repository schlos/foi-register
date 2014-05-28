source 'https://rubygems.org'

gem 'rails', '3.2.19'

gem 'rack', '~> 1.4'
#
# This should be removed when the bug is fixed.

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '3.2.5'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'sqlite3'
  gem 'mailcatcher'
  gem 'mocha', :require => false
end

group :test do
  gem 'sqlite3'
  gem 'mocha', :require => false

  gem 'debugger', :require => 'ruby-debug', :platforms => :mri_19, :git => "https://github.com/cldwalker/debugger"
  gem 'ruby-debug', :platforms => :mri_18
end

group :production do
  gem 'pg'

  # Report on exceptions
  gem 'exception_notification', '~> 2.6.1'
end

group :default do
  gem 'json'

  gem 'jquery-rails'

  # For installing Bootstrap
  gem 'therubyracer'
  gem 'less-rails'
  gem 'less-rails-bootstrap'

  # For annotating models
  gem "annotate", "~> 2.5.0"
  gem 'bcrypt-ruby', "~> 3.0.1"

  gem 'single_test', :git => 'git://github.com/sebbacon/single_test.git'

  # For pagination
  gem 'will_paginate', '~> 3.0.5'

  # So we can dump and load plenty of sample data
  gem 'yaml_db', :git => 'git://github.com/lostapathy/yaml_db.git'

  # Helps us store attachments nicely
  gem 'carrierwave', :git => 'git://github.com/jnicklas/carrierwave.git'

  # Full-text search
  gem 'xapian-full-alaveteli', '~> 1.2.9.4'
  gem 'acts_as_xapian', '~> 0.2.6', :git => 'git://github.com/mysociety/acts_as_xapian_gem.git'

  # Queue for updating Alaveteli
  gem 'delayed_job', '~> 3.0.3'
  gem 'delayed_job_active_record'

  # For calling Alaveteli API
  gem 'multipart-post'
  gem 'daemons'
  gem 'htmlentities'

  # For generating PDF letters
  gem 'pdf-reader', '~> 1.2.0'
  gem 'prawn', '~> 0.12.0'

end

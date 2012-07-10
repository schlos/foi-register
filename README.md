# FOI Register
## Installation

    $ bundle exec install

Then arrange for the `delayed_job` daemon to start, e.g.:

    $ RAILS_ENV=production script/delayed_job start
    
See
[delayed job documentation](https://github.com/collectiveidea/delayed_job#running-jobs)
for more info.
    

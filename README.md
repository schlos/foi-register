# FOI Register
## Installation
1. Clone the repo:

    ```
    $ git clone git@github.com:mysociety/foi-register.git
    ```

2. Get the git submodules

    ```
    $ cd foi-register
    $ git submodule update --init
    ```
3. Install the required packages in `config/packages` using your package manager

4. Make sure you have the required version of Ruby from `.rvmrc` with:

    ```
    $ rvm install ruby-1.8.7-p302
    ```
5. Copy the settings in `config/database.yml-example` to `config/database.yml`
and adjust as appropriate.

6. Copy the settings in `config/general.yml-example` to `config/general.yml`
and adjust as appropriate.

7. Run the following:

    ```
    $ bundle install
    $ script/post-deploy
    ```
8. Then arrange for the `delayed_job` daemon to start, e.g.:

    ```
    $ RAILS_ENV=production script/delayed_job start
    ```

    See
    [delayed job documentation](https://github.com/collectiveidea/delayed_job#running-jobs)
    for more info.

## Running tests
To run all the tests, use:

```
$ bundle exec rake test
```

But see the notes in `config/test.yml`, some tests require a running Alaveteli
instance to test against, which you'll have to set up. If you want to skip
these tests, blank the setting `TEST_ALAVETELI_API_HOST` in `config/test.yml`

## Developing with Vagrant
An example vagrant file can be found in `config/Vagrantfile.example` - the
provisioning script sets up the basics for you, and has the neccessary settings
to let you run this code in a virtual machine. To use it, it's probably easiest
to copy it out to the parent directory, so that it sits alongside the
foi-register folder you cloned from git:

```
$ cp foi-register/config/Vagrantfile-example Vagrantfile
$ vagrant up
$ vagrant ssh
```

Now follow the instructions above, the code is in `/vagrant/foi-register`

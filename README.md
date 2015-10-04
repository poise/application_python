# Application_Python Cookbook

[![Build Status](https://img.shields.io/travis/poise/application_python.svg)](https://travis-ci.org/poise/application_python)
[![Gem Version](https://img.shields.io/gem/v/poise-application-python.svg)](https://rubygems.org/gems/poise-application-python)
[![Cookbook Version](https://img.shields.io/cookbook/v/application_python.svg)](https://supermarket.chef.io/cookbooks/application_python)
[![Coverage](https://img.shields.io/codecov/c/github/poise/application_python.svg)](https://codecov.io/github/poise/application_python)
[![Gemnasium](https://img.shields.io/gemnasium/poise/application_python.svg)](https://gemnasium.com/poise/application_python)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Chef](https://www.chef.io/) cookbook to deploy Python applications.

## Quick Start

To deploy a Django application from git:

```ruby
application '/srv/myapp' do
  git 'https://github.com/example/myapp.git'
  virtualenv
  pip_requirements
  django do
    database 'sqlite:///test_django.db'
    secret_key 'd78fe08df56c9'
    migrate true
  end
  gunicorn do
    port 8000
  end
end
```

## Requirements

Chef 12 or newer is required.

## Resources

### `application_celery_beat`

The `application_celery_beat` resource creates a service for the `celery beat`
process.

```ruby
application '/srv/myapp' do
  celery_beat do
    app_module 'myapp.tasks'
  end
end
```

#### Actions

* `:enable` – Create, enable and start the service. *(default)*
* `:disable` – Stop, disable, and destroy the service.
* `:start` – Start the service.
* `:stop` – Stop the service.
* `:restart` – Stop and then start the service.
* `:reload` – Send the configured reload signal to the service.

#### Properties

* `path` – Base path for the application. *(name attribute)*
* `app_module` – Celery application module. *(default: auto-detect)*
* `service_name` – Name of the service to create. *(default: auto-detect)*
# `user` – User to run the service as. *(default: application owner)*

### `application_celery_config`

The `application_celery_config` creates a `celeryconfig.py` configuration file.

```ruby
application '/srv/myapp' do
  celery_config do
    options do
      broker_url 'amqp://'
    end
  end
end
```

#### Actions

* `:deploy` – Create the configuration file. *(default)*

#### Properties

* `path` – Path to write the configuration file to. If given as a directory,
  create `path/celeryconfig.py`. *(name attribute)*
* `options` – Hash or block of options to set in the configuration file.

### `application_celery_worker`

The `application_celery_worker` resource creates a service for the
`celery worker` process.

```ruby
application '/srv/myapp' do
  celery_worker do
    app_module 'myapp.tasks'
  end
end
```

#### Actions

* `:enable` – Create, enable and start the service. *(default)*
* `:disable` – Stop, disable, and destroy the service.
* `:start` – Start the service.
* `:stop` – Stop the service.
* `:restart` – Stop and then start the service.
* `:reload` – Send the configured reload signal to the service.

#### Properties

* `path` – Base path for the application. *(name attribute)*
* `app_module` – Celery application module. *(default: auto-detect)*
* `service_name` – Name of the service to create. *(default: auto-detect)*
# `user` – User to run the service as. *(default: application owner)*

### `application_django`

The `application_django` resource creates configuration files and runs commands
for a Django application deployment.

```ruby
application '/srv/myapp' do
  django do
    database 'sqlite:///test_django.db'
    migrate true
  end
end
```

#### Actions

* `:deploy` – Create config files and run required deployments steps. *(default)*

#### Properties

* `path` – Base path for the application. *(name attribute)*
* `allowed_hosts` – Value for `ALLOWED_HOSTS` in the Django settings.
  *(default: [])*
* `collectstatic` – Run `manage.py collectstatic` during deployment.
  *(default: true)*
* `database` – Database settings for the default connection. See [the database
  section below](#database-parameters) for more information. *(option collector)*
* `debug` – Enable debug mode for Django. *(default: false)*
* `local_settings` – A [Poise template property](https://github.com/poise/poise#template-content)
  for the content of the local settings configuration file.
* `local_settings_path` – Path to write local settings to. If given as a
  relative path, will be expanded against path. Set to false to disable writing
  local settings. *(default: local_settings.py next to settings_module)*
* `migrate` – Run `manage.py migrate` during deployment. *(default: false)*
* `manage_path` – Path to `manage.py`. *(default: auto-detect)*
* `secret_key` – Value for `SECRET_KEY` in the Django settings. If unset, no
  key is added to the local settings.
* `settings_module` – Django settings module in dotted notation.
  *(default: auto-detect)*
* `syncdb` – Run `manage.py syncdb` during deployment. *(default: false)*
* `wsgi_module` – WSGI application module in dotted notation.
  *(default: auto-detect)*

#### Database Parameters

The database parameters can be set in three ways: URL, hash, and block.

If you have a single URL for the parameters, you can pass it directly to
`database`:

```ruby
django do
  database 'postgres://myuser@dbhost/myapp'
end
```

Passing a single URL will also set the `$DATABASE_URL` environment variable
automatically for compatibility with Heroku-based applications.

As with other option collector resources, you can pass individual settings as
either a hash or block:

```ruby
django do
  database do
    engine 'postgres'
    user 'myuser'
    host 'dbhost'
    name 'myapp'
  end
end

django do
  database({
    engine: 'postgres',
    user: 'myuser',
    host: 'dbhost',
    name: 'myapp',
  })
end
```

### `application_gunicorn`

The `application_gunicorn` resource creates a service for the
[Gunicorn](http://gunicorn.org/) application server.

```ruby
application '/srv/myapp' do
  gunicorn do
    port 8000
    preload_app true
  end
end
```

#### Actions

* `:enable` – Create, enable and start the service. *(default)*
* `:disable` – Stop, disable, and destroy the service.
* `:start` – Start the service.
* `:stop` – Stop the service.
* `:restart` – Stop and then start the service.
* `:reload` – Send the configured reload signal to the service.

#### Properties

* `path` – Base path for the application. *(name attribute)*
* `app_module` – WSGI module to run as an application. *(default: auto-detect)*
* `bind` – One or more addresses/ports to bind to.
* `config` – Path to a Guncorn configuration file.
* `preload_app` – Enable code preloading. *(default: false)*
* `port` – Port to listen on. Alias for `bind("0.0.0.0:#{port}")`.
* `service_name` – Name of the service to create. *(default: auto-detect)*
# `user` – User to run the service as. *(default: application owner)*
* `version` – Version of Gunicorn to install. If set to true, use the latest
  version. If set to false, do not install Gunicorn. *(default: true)*

### `application_pip_requirements`

The `application_pip_requirements` resource installs Python packages based on a
`requirements.txt` file.

```ruby
application '/srv/myapp' do
  pip_requirements
end
```

All actions and properties are the same as the [`pip_requirements` resource](https://github.com/poise/poise-python#pip_requirements).

### `application_python`

The `application_python` resource installs a Python runtime for the deployment.

```ruby
application '/srv/myapp' do
  python '2.7'
end
```

All actions and properties are the same as the [`python_runtime` resource](https://github.com/poise/poise-python#python_runtime).

### `application_python_execute`

The `application_python_execute` resource runs Python commands for the deployment.

```ruby
application '/srv/myapp' do
  python_execute 'setup.py install'
end
```

All actions and properties are the same as the [`python_execute` resource](https://github.com/poise/poise-python#python_execute),
except that the `cwd`, `environment`, `group`, and `user` properties default to
the application-level data if not specified.

### `application_python_package`

The `application_python_package` resource installs Python packages for the deployment.

```ruby
application '/srv/myapp' do
  python_package 'requests'
end
```

All actions and properties are the same as the [`python_package` resource](https://github.com/poise/poise-python#python_package),
except that the `group` and `user` properties default to the application-level
data if not specified.

### `application_virtualenv`

The `application_virtualenv` resource creates a Python virtualenv for the
deployment.

```ruby
application '/srv/myapp' do
  virtualenv
end
```

If no path property is given, the default is to create a `.env/` inside the
application deployment path.

All actions and properties are the same as the [`python_virtualenv` resource](https://github.com/poise/poise-python#python_virtualenv).

## Examples

Some test recipes are available as examples for common application frameworks:

* [Flask](https://github.com/poise/application_python/blob/master/test/cookbooks/application_python_test/recipes/flask.rb)
* [Django](https://github.com/poise/application_python/blob/master/test/cookbooks/application_python_test/recipes/django.rb)

## Sponsors

Development sponsored by [Chef Software](https://www.chef.io/), [Symonds & Son](http://symondsandson.com/), and [Orion](https://www.orionlabs.co/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

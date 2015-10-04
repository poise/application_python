#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'

require 'chef/provider'
require 'chef/resource'
require 'poise'
require 'poise_application'
require 'poise_python'

require 'poise_application_python/app_mixin'
require 'poise_application_python/error'


module PoiseApplicationPython
  module Resources
    # (see Django::Resource)
    # @since 4.0.0
    module Django
      # Aliases for Django database engine names. Based on https://github.com/kennethreitz/dj-database-url/blob/master/dj_database_url.py
      # Copyright 2014, Kenneth Reitz.
      ENGINE_ALIASES = {
        'postgres' => 'django.db.backends.postgresql_psycopg2',
        'postgresql' => 'django.db.backends.postgresql_psycopg2',
        'pgsql' => 'django.db.backends.postgresql_psycopg2',
        'postgis' => 'django.contrib.gis.db.backends.postgis',
        'mysql2' => 'django.db.backends.mysql',
        'mysqlgis' => 'django.contrib.gis.db.backends.mysql',
        'spatialite' => 'django.contrib.gis.db.backends.spatialite',
        'sqlite' => 'django.db.backends.sqlite3',
      }

      # An `application_django` resource to configure Django applications.
      #
      # @since 4.0.0
      # @provides application_django
      # @action deploy
      # @example
      #   application '/srv/myapp' do
      #     git '...'
      #     pip_requirements
      #     django do
      #       database do
      #         host node['db_host']
      #       end
      #     end
      #     gunicorn do
      #       port 8080
      #     end
      #   end
      class Resource < Chef::Resource
        include PoiseApplicationPython::AppMixin
        provides(:application_django)
        actions(:deploy)

        # @!attribute allowed_hosts
        #   Value for `ALLOWED_HOSTS` in the Django settings.
        #   @return [String, Array<String>]
        attribute(:allowed_hosts, kind_of: [String, Array], default: lazy { [] })
        # @!attribute collectstatic
        #   Set to false to disable running manage.py collectstatic during
        #   deployment.
        #   @todo This could auto-detect based on config vars in settings?
        #   @return [Boolean]
        attribute(:collectstatic, equal_to: [true, false], default: true)
        # @!attribute database
        #   Option collector attribute for Django database configuration.
        #   @return [Hash]
        #   @example Setting via block
        #     database do
        #       engine 'postgresql'
        #       database 'blog'
        #     end
        #   @example Setting via URL
        #     database 'postgresql://localhost/blog'
        attribute(:database, option_collector: true, parser: :parse_database_url, forced_keys: %i{name})
        # @!attribute debug
        #   Enable debug mode for Django.
        #   @note
        #     If you use this in production you will get everything you deserve.
        #   @return [Boolean]
        attribute(:debug, equal_to: [true, false], default: false)
        # @!attribute group
        #   Owner for the Django application, defaults to application group.
        #   @return [String]
        attribute(:group, kind_of: String, default: lazy { parent && parent.group })
        # @!attribute local_settings
        #   Template content attribute for the contents of local_settings.py.
        #   @todo Redo this doc to cover the actual attributes created.
        #   @return [Poise::Helpers::TemplateContent]
        attribute(:local_settings, template: true, default_source: 'settings.py.erb', default_options: lazy { default_local_settings_options })
        # @!attribute local_settings_path
        #   Path to write local settings to. If given as a relative path,
        #   will be expanded against {#path}. Set to false to disable writing
        #   local settings. Defaults to local_settings.py next to
        #   {#setting_module}.
        #   @return [String, nil false]
        attribute(:local_settings_path, kind_of: [String, NilClass, FalseClass], default: lazy { default_local_settings_path })
        # @!attribute migrate
        #   Run database migrations. This is a bad idea for real apps. Please
        #   do not use it.
        #   @return [Boolean]
        attribute(:migrate, equal_to: [true, false], default: false)
        # @!attribute manage_path
        #   Path to manage.py. Defaults to scanning for the nearest manage.py
        #   to {#path}.
        #   @return [String]
        attribute(:manage_path, kind_of: String, default: lazy { default_manage_path })
        # @!attribute owner
        #   Owner for the Django application, defaults to application owner.
        #   @return [String]
        attribute(:owner, kind_of: String, default: lazy { parent && parent.owner })
        # @!attribute secret_key
        #   Value for `SECRET_KEY` in the Django settings. If unset, no key is
        #   added to the local settings.
        #   @return [String, false]
        attribute(:secret_key, kind_of: [String, FalseClass])
        # @!attribute settings_module
        #   Django settings module in dotted notation. Set to false to disable
        #   anything related to settings. Defaults to scanning for the nearest
        #   settings.py to {#path}.
        #   @return [Boolean]
        attribute(:settings_module, kind_of: [String, NilClass, FalseClass], default: lazy { default_settings_module })
        # @!attribute syncdb
        #   Run database sync. This is a bad idea for real apps. Please do not
        #   use it.
        #   @return [Boolean]
        attribute(:syncdb, equal_to: [true, false], default: false)
        # @!attribute wsgi_module
        #   WSGI application module in dotted notation. Set to false to disable
        #   anything related to WSGI. Defaults to scanning for the nearest
        #   wsgi.py to {#path}.
        #   @return [Boolean]
        attribute(:wsgi_module, kind_of: [String, NilClass, FalseClass], default: lazy { default_wsgi_module })

        private

        # Default value for {#local_settings_options}. Adds Django settings data
        # from the resource to be rendered in the local settings template.
        #
        # @return [Hash]
        def default_local_settings_options
          {}.tap do |options|
            options[:allowed_hosts] = Array(allowed_hosts)
            options[:databases] = {}
            options[:databases]['default'] = database.inject({}) do |memo, (key, value)|
              key = key.to_s.upcase
              # Deal with engine aliases here too, just in case.
              value = resolve_engine(value) if key == 'ENGINE'
              memo[key] = value
              memo
            end
            options[:debug] = debug
            options[:secret_key] = secret_key
          end
        end

        # Default value for {#local_settings_path}, local_settings.py next to
        # the configured {#settings_module}.
        #
        # @return [String, nil]
        def default_local_settings_path
          # If no settings module, no default local settings.
          return unless settings_module
          settings_path = PoisePython::Utils.module_to_path(settings_module, path)
          ::File.expand_path(::File.join('..', 'local_settings.py'), settings_path)
        end

        # Default value for {#manage_path}, searches for manage.py in the
        # application path.
        #
        # @return [String, nil]
        def default_manage_path
          find_file('manage.py')
        end

        # Default value for {#settings_module}, searches for settings.py in the
        # application path.
        #
        # @return [String, nil]
        def default_settings_module
          settings_path = find_file('settings.py')
          if settings_path
            PoisePython::Utils.path_to_module(settings_path, path)
          else
            nil
          end
        end

        # Default value for {#wsgi_module}, searchs for wsgi.py in the
        # application path.
        #
        # @return [String, nil]
        def default_wsgi_module
          wsgi_path = find_file('wsgi.py')
          if wsgi_path
            PoisePython::Utils.path_to_module(wsgi_path, path)
          else
            nil
          end
        end

        # Format a URL for DATABASES.
        #
        # @return [Hash]
        def parse_database_url(url)
          parsed = URI(url)
          {}.tap do |db|
            # Store this for use later in #set_state, and maybe future use by
            # Django in some magic world where operability happens.
            db[:URL] = url
            db[:ENGINE] = resolve_engine(parsed.scheme)
            # Strip the leading /.
            path = parsed.path ? parsed.path[1..-1] : parsed.path
            # If we are using SQLite, make it an absolute path.
            path = ::File.expand_path(path, self.path) if db[:ENGINE].include?('sqlite')
            db[:NAME] = path if path && !path.empty?
            db[:USER] = parsed.user if parsed.user && !parsed.user.empty?
            db[:PASSWORD] = parsed.password if parsed.password && !parsed.password.empty?
            db[:HOST] = parsed.host if parsed.host && !parsed.host.empty?
            db[:PORT] = parsed.port if parsed.port && !parsed.port.empty?
          end
        end

        # Search for a file somewhere under the application path. Prefers files
        # closer to the root, then sort alphabetically for stability.
        #
        # @param name [String] Filename to search for.
        # @return [String, nil]
        def find_file(name)
          num_separators = lambda do |path|
            if ::File::ALT_SEPARATOR && path.include?(::File::ALT_SEPARATOR)
              # :nocov:
              path.count(::File::ALT_SEPARATOR)
              # :nocov:
            else
              path.count(::File::SEPARATOR)
            end
          end
          Dir[::File.join(path, '**', name)].min do |a, b|
            cmp = num_separators.call(a) <=> num_separators.call(b)
            if cmp == 0
              cmp = a <=> b
            end
            cmp
          end
        end

        # Resolve Django database engine from shortname to dotted module.
        #
        # @param name [String, nil] Engine name.
        # @return [String, nil]
        def resolve_engine(name)
          if name && !name.empty? && !name.include?('.')
            ENGINE_ALIASES[name] || "django.db.backends.#{name}"
          else
            name
          end
        end

      end

      # Provider for `application_django`.
      #
      # @since 4.0.0
      # @see Resource
      # @provides application_django
      class Provider < Chef::Provider
        include PoiseApplicationPython::AppMixin
        provides(:application_django)

        # `deploy` action for `application_django`. Ensure all configuration
        # files are created and other deploy tasks resolved.
        #
        # @return [void]
        def action_deploy
          set_state
          notifying_block do
            write_config
            run_syncdb
            run_migrate
            run_collectstatic
          end
        end

        private

        # Set app_state variables for future services et al.
        def set_state
          # Set environment variables for later services.
          new_resource.app_state_environment[:DJANGO_SETTINGS_MODULE] = new_resource.settings_module if new_resource.settings_module
          new_resource.app_state_environment[:DATABASE_URL] = new_resource.database[:URL] if new_resource.database[:URL]
          # Set the app module.
          new_resource.app_state[:python_wsgi_module] = new_resource.wsgi_module if new_resource.wsgi_module
        end

        # Create the database using the older syncdb command.
        def run_syncdb
          manage_py_execute('syncdb', '--noinput') if new_resource.syncdb
        end

        # Create the database using the newer migrate command. This should work
        # for either South or the built-in migrations support.
        def run_migrate
          manage_py_execute('migrate', '--noinput') if new_resource.migrate
        end

        # Run the asset pipeline.
        def run_collectstatic
          manage_py_execute('collectstatic', '--noinput') if new_resource.collectstatic
        end

        # Create the local config settings.
        def write_config
          # Allow disabling the local settings.
          return unless new_resource.local_settings_path
          file new_resource.local_settings_path do
            content new_resource.local_settings_content
            mode '640'
            owner new_resource.owner
            group new_resource.group
          end
        end

        # Run a manage.py command using `python_execute`.
        def manage_py_execute(*cmd)
          raise PoiseApplicationPython::Error.new("Unable to find a find a manage.py for #{new_resource}, please set manage_path") unless new_resource.manage_path
          python_execute "manage.py #{cmd.join(' ')}" do
            python_from_parent new_resource
            command [::File.expand_path(new_resource.manage_path, new_resource.path)] + cmd
            cwd new_resource.path
            environment new_resource.app_state_environment
            group new_resource.group
            user new_resource.owner
          end
        end

      end
    end
  end
end

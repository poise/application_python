application "packaginator" do
  path "/srv/packaginator"
  owner "nobody"
  group "nogroup"
  repository "https://github.com/coderanger/packaginator.git"
  revision "master"
  migrate true
  packages ["libpq-dev", "git-core", "mercurial"]

  django do
    packages ["redis"]
    requirements "requirements/mkii.txt"
    settings_template "settings.py.erb"
    debug true
    collectstatic "build_static --noinput"
    database do
      database "packaginator"
      engine "postgresql_psycopg2"
      username "packaginator"
      password "awesome_password"
    end
    database_master_role "packaginator_database_master"
  end

  gunicorn do
    only_if { node['roles'].include? 'packaginator_application_server' }
    app_module :django
    port 8080
  end

  celery do
    only_if { node['roles'].include? 'packaginator_application_server' }
    config "celery_settings.py"
    django true
    celerybeat true
    celerycam true
    broker do
      transport "redis"
    end
  end

  nginx_load_balancer do
    only_if { node['roles'].include? 'packaginator_load_balancer' }
    application_port 8080
    static_files "/site_media" => "site_media"
  end

end

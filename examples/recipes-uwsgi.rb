
application "celeryproject" do
  packages   %w{ git-core }
  path       "/srv/celeryproject"
  owner      "nobody"
  group      "nogroup"
  repository "https://github.com/celery/celeryproject.git"
  revision   "master"
  migrate    true

  django do
    requirements        "requirements.txt"
    collectstatic       true
    settings_template   "local_settings.py.erb"
    local_settings_file "celeryproject/settings/production.py"
    environment ({
      "DJANGO_SETTINGS_MODULE" => "celeryproject.settings.production",
      "SECRET_KEY" => "1304yioksndflkn1o34y0iogbdkoah98ryio123nrp1y9734pih1n340y"
    })
  end

  uwsgi do
    workers    2
    app_module "celeryproject.wsgi:application"
    environment ({
      "DJANGO_SETTINGS_MODULE" => "celeryproject.settings.production",
      "SECRET_KEY" => "1304yioksndflkn1o34y0iogbdkoah98ryio123nrp1y9734pih1n340y"
    })
  end

  nginx_load_balancer do
    hosts [ "127.0.0.1" ]
    application_port 8080
    static_files "/static" => "static"
  end
end

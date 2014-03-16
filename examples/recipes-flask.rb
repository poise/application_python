
application "flask-website" do
  packages   %w{ git-core }
  path       "/srv/flask-website"
  owner      "nobodoy"
  group      "nogroup"
  repository "https://github.com/mitsuhiko/flask.git"
  revision   "website"
  migrate    true

  flask do
    requirements "requirements.txt"
  end

  gunicorn do
    workers 2
    requirements "requirements.txt"
    app_module "flask_website:app"
    port 8080
  end

  nginx_load_balancer do
    hosts [ "127.0.0.1" ]
    application_port 8080
    static_files "/static" => "flask_website/static"
  end
end

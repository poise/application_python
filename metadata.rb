name             "application_python"
maintainer       "Opscode, Inc."
maintainer_email "cookbooks@opscode.com"
license          "Apache 2.0"
description      "Deploys and configures Python-based applications"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.2.2"

%w{ application python gunicorn supervisor }.each do |cb|
  depends cb
end

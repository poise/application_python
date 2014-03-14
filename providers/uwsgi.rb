#
# Author:: Jonathon W. Marshall <jonathon@bnotions.com>
# Cookbook Name:: application_python
# Provider:: uwsgi
#

require 'tmpdir'

include Chef::DSL::IncludeRecipe

action :before_compile do

  include_recipe "supervisor"

  if !new_resource.restart_command
    r = new_resource
    new_resource.restart_command do
      run_context.resource_collection.find(:supervisor_service => r.application.name).run_action(:restart)
    end
  end

  raise "You must specify an application module to load" unless new_resource.app_module

end

action :before_deploy do

  django_resource = new_resource.application.sub_resources.select{|res| res.type == :django}.first
  if django_resource && new_resource.virtualenv.nil?
    new_resource.virtualenv django_resource.virtualenv
  end

  install_packages

  python_pip "uwsgi" do
    virtualenv new_resource.virtualenv
    action :install
  end

  template "#{new_resource.application.path}/shared/uwsgi.ini" do
    mode 00644
    source new_resource.settings_template || "uwsgi.ini.erb"
    cookbook new_resource.settings_template ? new_resource.cookbook_name.to_s : "application_python"
    variables({
      :uwsgi => {
        :home => new_resource.virtualenv,
        :chdir => new_resource.directory ? new_resource.directory : ::File.join(new_resource.application.path, "current"),
        :master => new_resource.master,
        :module => new_resource.app_module,
        :socket => new_resource.socket,
        :protocol => new_resource.protocol,
        :workers => new_resource.workers,
        :extra_options => new_resource.extra_options
      }
    })
  end

  supervisor_service new_resource.application.name do
    action :enable
    environment new_resource.environment
    base_command = new_resource.virtualenv.nil? ? "uwsgi" : ::File.join(new_resource.virtualenv, "bin", "uwsgi")
    command "#{base_command} --ini #{new_resource.application.path}/shared/uwsgi.ini"
    directory new_resource.directory ? new_resource.directory : ::File.join(new_resource.application.path, "current")
    autostart new_resource.autostart
    user new_resource.owner
  end

end

action :before_migrate do

  install_requirements

end

action :before_symlink do
end

action :before_restart do
end

action :after_restart do
end

protected

def install_packages
  new_resource.packages.each do |name, ver|
    python_pip do
      version if ver && ver.length > 0
      virtualenv new_resource.virtualenv
      action :install
    end
  end
end

def install_requirements
  if new_resource.requirements.nil?
    # look for requirements.txt files in common locations
    [
      ::File.join(new_resource.release_path, "requirements", "#{node.chef_environment}.txt"),
      ::File.join(new_resource.release_path, "requirements.txt")
    ].each do |path|
      if ::File.exists?(path)
        new_resource.requirements path
        break
      end
    end
  end
  if new_resource.requirements
    Chef::Log.info("Installing using requirements file: #{new_resource.requirements}")
    # TODO normalise with python/providers/pip.rb 's pip_cmd
    if new_resource.virtualenv.nil?
      pip_cmd = 'pip'
    else
      pip_cmd = ::File.join(new_resource.virtualenv, 'bin', 'pip')
    end
    execute "#{pip_cmd} install --src=#{Dir.tmpdir} -r #{new_resource.requirements}" do
      cwd new_resource.release_path
    end
  else
    Chef::Log.debug("No requirements file found")
  end
end

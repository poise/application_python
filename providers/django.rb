#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application_python
# Provider:: django
#
# Copyright:: 2011, Opscode, Inc <legal@opscode.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Chef::Mixin::LanguageIncludeRecipe

action :before_compile do

  include_recipe 'python'

  new_resource.migration_command "#{::File.join(new_resource.virtualenv, "bin", "python")} manage.py syncdb --migrate --noinput" if !new_resource.migration_command

  new_resource.symlink_before_migrate.update({
    new_resource.local_settings_base => new_resource.local_settings_file,
  })
end

action :before_deploy do

  python_virtualenv new_resource.virtualenv do
    path new_resource.virtualenv
    action :create
  end

  new_resource.packages.each do |name, ver|
    python_pip name do
      version ver if ver && ver.length > 0
      virtualenv new_resource.virtualenv
      action :install
    end
  end

  dbm = new_resource.find_matching_role(new_resource.database_master_role)
  Chef::Log.warn("No node with role #{new_resource.database_master_role}") if new_resource.database_master_role && !dbm

  template "#{new_resource.path}/shared/#{new_resource.local_settings_base}" do
    source new_resource.settings_template || "settings.py.erb"
    cookbook new_resource.settings_template ? new_resource.cookbook_name : "application_django"
    owner new_resource.owner
    group new_resource.group
    mode "644"
    variables new_resource.settings.clone
    variables.update :debug => new_resource.debug, :database => {
      :host => (dbm.attribute?('cloud') ? dbm['cloud']['local_ipv4'] : dbm['ipaddress']),
      :settings => new_resource.database,
      :legacy => new_resource.legacy_database_settings
    }
  end

end

action :before_migrate do

  if new_resource.requirements.nil?
    # look for requirements.txt files in common locations
    [
      ::File.join(new_resource.path, "requirements", "#{node[:chef_environment]}.txt"),
      ::File.join(new_resource.path, "requirements.txt")
    ].each do |path|
      if ::File.exists?(path)
        new_resource.requirements path
        break
      end
    end
  end
  if new_resource.requirements
    Chef::Log.info("Installing using requirements file: #{new_resource.requirements}")
    execute "pip install -E #{new_resource.virtualenv} -r #{new_resource.requirements}" do
      cwd new_resource.release_path
    end
  else
    Chef::Log.debug("No requirements file found")
  end

end

action :before_symlink do

  if new_resource.collectstatic
    cmd = new_resource.collectstatic.is_a?(String) ? new_resource.collectstatic : "collectstatic --noinput"
    execute "#{::File.join(new_resource.virtualenv, "bin", "python")} manage.py #{cmd}" do
      user new_resource.owner
      group new_resource.group
      cwd new_resource.release_path
    end
  end

  ruby_block "remove_run_migrations" do
    block do
      if node.role?("#{new_resource.application.name}_run_migrations")
        Chef::Log.info("Migrations were run, removing role[#{new_resource.id}_run_migrations]")
        node.run_list.remove("role[#{new_resource.id}_run_migrations]")
      end
    end
  end

end

action :before_restart do
end

action :after_restart do
end


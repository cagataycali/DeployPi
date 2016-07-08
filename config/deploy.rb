set :branch, 'your-awesome-branch'
set :application, 'deployment'
set :repo_url, "git@github.com:ccali14/test.git"
set :deploy_to, "/home/ubuntu/apps/#{fetch(:application)}"
set :keep_releases, 1

set :copy_exclude, %w(.git/* tmp/*)

set :linked_dirs, %w{log tmp/pids tmp/cache vendor/bundle tmp/sockets}
# set :linked_files, %w{config.js}

set :assets_roles, [:web, :app]

set :npm_target_path, -> { release_path } # default not set
set :npm_flags, '--silent --no-spin' # default
set :npm_roles, :all                              # default
set :npm_env_variables, {}

if ENV['VIA_ADMIN']
  require 'net/ssh/proxy/command'
  ssh_command = 'ssh ubuntu@xxxxxx.amazonaws.com -W %h:%p'

  set :ssh_options, proxy: Net::SSH::Proxy::Command.new(ssh_command)
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  task :npm_install do
    on roles fetch(:npm_roles) do
      within fetch(:npm_target_path, release_path) do
        with fetch(:npm_env_variables, {}) do
          execute :npm, 'install', fetch(:npm_flags)
        end
      end
    end
  end

  task :npm_build do
    on roles fetch(:npm_roles) do
      within fetch(:npm_target_path, release_path) do
        with fetch(:npm_env_variables, {}) do
          # execute :npm, 'install babel-polyfill', fetch(:npm_flags)
        end
      end
    end
  end

  task :npm_build do
    on roles fetch(:npm_roles) do
      within fetch(:npm_target_path, release_path) do
        with fetch(:npm_env_variables, {}) do
          # execute "pm2 delete #{fetch(:application)}-#{fetch(:branch)} && pm2 start /home/ec2-user/apps/#{fetch(:application)}/#{fetch(:branch)}/current/dist/index.js --name='#{fetch(:application)}-#{fetch(:branch)}'"
        end
      end
    end
  end


  task :deploy_complete do
    on roles(:app) do
      execute 'echo -----------------------------'
      execute "echo DEPLOYMENT COMPLETED - release - #{release_path}"
    end
  end


  # after :publishing, :permissions
  after :publishing, :restart
  after :publishing, :npm_install
  after :publishing, :npm_build
  after :finished,  'deploy:deploy_complete'
  after :finished,  'deploy:cleanup'
end

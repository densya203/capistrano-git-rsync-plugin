require 'capistrano/scm/plugin'

class Capistrano::SCM
  class GitRsync < ::Capistrano::SCM::Plugin
    def set_defaults
       # command-line options for rsync
      set_if_empty :rsync_options, %w[--archive --delete --exclude=.git*]

      # Local cache (Git checkout will be happen here, resulting files then get rsynced to the remote server)
      set_if_empty :rsync_local_cache, "/usr/local/src/capistrano-rsync-deploy/fetch(:application)/#{fetch(:stage)}"
    end

    def define_tasks
      namespace :rsync do
        desc <<-DESC
            Copy application source code from (remote) cache to release path.

            If a :rsync_deploy_build_path is set, only that relative path will \
            be copied to the release path.
        DESC
        task create_release: :update_local_cache do
          on release_roles :all do

            # Select oldest release number
            can_be_discarded_release_number = capture(:ls, "-xt", releases_path).split.sort.first

            if can_be_discarded_release_number
              discarding_release_path = releases_path.join(can_be_discarded_release_number)

              # Set oldest release to this time release target.
              # Better than starting empty directory, In many cases.
              execute :mv, discarding_release_path, release_path
            end

            execute :rsync, '--archive', "#{fetch(:rsync_local_cache)}/", "#{release_path}/"
          end
        end

        desc <<-DESC
            Update local cache of application source code.

            This will be checked out to :rsync_local_cache.
        DESC
        task :update_local_cache do
          on release_roles :all do |role|
            within fetch(:rsync_local_cache) do
              repo_exists = (capture "if [ -e #{fetch(:rsync_local_cache)}/.git ];then echo yes;fi")
              if repo_exists != 'yes'
                execute :mkdir, '-p', fetch(:rsync_local_cache)
                execute :git, :clone, '--quiet', repo_url, fetch(:rsync_local_cache)
              end

              execute :git, :fetch, '--quiet', '--all', '--prune'
              execute :git, :checkout, fetch(:branch)
              execute :git, :reset, '--quiet', '--hard', "origin/#{fetch(:branch)}"
            end
          end
        end

        desc <<-DESC
            Determine version of code that rsync will deploy.

            By default, this is the latest version of the code on branch :branch.
        DESC
        task :set_current_revision do
          on release_roles :all do |role|
            within fetch(:rsync_local_cache) do
              set :current_revision, capture(:git, "rev-list --max-count=1 #{fetch(:branch)}")
            end
          end
        end
      end
    end

    def register_hooks
      after 'deploy:new_release_path', 'rsync:create_release'
      before 'deploy:set_current_revision', 'rsync:set_current_revision'
    end
  end
end

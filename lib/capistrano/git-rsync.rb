require 'capistrano/scm/plugin'

class Capistrano::SCM
  class GitRsync < ::Capistrano::SCM::Plugin
    def set_defaults
      # command-line options for rsync
      # Without -t option (timestamp)
      set_if_empty :rsync_options, %w[--archive --human-readable --verbose --delete --exclude=.git*]

      # Local cache (Git checkout will happen here, resulting files then get rsynced to the remote server)
      set_if_empty :git_checkout_to, "/usr/local/src/capistrano-rsync-deploy/#{fetch(:application)}/#{fetch(:stage)}"

      # shallow clone depth for git clone and fetch. This is to prevent the local cache from having too much history,
      # which can make git operations slow.
      set_if_empty :git_shallow_clone_depth, 10
    end

    def define_tasks
      namespace :git_rsync do
        desc <<-DESC
            Copy application source code from (remote) cache to release path.

        DESC
        task create_release: :update_local_cache do
          on release_roles :all do

            # Select oldest release number
            can_be_discarded_release_number = capture(:ls, releases_path).split.sort.first

            if can_be_discarded_release_number
              discarding_release_path = releases_path.join(can_be_discarded_release_number)

              # Set oldest release to this time release target.
              # Better than starting from empty directory, In many cases.
              execute :mv, discarding_release_path, release_path
            end

            # Without -t option (timestamp)
            execute :rsync, *fetch(:rsync_options), "#{fetch(:git_checkout_to)}/", "#{release_path}/"
          end
        end

        desc <<-DESC
            Update local cache of application source code.

            This will be checked out to :git_checkout_to.
        DESC
        task :update_local_cache do
          on release_roles :all do
            # Set the depth for git operations from the variable
            depth = fetch(:git_shallow_clone_depth).to_s

            unless test("[ -e #{fetch(:git_checkout_to)}/.git ]")
              execute :mkdir, '-p', fetch(:git_checkout_to)

              # Specify --depth when cloning
              execute :git, :clone, '--depth', depth, '--quiet', repo_url, fetch(:git_checkout_to)
            end

            within fetch(:git_checkout_to) do
              # Specify --depth when fetching to prevent history from becoming too deep
              execute :git, :fetch, '--depth', depth, '--quiet', 'origin', fetch(:branch)
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
          on release_roles(:all).first do
            within fetch(:git_checkout_to) do
              set :current_revision, capture(:git, 'rev-list', '--max-count=1', fetch(:branch))
            end
          end
        end
      end
    end

    def register_hooks
      after  'deploy:new_release_path'    , 'git_rsync:create_release'
      before 'deploy:set_current_revision', 'git_rsync:set_current_revision'
    end
  end
end
# capistrano-git-rsync-plugin

A Capistrano 3.7+ plugin that deploys by running `git fetch` on the release host and then syncing with `rsync`, instead of using `git archive`. Forked from [infovore/capistrano-rsync-plugin](https://github.com/infovore/capistrano-rsync-plugin).

## Why?

`Capistrano::SCM::Git#archive_to_release_path` re-archives the entire repository on every deploy, which is slow for large repos (many files, large assets, etc.). This plugin avoids that by:

1. Keeping a local Git working copy (`:git_checkout_to`) on each release host and running `git fetch` + `git reset --hard` on it.
2. Reusing the **oldest existing release directory** as the base for the new release before rsyncing. This minimises the rsync diff and makes deploys faster when only a few files change.
3. Using a **shallow clone** (`:git_shallow_clone_depth`, default `1`) to keep the on-host clone small and fast.

The fewer files that changed between the oldest kept release and the new release, the faster the deploy. Setting `:keep_releases` to `2` (the minimum) gives the best performance.

### Requirements

- The release host must be able to reach the Git remote (e.g. via HTTPS to AWS CodeCommit, GitHub, etc.).
- Capistrano ≥ 3.7.1

## Installation

Add to your application's `Gemfile`:

```ruby
gem 'capistrano-git-rsync-plugin', github: 'densya203/capistrano-git-rsync-plugin'
```

Then run:

    $ bundle install

Add to your `Capfile` **after** `require "capistrano/deploy"`:

```ruby
require "capistrano/git-rsync"
install_plugin Capistrano::SCM::GitRsync
```

## Usage

Set the following variables in `deploy.rb` or `config/deploy/<stage>.rb`:

```ruby
# Git remote URL accessible from the release host
set :repo_url, "https://YOUR_REPOSITORY_URL"

# Path on the release host where the Git working copy is kept
set :git_checkout_to, "/PATH/TO/GIT_WORKING_DIR_ON_RELEASE_HOST"

# Must be >= 2; 2 is recommended for fastest deploys
set :keep_releases, 2
```

Tasks run on `release_roles :all`.

## Configuration

All options and their defaults:

| Option | Default | Description |
|---|---|---|
| `:rsync_options` | `%w[--archive --human-readable --verbose --delete --exclude=.git*]` | Options passed to the `rsync` command. |
| `:rsync_extra_options` | `[]` | Additional rsync options appended after `:rsync_options`. |
| `:git_checkout_to` | `"/usr/local/src/capistrano-rsync-deploy/<app>/<stage>"` | Path on the release host for the local Git working copy. |
| `:git_shallow_clone_depth` | `1` | Depth for `git clone --depth` and `git fetch --depth`. Keeps history shallow to speed up Git operations. |

Example overrides:

```ruby
set :rsync_options, %w[--archive --delete --exclude=.git* --exclude=node_modules]
set :rsync_extra_options, %w[--checksum]
set :git_shallow_clone_depth, 5
```

## How It Works

1. **`git_rsync:update_local_cache`** — On each release host, clones the repo (shallow) if no working copy exists, then fetches the target branch and resets to `FETCH_HEAD`.
2. **`git_rsync:create_release`** — Moves the oldest existing release directory to `release_path` (so rsync starts from a similar baseline), then rsyncs the working copy into `release_path`.
3. **`git_rsync:set_current_revision`** — Captures `git rev-parse HEAD` from the working copy and sets `:current_revision`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/densya203/capistrano-git-rsync-plugin.

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

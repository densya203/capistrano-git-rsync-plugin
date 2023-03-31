# Capistrano 3.7.1+ rsync after git pull plugin

infovore さんの capistrano-rsync-plugin からフォークさせていただいた Capistrano プラグインです。

`Capistrano::SCM::Git#archive_to_release_path` に時間がかかりすぎるリポジトリのために作りました。

`git archive` の代わりに、公開サーバ上にクローンしてある作業コピー（`:git_checkout_to`）で `git fetch` して、`release_path` に `rsync` します。

本来 `release_path` は新規で作られますが、`rsync` 前に一番古いリリースを`release_path` に置き換えて再利用する処理を入れておくことで、差分がなるべく少なくなるようにしています。

一番古いリリースと今回のリリースに差分が少なければ少ないほど（= `:keep_releases` の値が少ないほど）、リリースは高速になります。ちょっとしたソースの変更でも毎回 `git archive` を食らって世の中の厳しさを感じていた人には解ってもらえるツールかもしれません。

公開サーバから `git fetch` できる環境の存在が前提です。（私の環境では AWS CodeCommit の HTTPS）

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-git-rsync-plugin'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-git-rsync-plugin

Then, add this to your `Capfile` after loading `capistrano/deploy`

```ruby
require "capistrano/git-rsync"
install_plugin Capistrano::SCM::GitRsync
```

## Usage

デプロイ設定ファイル（`deploy.rb` や `config/deploy/STAGE_NAME.rb`）で次の変数をセットしてください。


```ruby
set :repo_url, "https://YOUR_REPOSITY_URL_WHICH_CAN_GIT_PULL_AT_RELEASE_HOST"

set :git_checkout_to , "/PATH/TO/GIT_WORKING_DIR_AT_RELEASE_HOST"

set :keep_releases, 2   # Must be equal to or greater than 2. 2 is recommended.
```

`on release_roles :all` で実行されます。

## Configuration

Configuration option `:rsync_options` lets you specify options for the RSync command. The default is equivalent to:

```ruby
set :rsync_options, %w[--archive --human-readable --verbose --delete --exclude=.git*]
```

The remote cache directory, relative to the deploy root, is set via `:git_checkout_to`, and is equivalent to:

```ruby
set :git_checkout_to, "/usr/local/src/capistrano-rsync-deploy/fetch(:application)/#{fetch(:stage)}"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/densya203?tab=repositories .

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

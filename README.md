# exercism-rb

`xrb` is a small CLI that removes friction from the Exercism Ruby workflow.

It remembers the current exercise, runs commands from the right exercise directory, opens your editor, starts IRB with the solution file loaded, runs tests, and submits the solution file without requiring manual `cd` work.

This is an independent helper for the Exercism Ruby track, not an official Exercism project.

## Install

Install from RubyGems:

```bash
gem install exercism-rb
```

Make sure your RubyGems executable directory is in your `PATH`, then verify the CLI:

```bash
xrb version
```

To update:

```bash
gem update exercism-rb
```

## Requirements

- Ruby 3.2+
- Exercism CLI for `xrb new` and `xrb submit`
- An editor available on `PATH`

Configure the Exercism CLI separately:

```bash
exercism configure --token=<your-api-token>
```

## Main Flow

```bash
xrb new assembly-line
xrb test
xrb irb
xrb edit
xrb submit
```

## Commands

```bash
xrb new <exercise>       # download, save as current, and open the editor
xrb edit [exercise]      # open the editor for an exercise
xrb test [exercise]      # run the exercise test file with minitest/pride
xrb irb [exercise]       # open irb -r ./<solution>.rb --simple-prompt
xrb submit [exercise]    # submit the solution .rb file
xrb use <exercise>       # save a downloaded exercise as current
xrb current              # show the current exercise
xrb path [exercise]      # print the exercise path
xrb list                 # list downloaded exercises
xrb clear                # clear saved state
```

Exercise resolution priority:

1. Explicit slug, for example `xrb test assembly-line`
2. Current working directory when inside `XRB_ROOT`
3. Saved state from the previous `xrb new` or `xrb use`

`xrb test` expects a single `*_test.rb` file in the exercise directory and reports an ambiguity if more than one is present.

## Output And Color

`xrb` uses color automatically when stdout is a terminal. It stays plain when output is redirected, piped, or captured by tests.

Color controls:

```bash
XRB_COLOR=auto      # default
XRB_COLOR=always    # force ANSI color
XRB_COLOR=never     # disable ANSI color
NO_COLOR=1          # disable color in auto mode
CLICOLOR_FORCE=1    # force color in auto mode
```

`xrb path` intentionally prints only the resolved path so it can be used in scripts.

## State

The current exercise is stored as flat TOML:

```text
~/.local/state/exercism-rb/state.toml
```

Example:

```toml
track = "ruby"
exercise = "assembly-line"
path = "/home/hvpaiva/exercism/ruby/assembly-line"
updated_at = "2026-05-05T12:00:00Z"
```

## Configuration

```bash
XRB_ROOT=~/exercism/ruby      # exercise directory
XRB_TRACK=ruby                # Exercism track
XRB_EDITOR=nvim               # editor used by xrb new/edit
XRB_STATE=~/.local/state/exercism-rb/state.toml
XRB_COLOR=auto                # auto, always, or never
```

`xrb new` uses `exercism download`, which downloads into the workspace configured in the Exercism CLI. If you customize `XRB_ROOT`, configure the Exercism workspace so its track directory matches it, for example `exercism configure --workspace ~/exercism` for `XRB_ROOT=~/exercism/ruby`.

Editor commands are split with shell-like quoting, so this works:

```bash
XRB_EDITOR="code --wait" xrb edit
```

## Source Installer

RubyGems is the recommended installation path. The repository also keeps a source installer for users who want to install directly from `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/hvpaiva/exercism-rb/main/install.rb | ruby
```

The installer clones or updates the repository at `~/.local/share/exercism-rb` and creates this symlink:

```text
~/.local/bin/xrb -> ~/.local/share/exercism-rb/bin/xrb
```

It also installs the Exercism CLI into `~/.local/bin/exercism` when `exercism` is not already available.

To skip the Exercism CLI install:

```bash
curl -fsSL https://raw.githubusercontent.com/hvpaiva/exercism-rb/main/install.rb | ruby - --no-exercism
```

To force-install or update the Exercism CLI:

```bash
curl -fsSL https://raw.githubusercontent.com/hvpaiva/exercism-rb/main/install.rb | ruby - --with-exercism
```

If `~/.local/bin/xrb` is an existing symlink, the installer replaces the symlink without deleting the old target. If it is a real file or directory, the installer refuses to replace it unless you opt in:

```bash
curl -fsSL https://raw.githubusercontent.com/hvpaiva/exercism-rb/main/install.rb | XRB_INSTALL_OVERWRITE=1 ruby
```

## Development

Install development dependencies:

```bash
bundle install
```

Run the default test suite:

```bash
bundle exec rake
```

Run the full verification suite:

```bash
bundle exec rake ci
```

The CI task checks syntax, runs tests, runs tests with Ruby warnings enabled, smoke-tests the checkout executable, builds the gem, installs it into an isolated `GEM_HOME`, and smoke-tests the installed `xrb` executable.

Useful individual tasks:

```bash
bundle exec rake test
bundle exec rake syntax
bundle exec rake warnings
bundle exec rake smoke:bin
bundle exec rake smoke:gem
```

## Release

Publishing is automated through RubyGems Trusted Publishing and GitHub Actions. No long-lived `RUBYGEMS_AUTH_TOKEN` is required for the recommended release path.

Before the first release, configure a pending trusted publisher on RubyGems.org:

```text
Gem name: exercism-rb
GitHub repository: hvpaiva/exercism-rb
Workflow filename: release.yml
Environment: release
```

Release checklist:

1. Update `lib/exercism/rb/version.rb`
2. Update `CHANGELOG.md`
3. Run `bundle exec rake ci`
4. Commit the release changes
5. Create and push a tag that matches the version, for example `v0.1.0` for `VERSION = "0.1.0"`

The `Release` workflow runs only for `v*` tags. It verifies the project and publishes the gem through `rubygems/release-gem@v1`.

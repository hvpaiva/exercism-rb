# Contributing

Thanks for improving `exercism-rb`.

## Development Setup

```bash
bundle install
bundle exec rake
```

## Verification

Run the full local verification suite before opening a pull request:

```bash
bundle exec rake ci
```

The CI task checks syntax, runs the test suite, runs tests with Ruby warnings enabled, runs required quality checks, smoke-tests the checkout executable, builds the gem, installs it into an isolated `GEM_HOME`, and smoke-tests the installed `xrb` executable.

Useful focused checks:

```bash
bundle exec rake test
bundle exec rake syntax
bundle exec rake warnings
bundle exec rake style
bundle exec rake audit
bundle exec rake quality
bundle exec rake coverage
```

Optional maintenance reports:

```bash
bundle exec rake smells
bundle exec rake critic
```

Treat `standardrb` and `bundle-audit` as required checks. Treat coverage, Reek, and RubyCritic as maintenance advisors, not CI gates. RubyCritic writes its report to `tmp/rubycritic/`, which is ignored by Git.

## Pull Requests

- Keep changes small and focused.
- Add or update tests for behavior changes.
- Update `README.md` or `CHANGELOG.md` when user-facing behavior changes.
- Do not include secrets, Exercism tokens, or local machine paths in commits.

## Release Maintenance

Releases use GitHub Actions and RubyGems Trusted Publishing. No long-lived `RUBYGEMS_AUTH_TOKEN` is required for the recommended release path, and Trusted Publishing is already configured for this project.

Release checklist:

1. Update `lib/exercism/rb/version.rb`
2. Update `CHANGELOG.md`
3. Run `bundle exec rake ci`
4. Commit the release changes
5. Create and push a tag that matches the version, for example `vX.Y.Z` for `VERSION = "X.Y.Z"`
6. Confirm that the `Release` workflow published the gem to RubyGems

The `Release` workflow runs only for `v*` tags. It verifies the project and publishes the gem through `rubygems/release-gem@v1`.

Operational note: `rubygems/release-gem@v1` currently depends transitively on a RubyGems credential action that still declares a Node.js 20 runtime. Monitor upstream before the next release and update the workflow only when RubyGems publishes a clear replacement path.

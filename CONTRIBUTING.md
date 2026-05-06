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

The CI task checks syntax, runs the test suite, runs tests with Ruby warnings enabled, smoke-tests the checkout executable, builds the gem, installs it into an isolated `GEM_HOME`, and smoke-tests the installed `xrb` executable.

## Pull Requests

- Keep changes small and focused.
- Add or update tests for behavior changes.
- Update `README.md` or `CHANGELOG.md` when user-facing behavior changes.
- Do not include secrets, Exercism tokens, or local machine paths in commits.

# Cli-niuma-test

Niuma workflow integration/regression testbed repository.

## Provider Modes

Workflows support two provider modes via repository variable `NIUMA_TEST_PROVIDER_MODE`:

- `stub` (default): uses `.niuma/mock_provider.sh` for deterministic smoke testing.
- `codex`: uses real `codex` provider (`codex exec ...`).

If `NIUMA_TEST_PROVIDER_MODE=codex`, runner must have `codex` installed; otherwise workflow exits with clear error.

## Runner Selection

Workflows use repository variable `NIUMA_TEST_RUNNER` when provided, otherwise fallback to `ubuntu-latest`.

- For `stub` mode, default GitHub-hosted runner is enough.
- For `codex` mode, set `NIUMA_TEST_RUNNER` to your self-hosted runner label where `codex` is installed.

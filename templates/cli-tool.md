# CLAUDE.md - CLI Tool Project

<!-- Quick customize: Fill in the TODOs below, then delete this comment block -->
<!-- TODO: Set your CLI tool name (replace "mytool" throughout) -->
<!-- TODO: Set your language: Go (Cobra), Python (Click/Typer), or Rust (Clap) -->
<!-- TODO: Remove the language-specific sections that do not apply -->
<!-- TODO: Set your config file format (YAML, TOML, or JSON) -->
<!-- TODO: Set your distribution targets (Homebrew, RPM, DEB, PyPI, crates.io) -->
<!-- TODO: Update the project structure to match your subcommand layout -->

## Project Overview

This is a CLI tool project. It follows the Unix philosophy: do one thing well, compose with other tools, produce output that humans and machines can both consume.

Properties of a well-built CLI tool:

- **Predictable.** Same inputs produce same outputs. Users build scripts on top of it.
- **Discoverable.** Help text is thorough. Tab completion works. Misspelled commands get suggestions.
- **Quiet by default.** Only requested output goes to stdout. Diagnostics go to stderr.
- **Composable.** Supports `--output json` for piping to `jq`. Reads from stdin when `-` is a filename.
- **Forgiving.** Confirms destructive operations. Supports `--dry-run`.

### Design principles

1. Flags and arguments follow POSIX conventions. Long flags use `--kebab-case`.
2. Human output goes to stdout. Errors, progress, and diagnostics go to stderr.
3. Exit codes: 0 success, 1 general error, 2 usage error.
4. No interactive prompts when stdin is not a TTY. The tool works in CI without modification.
5. Config precedence: flags > environment variables > config file > defaults.

## Project Structure

<!-- TODO: Keep only the structure for your language -->

### Go (Cobra)

```
project-root/
  cmd/
    mytool/
      main.go              # Entrypoint: minimal, calls root command
    root.go                # Root command and persistent flags
    get.go                 # get subcommand
    create.go              # create subcommand
    delete.go              # delete subcommand
    completion.go          # Shell completion generation
  internal/
    config/                # Config file loading and validation
    output/                # Formatters: table, JSON, YAML
    client/                # API client (if API-backed)
    prompt/                # Interactive prompt helpers
  docs/man/                # Generated man pages
  completions/             # Generated shell completions
  go.mod
  goreleaser.yaml
  Makefile
```

### Python (Click or Typer)

```
project-root/
  src/
    mytool/
      __init__.py
      __main__.py          # python -m mytool entrypoint
      cli.py               # Root group and subcommand registration
      commands/
        get.py
        create.py
        delete.py
      config.py
      output.py
      client.py
  tests/
    test_cli.py
    conftest.py
  pyproject.toml
  Makefile
```

### Rust (Clap)

```
project-root/
  src/
    main.rs                # Entrypoint: parse args, dispatch
    cli.rs                 # Clap derive structs
    commands/
      mod.rs
      get.rs
      create.rs
      delete.rs
    config.rs
    output.rs
    error.rs
  tests/
    cli_tests.rs
  Cargo.toml
  Cargo.lock
  Makefile
```

### Layout rules

- Keep `main` minimal. Parse arguments and delegate. No business logic in the entrypoint.
- Group code by subcommand, not by architectural layer.
- Separate output formatting from business logic. Commands return data; formatters render it.

## Argument Parsing

### Go (Cobra)

```go
var rootCmd = &cobra.Command{
    Use:   "mytool",
    Short: "A tool that does useful things",
    SilenceUsage:  true,
    SilenceErrors: true,
}

func init() {
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file path")
    rootCmd.PersistentFlags().StringVarP(&outputFormat, "output", "o", "table", "output format (table, json, yaml)")
    rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
}

var getCmd = &cobra.Command{
    Use:     "get <resource-name>",
    Short:   "Get a resource by name",
    Aliases: []string{"show", "describe"},
    Args:    cobra.ExactArgs(1),
    RunE: func(cmd *cobra.Command, args []string) error {
        return runGet(cmd.Context(), args[0])
    },
}
```

### Python (Typer)

```python
app = typer.Typer(name="mytool", no_args_is_help=True,
                  context_settings={"help_option_names": ["-h", "--help"]})

@app.callback()
def main(ctx: typer.Context,
         config: str = typer.Option(None, "--config", "-c", help="Config file path."),
         output: str = typer.Option("table", "--output", "-o", help="Output format."),
         verbose: bool = typer.Option(False, "--verbose", "-v", help="Verbose output.")):
    ctx.ensure_object(dict)
    ctx.obj["output"] = output

@app.command()
def get(ctx: typer.Context,
        name: str = typer.Argument(help="Resource name.")):
    """Get a resource by name."""
```

### Rust (Clap derive)

```rust
#[derive(Parser)]
#[command(name = "mytool", version, propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    #[arg(long, global = true)]
    config: Option<PathBuf>,
    #[arg(long, short, global = true, default_value = "table")]
    output: OutputFormat,
    #[arg(long, short, global = true)]
    verbose: bool,
}

#[derive(Subcommand)]
enum Commands {
    /// Get a resource by name
    #[command(aliases = ["show", "describe"])]
    Get {
        name: String,
        #[arg(long, conflicts_with = "fields")]
        all: bool,
        #[arg(long = "field")]
        fields: Vec<String>,
    },
}
```

### Argument design rules

- Positional arguments for the primary target. Flags for everything else.
- Every flag gets a help string. No exceptions.
- Short flags (`-o`, `-v`, `-n`) only for frequently-typed flags.
- `--kebab-case` for multi-word flags. Not `--snake_case`.
- Boolean flags should be positive: `--no-color` not `--color=false`, `--dry-run` not `--no-execute`.
- Validate early. Exit code 2 for invalid input.
- Use `MarkFlagsMutuallyExclusive` (Cobra), `conflicts_with` (Clap), or manual validation (Click/Typer) for mutually exclusive flags.

## Subcommand Design

### Command hierarchy

Two levels max. Three levels means the tool is trying to do too much.

```
mytool get <resource>           # Good: verb-noun
mytool create <resource>
mytool config set <key> <value> # OK: two levels for config
mytool cluster node list        # Bad: three levels. Rethink.
```

### Naming conventions

- Verbs for actions: `get`, `create`, `delete`, `list`, `update`, `apply`.
- Nouns for management subgroups: `config`, `auth`, `plugin`.
- Be consistent. If one command uses `delete`, do not use `remove` elsewhere.
- Aliases for common alternatives: `get`/`show`, `delete`/`rm`, `list`/`ls`.

### Help text

- Short description: one line, under 60 characters, no period.
- Long description: what it does, when to use it, one example.
- Examples should be real commands with concrete values, not `<placeholders>`.
- Shared flags (`--output`, `--verbose`, `--config`) belong on the root command. Cobra: persistent flags. Clap: `global = true`. Click/Typer: group callback.

## Configuration

### Config file discovery

Follow XDG Base Directory Specification. Search in this order:

```
1. --config flag (explicit path)
2. $MYTOOL_CONFIG environment variable
3. ./mytool.yaml (project-local)
4. $XDG_CONFIG_HOME/mytool/config.yaml (~/.config/mytool/config.yaml)
5. $HOME/.mytool.yaml (legacy fallback)
```

### Config precedence (not negotiable)

```
Flags (highest)  >  Env vars ($MYTOOL_SERVER)  >  Config file  >  Defaults (lowest)
```

Document every config key and its corresponding flag and env var in one place.

### Config validation

Validate at load time. Fail fast with a clear message.

```
Error: invalid config at ~/.config/mytool/config.yaml
  server: must be a valid URL (got "not-a-url")
  auth.token_file: file not found at /home/user/.config/mytool/token
```

### First-run setup

Provide `mytool config init` or `mytool login`. Do not prompt interactively when config is missing. Print a message and exit with code 1.

```
Error: mytool is not configured. Run "mytool login" to set up authentication.
```

## Output Formatting

### Human-readable vs machine-readable

Default to table output. Support `--output json` and optionally `--output yaml`.

```bash
$ mytool list
NAME        STATUS    AGE
frontend    running   3d
backend     stopped   7d

$ mytool list -o json
[{"name": "frontend", "status": "running", "age": "3d"}]
```

### Table rules

- Fixed-width columns, not tabs. Headers in ALL CAPS (convention from `kubectl`, `docker`, `gh`).
- Truncate long values with `...`. Provide `--wide` for full output.
- Respect terminal width via `COLUMNS` or terminal query.

### Color handling

Disable color when any of these are true:

- `NO_COLOR` environment variable is set (https://no-color.org)
- `--no-color` flag is set
- stdout is not a TTY (output is piped)
- `TERM=dumb`

Go: `term.IsTerminal()`. Python: `sys.stdout.isatty()`. Rust: `atty::is(atty::Stream::Stdout)`.

### Progress output

Progress bars, spinners, and status messages go to stderr. This keeps stdout clean for piping.

### Verbosity levels

- (default): errors only, to stderr
- `--verbose` / `-v`: info-level (what the tool is doing)
- `--quiet` / `-q`: suppress non-error output
- `--debug`: full diagnostics (how the tool is doing it, request/response bodies)

## Shell Completion

Build completion generation into the tool. Do not maintain completion scripts by hand.

- **Cobra**: built-in `GenBashCompletionV2`, `GenZshCompletion`, `GenFishCompletion`
- **Click**: `_MYTOOL_COMPLETE=bash_source mytool`
- **Clap**: `clap_complete::generate()`

For dynamic completions (resource names from an API), use `RegisterFlagCompletionFunc` (Cobra), custom completers (Click), or `value_parser` (Clap).

Document installation in help text:
```
source <(mytool completion bash)                   # Current session
mytool completion bash > /etc/bash_completion.d/mytool  # Persistent
```

## Error Handling

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (runtime failure, API error) |
| 2 | Usage error (bad flag, missing argument) |
| 3 | Configuration error (missing/invalid config) |
| 130 | Interrupted (SIGINT / Ctrl+C) |

### Error message quality

Every error should answer: what happened, why, and what the user can do.

```
# Bad
Error: connection refused

# Good
Error: could not connect to https://api.example.com
  The server is not responding. Check the URL and server status.
  Config: ~/.config/mytool/config.yaml (server: https://api.example.com)
```

### Suggestions for typos

Cobra provides Levenshtein-based suggestions out of the box. Python: `difflib.get_close_matches`. Clap has built-in suggestion support.

```
$ mytool gte my-resource
Error: unknown command "gte". Did you mean "get"?
```

### Debug mode errors

With `--debug`, show the full error chain and request/response details. Redact auth headers.

## Interactive Mode

### TTY detection

Check `isatty(stdin)` before prompting. If not a TTY, fail with a message suggesting `--yes`.

Also check CI environment variables (`CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, `JENKINS_URL`). Disable all prompts and color in CI.

### Destructive operations

Always confirm before delete/destroy. Provide `--yes` / `-y` to skip in scripts.

```
$ mytool delete my-resource
Are you sure? Type the resource name to confirm: my-resource
Deleted "my-resource".

$ mytool delete my-resource --yes
Deleted "my-resource".
```

### Secret input

Use secure, non-echoing input. Go: `term.ReadPassword()`. Python: `getpass.getpass()`. Rust: `rpassword::read_password()`.

## Man Page Generation

Generate man pages from code. Do not write them by hand.

- **Cobra**: `cobra/doc.GenManTree()`
- **Clap**: `clap_mangen::Man` in build.rs

Include sections: NAME, SYNOPSIS, DESCRIPTION, OPTIONS, ENVIRONMENT, FILES, EXIT STATUS, EXAMPLES, SEE ALSO.

```makefile
install-man:
	install -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 docs/man/man1/*.1 $(DESTDIR)$(PREFIX)/share/man/man1/
```

## Testing

### End-to-end CLI tests

Test as a user would. Capture stdout, stderr, exit codes.

**Go**: Use `cmd.SetOut()`, `cmd.SetArgs()`, `cmd.Execute()` with `httptest.NewServer` for API mocks.
**Python**: Use `click.testing.CliRunner` with `runner.invoke(cli, ["get", "name"])`.
**Rust**: Use `assert_cmd::Command::cargo_bin("mytool")` with `.assert().success().stdout(contains("..."))`.

### Golden file / snapshot testing

For complex output, compare against saved expected output. Go: `testdata/*.golden` files. Rust: `insta::assert_snapshot!`. Python: write your own or use `syrupy`.

### What to test

- Every subcommand with valid input: expected output and exit code 0.
- Invalid arguments: exit code 2, clear error.
- Missing config: exit code 3, actionable message.
- `--output json` produces valid JSON on every command.
- `--help` works on every subcommand.
- Interactive prompts can be skipped with `--yes`.
- Shell completions generate without errors.

## Release Automation

### Go (GoReleaser)

```yaml
# goreleaser.yaml
builds:
  - env: [CGO_ENABLED=0]
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    ldflags:
      - -s -w -X main.version={{.Version}} -X main.commit={{.Commit}}
brews:
  - repository: { owner: your-org, name: homebrew-tap }
nfpms:
  - formats: [rpm, deb]
    contents:
      - { src: completions/mytool.bash, dst: /etc/bash_completion.d/mytool }
      - { src: man/mytool.1, dst: /usr/share/man/man1/mytool.1 }
```

### Python (PyPI)

```toml
[project]
name = "mytool"
requires-python = ">=3.11"
dependencies = ["click>=8.1", "rich>=13.0"]
[project.scripts]
mytool = "mytool.cli:cli"
```

### Rust

`cargo release patch` (or minor, major). Cross-compile with `cross` or GitHub Actions matrix.

### Container images

Use multi-stage builds. Final image should be distroless or scratch.

```dockerfile
FROM golang:1.22-bookworm AS builder
WORKDIR /build
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /mytool ./cmd/mytool

FROM gcr.io/distroless/static-debian12
COPY --from=builder /mytool /usr/local/bin/mytool
ENTRYPOINT ["mytool"]
```

## Logging and Debugging

All log messages go to stderr. Never mix logs into stdout.

- **Go**: `slog` with `slog.NewTextHandler(os.Stderr, ...)`
- **Python**: `logging.basicConfig(stream=sys.stderr, ...)`
- **Rust**: `tracing_subscriber::fmt().with_writer(std::io::stderr)`

For API-backed CLIs, log request method, URL, status, and latency in debug mode. Redact `Authorization` headers.

## Security

### Credentials

- Never store credentials in world-readable files. Set 0600 permissions on config files containing tokens.
- Read tokens from files or env vars, not from CLI flags (flags are visible in `ps` and shell history).
- Support `$MYTOOL_TOKEN` for CI. Warn if tokens are passed as flags.

### TLS and proxy

- Use system CA certs by default. Support `--ca-cert` for custom CAs.
- Respect `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY`.
- Support `--insecure` with a printed warning.

## UX Best Practices

### Consistent flag naming

Same flags across all subcommands. Common conventions:

| Flag | Short | Purpose |
|------|-------|---------|
| `--output` | `-o` | Output format |
| `--verbose` | `-v` | Verbose output |
| `--quiet` | `-q` | Quiet mode |
| `--namespace` | `-n` | Scope |
| `--yes` | `-y` | Skip confirmation |
| `--dry-run` | | Show what would happen |
| `--no-color` | | Disable color |

### Dry-run

Show what would happen without doing it:

```
$ mytool delete --all --dry-run
Would delete: frontend, backend, worker (3 resources)
Run without --dry-run to execute.
```

### Idempotent operations

Creating something that exists should succeed or warn, not fail. This makes scripts reliable.

### Destructive safeguards

1. Require confirmation (or `--yes`). 2. Show what will be affected. 3. Support `--dry-run`. 4. Require `--all` for bulk operations.

## Performance

### Startup time

Target under 100ms. Go and Rust are fast by default. Python: use lazy imports for heavy modules.

```python
@app.command()
def deploy(ctx: typer.Context):
    import boto3  # Only imported when "deploy" runs, not on --help
```

For many subcommands in Python, use lazy group loading to avoid importing all command modules at startup.

### Caching

Cache API responses in `$XDG_CACHE_HOME/mytool/`. Set TTLs. Provide `--no-cache` and `mytool cache clear`.

### Connection reuse

Create one HTTP client, pass it to all commands. Do not create a new connection per request.

## Common Pitfalls

### Signal handling

Handle SIGINT and SIGTERM gracefully. Clean up temp files, close connections, exit 130 for SIGINT.

- Go: `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)`
- Python: `signal.signal(signal.SIGINT, handler)` that calls `sys.exit(130)`
- Rust: `tokio::signal::ctrl_c()` or `ctrlc` crate

### Broken pipe

When piped to `head`, the reader closes early and sends SIGPIPE. Python: set `signal.signal(signal.SIGPIPE, signal.SIG_DFL)`. Go handles this by default.

### Non-TTY output

When stdout is not a TTY, disable color, progress bars, spinners, and interactive prompts. Fall back to 80-column width or unlimited.

### Windows compatibility

- Use platform-aware path APIs, not hardcoded `/`.
- Config on Windows: `%APPDATA%\mytool\`, not `~/.config/`.
- Go: `os.UserHomeDir()`. Python: `Path.home()`. Rust: `dirs::home_dir()`.

## Version Information

Every CLI needs `--version` or `mytool version`. Include version, commit, build date, and compiler version.

```
$ mytool version
mytool v1.2.3 (commit abc1234, built 2024-11-15, go1.22.1, linux/amd64)
```

Inject at build time. Go: `-ldflags -X main.version=...`. Rust: `env!("CARGO_PKG_VERSION")`. Python: `importlib.metadata.version()`.

## Common Commands and Review Checklist

### Development commands

```bash
# TODO: Update these to match your project

# Build
make build

# Test
make test                       # All tests
go test ./... | cargo test | pytest

# Lint and format
make lint
make fmt

# Generate completions and man pages
make completions
make man

# Release (local test)
goreleaser release --snapshot   # Go
cargo release --dry-run patch   # Rust
python -m build                 # Python
```

## Common Mistakes Claude Makes

**Mixing stdout and stderr.** Claude prints error messages, progress updates, and diagnostic output to stdout. Only requested output goes to stdout. Errors, progress, and diagnostics go to stderr. This is essential for pipe compatibility.

**Adding interactive prompts without TTY detection.** Claude adds confirmation prompts that break when the tool is used in scripts or CI pipelines. Check `isatty(stdin)` before prompting. Provide `--yes` to skip prompts.

**Using `os.Exit()` or `sys.exit()` deep in library code.** Claude calls exit functions from within business logic. Only the `main` function should exit. Return errors and let `main` decide the exit code.

**Ignoring the `NO_COLOR` environment variable.** Claude adds colored output without checking for `NO_COLOR`, `--no-color`, or non-TTY stdout. Always disable color when `NO_COLOR` is set, `--no-color` is passed, or stdout is not a terminal.

**Hardcoding config file paths.** Claude reads configuration from `~/.config/mytool/config.yaml` without supporting `--config`, `$MYTOOL_CONFIG`, or XDG Base Directory discovery. Follow the config precedence chain: flags > env vars > config file > defaults.

**Producing invalid JSON with `--output json`.** Claude generates JSON output that includes log messages, progress indicators, or trailing commas. JSON output mode must produce valid, parseable JSON with no extra text.

**Missing help text on flags.** Claude adds flags without description strings. Every flag needs a help string. No exceptions.

**Not handling SIGINT gracefully.** Claude lets the tool crash with a stack trace on Ctrl+C. Handle SIGINT to clean up temporary files, close connections, and exit with code 130.

### Code review checklist

Before merging any CLI change:

- [ ] Every new flag has a help string
- [ ] Every new subcommand has Short, Long, and Example text
- [ ] `--output json` produces valid JSON
- [ ] Errors answer: what, why, what to do
- [ ] Exit codes are correct (0/1/2)
- [ ] Destructive commands require confirmation or `--yes`
- [ ] No secrets logged or printed, even with `--debug`
- [ ] Color disabled when `NO_COLOR` set or stdout is not a TTY
- [ ] Commands work in non-interactive (piped) mode
- [ ] Shell completions and man pages generate without errors
- [ ] `--help` output is accurate
- [ ] Breaking changes to flags or output are documented
- [ ] Tests cover valid input, invalid input, and edge cases
- [ ] `--dry-run` supported for state-modifying commands

### References

- CLI Guidelines: https://clig.dev/
- POSIX Utility Conventions: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html
- NO_COLOR: https://no-color.org/
- XDG Base Directory Spec: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
- 12 Factor CLI Apps: https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46

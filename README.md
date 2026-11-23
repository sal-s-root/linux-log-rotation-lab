# Linux log rotation lab

Rotate a live log writer using rename, create, SIGHUP, and delayed compression.
The drill verifies that every numbered record appears exactly once across the
active log and the two retained archives.

## Run

Requirements: Linux, Bash, Make, logrotate, gzip, and ShellCheck.
On Debian/Ubuntu the additional packages are `logrotate shellcheck`;
on Alpine they are `bash make logrotate shellcheck`.

```sh
make test
```

The drill creates a private temporary directory and a sequential log writer, forces
two rotations using a private state file, then stops the writer and checks the
combined sequence. All generated files are removed when the drill exits.

## What to inspect

`logger.sh` holds an open file descriptor and reopens it on SIGHUP. `drill.sh`
builds a local configuration with `create`, `postrotate`, `compress`, and
`delaycompress`. The first archive remains plain text for one cycle; after the
second rotation it is compressed. The writer follows the newly created active file.

This experiment uses rename and reopen rather than `copytruncate`. Its acceptance
check is sequence continuity under this controlled workload. Keep the private state
file separate from the machine-wide logrotate state.

[Validation](VALIDATION.md) · [logrotate manual](https://man7.org/linux/man-pages/man8/logrotate.8.html)

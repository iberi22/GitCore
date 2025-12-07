# Workflow Orchestrator

High-performance parallel workflow orchestrator for Git-Core Protocol, written in Rust.

## 🚀 Overview

The Workflow Orchestrator is a Rust-based CLI tool designed to execute critical Git-Core Protocol workflows with maximum performance and reliability. It replaces slow PowerShell scripts with blazing-fast native binaries.

## 📦 Components

### Guardian Agent

Auto-merge decision engine that evaluates Pull Requests and determines if they're safe to merge automatically.

**Performance:**
- **Rust:** <200ns per PR evaluation (~10M ops/sec)
- **PowerShell baseline:** 2-3 seconds
- **Speedup:** ~15,000,000x

**Confidence Scoring:**
```
Base Score:
- CI passes: +40
- Approved reviews: +40

Bonuses:
- Has tests: +10
- Single scope/module: +10

Penalties:
- 100-300 lines: -5
- 300-500 lines: -10
- 500+ lines: -20

Blockers (Immediate rejection):
- high-stakes label
- needs-human label
- CI failure
```

**Usage:**
```bash
# Evaluate a PR
workflow-orchestrator guardian --pr-number 123

# Set custom threshold (default: 70)
workflow-orchestrator guardian --pr-number 123 --threshold 80

# Dry run (no execution)
workflow-orchestrator guardian --pr-number 123 --dry-run

# CI mode (outputs JSON for GitHub Actions)
workflow-orchestrator guardian --pr-number 123 --ci-mode
```

**GitHub Actions Integration:**
```yaml
- name: 🛡️ Run Guardian Agent
  run: |
    if command -v workflow-orchestrator &> /dev/null; then
      workflow-orchestrator guardian \
        --pr-number ${{ github.event.pull_request.number }} \
        --ci-mode
    else
      # Fallback to PowerShell
      pwsh ./scripts/guardian-core.ps1 -PrNumber ${{ github.event.pull_request.number }}
    fi
```

## 🏗️ Architecture

```
workflow-orchestrator/
├── src/
│   ├── main.rs              # CLI entry point
│   ├── lib.rs               # Public API
│   ├── guardian_core.rs     # Guardian Agent logic ⭐
│   ├── github.rs            # GitHub API client
│   ├── analyzer.rs          # Workflow analysis
│   ├── validator.rs         # Workflow validation
│   ├── reporter.rs          # Report generation
│   └── parallel.rs          # Parallel execution utilities
├── tests/
│   └── integration_guardian.rs  # Integration tests (8 tests)
├── benches/
│   └── guardian_benchmarks.rs   # Performance benchmarks
└── Cargo.toml
```

## 🧪 Testing

**Unit Tests:**
```bash
cargo test --lib
```

**Integration Tests:**
```bash
cargo test --test integration_guardian
```

**All Tests:**
```bash
cargo test
# Expected: 14 tests passing
```

**Benchmarks:**
```bash
cargo bench --bench guardian_benchmarks
```

## 📊 Benchmarks

Latest results on `cargo bench`:

| Operation | Time | Ops/sec |
|-----------|------|---------|
| Size penalty calculation | ~1-2 ns | 500M-1B |
| Test detection | ~23-52 ns | 20M-40M |
| Scope detection | ~48-49 ns | 20M |
| Decision making | ~7-77 ns | 13M-140M |
| **Full confidence calc** | **~177 ns** | **~5.6M** |

## 🔧 Development

**Build:**
```bash
cargo build --release
```

**Run locally:**
```bash
cargo run -- guardian --pr-number 123
```

**Add new subcommand:**
1. Create module in `src/` (e.g., `dispatcher_core.rs`)
2. Add to `Commands` enum in `main.rs`
3. Implement handler in `main()`
4. Add tests in `tests/`
5. Add benchmarks in `benches/`

## 📝 Dependencies

| Dependency | Purpose |
|------------|---------|
| `octocrab` | GitHub API client |
| `tokio` | Async runtime |
| `clap` | CLI argument parsing |
| `serde` | Serialization |
| `anyhow` | Error handling |
| `tracing` | Logging |
| `criterion` | Benchmarking (dev) |

## 🚦 CI/CD

The workflow orchestrator is built and deployed via GitHub Actions:

1. **Build:** Compiled for Linux, macOS, Windows
2. **Test:** All tests must pass
3. **Benchmark:** Performance regression checks
4. **Release:** Binaries published as artifacts

**Fallback Strategy:**

If the Rust binary is not available, workflows automatically fall back to PowerShell scripts in `scripts/`. This ensures zero downtime during rollouts.

## 🎯 Roadmap

- [x] Guardian Agent (auto-merge decision)
- [ ] Dispatcher Agent (agent load balancing)
- [ ] Issue Syncer (GitHub ↔ local file sync)
- [ ] Planner Agent (autonomous issue generation)

## 📚 Related Documentation

- [Git-Core Protocol](../../AGENTS.md)
- [Guardian Agent Issue](../../.github/issues/FEAT_rust-guardian-agent.md)
- [Architecture Decisions](../../.✨/ARCHITECTURE.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feat/my-feature`
3. Write tests: `cargo test`
4. Benchmark: `cargo bench`
5. Commit: `git commit -m "feat(guardian): add X"`
6. Push: `git push origin feat/my-feature`
7. Create PR

## 📄 License

MIT License - see [LICENSE](../../LICENSE)

---

**Built with ⚡ Rust for maximum performance**

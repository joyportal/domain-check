# AGENTS.md - Domain Check Repository Guidelines

## Build, Test & Lint Commands

### Building
```bash
# Build entire workspace
cargo build --workspace

# Build release binary
cargo build --release -p domain-check
```

### Testing
```bash
# Run all tests
cargo test --workspace

# Run tests for specific crate
cargo test -p domain-check-lib
cargo test -p domain-check

# Run single test by name
cargo test --workspace test_name_here

# Run tests with all features enabled
cargo test -p domain-check-lib --all-features

# Run documentation tests
cargo test --doc --workspace
```

### Linting & Formatting
```bash
# Format code
cargo fmt --all

# Check formatting (CI)
cargo fmt --all --check

# Run Clippy with workspace settings
cargo clippy --workspace --all-targets --all-features -- -D warnings -A clippy::uninlined_format_args

# Security audit
cargo audit
```

### Documentation
```bash
# Build docs
cargo doc --workspace --no-deps
cargo doc -p domain-check-lib --document-private-items
```

## Project Structure

This is a Rust workspace with two crates:
- `domain-check-lib/` - Core library for domain checking
  - `src/lib.rs` - Public API exports
  - `src/checker.rs` - Main DomainChecker implementation
  - `src/error.rs` - DomainCheckError enum
  - `src/types.rs` - DomainResult, CheckConfig, etc.
  - `src/protocols/` - RDAP, WHOIS, registry modules
  - `src/utils.rs` - Domain validation and expansion
- `domain-check/` - CLI application
  - `src/main.rs` - CLI entry point with clap
  - `tests/cli_integration.rs` - CLI integration tests

## Code Style Guidelines

### Imports
- Order: `std`, external crates, internal modules (`crate::`)
- Group related imports together
- Use `use crate::error::DomainCheckError;` for internal modules

```rust
// Standard library
use std::collections::HashMap;
use std::time::Duration;

// External crates
use serde::{Deserialize, Serialize};
use tokio::sync::Semaphore;

// Internal modules
use crate::error::DomainCheckError;
use crate::types::{CheckConfig, DomainResult};
```

### Formatting
- Use `cargo fmt` with default settings
- Max line length: Follow rustfmt defaults
- Indent with 4 spaces

### Types & Naming
- **Structs/Enums**: `PascalCase` (e.g., `DomainResult`, `CheckMethod`)
- **Functions/Variables**: `snake_case` (e.g., `check_domain`, `domain_name`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g., `VERSION`, `AUTHOR`)
- **Modules**: `snake_case` (e.g., `protocols`, `domain_check_lib`)
- **Type aliases**: Use `Result<T> = std::result::Result<T, DomainCheckError>;`

### Error Handling
- Use custom `DomainCheckError` enum for library errors
- Implement `From` conversions for external error types (reqwest, serde, io)
- Use `?` operator for error propagation
- Provide user-friendly error messages with `Display` impl including emojis

```rust
impl From<reqwest::Error> for DomainCheckError {
    fn from(err: reqwest::Error) -> Self {
        if err.is_timeout() {
            Self::timeout("HTTP request", Duration::from_secs(30))
        } else {
            Self::network_with_source("Connection failed", err.to_string())
        }
    }
}
```

### Documentation
- Module docs: `//!` at top of file
- Item docs: `///` before public items
- Include code examples in doc comments with ```rust,no_run

```rust
//! # Domain Check Library
//!
//! A fast, robust library for checking domain availability.
//!
//! ## Quick Start
//!
//! ```rust,no_run
//! use domain_check_lib::DomainChecker;
//!
//! #[tokio::main]
//! async fn main() -> Result<(), Box<dyn std::error::Error>> {
//!     let checker = DomainChecker::new();
//!     let result = checker.check_domain("example.com").await?;
//!     Ok(())
//! }
//! ```
```

### Async Code
- Use `tokio` runtime with `#[tokio::main]`
- Functions return `Result<T, DomainCheckError>`
- Clone clients for concurrent execution
- Use `futures::stream` for concurrent processing with backpressure

### Testing
- Unit tests in `#[cfg(test)]` modules at end of files
- Integration tests in `tests/` directories
- Use `assert_cmd` and `predicates` for CLI tests
- Tests should be deterministic (avoid real network calls)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_should_enable_bootstrap_large_tld_set() {
        let args = create_test_args();
        let large_tld_set = Some((0..25).map(|i| format!("tld{}", i)).collect());
        assert!(should_enable_bootstrap(&args, &large_tld_set));
    }
}
```

### Features
- Library features: `rdap`, `whois`, `bootstrap`, `debug`
- Default features: `rdap`, `whois`, `bootstrap`
- Use `#[cfg(feature = "rdap")]` for conditional compilation

## CI Requirements
- All code must pass `cargo fmt --all --check`
- All code must pass `cargo clippy` with `-D warnings`
- Tests must pass on stable, beta, and MSRV (1.70.0)
- Security audit must pass

## Version Management
- Workspace version in root `Cargo.toml`
- MSRV: 1.70.0
- Edition: 2021

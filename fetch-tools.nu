#!/usr/bin/env nu

# Install Rust
if (is-rust-installed?) {
    log "Rust is already installed"
} else {
    log "Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

# The idea behind these tools is to provide a contemporary
# UX while also improving on functionality.
# To that end, the sandwhich to be made is:
# - nushell on top
# - zellij in the middle
# - alacritty at the bottom
# - zoxide for superior path navigation
cargo-install alacritty         # fast H/W accelerated terminal
cargo-install nu --all-features # a modern, FP-style shell
cargo-install zellij            # tab/pane support
cargo-install zoxide --locked   # CLI navigation on steroids

# Install more general tools
cargo-install bat # modern update to `cat`
cargo-install bottom --locked # modern update to `top` and `htop`
cargo-install cargo-audit # vuln auditing tool
cargo-install cargo-cache # manage Rust crate cache
cargo-install cargo-make # build tool for complex projects
cargo-install cargo-outdated # scans a project for outdated deps
cargo-install diesel_cli --locked # Diesel CLI util
cargo-install du-dust # summarize dir disk space usage
cargo-install dua # alternative for du-dust
cargo-install exa # modern update to `ls`
# cargo-install eva  # calculator REPL
cargo-install fd-find --locked # modern update to `find`
cargo-install grex --locked # Generate regexes from samples
cargo-install hyperfine # CLI benchmarking tool
cargo-install ripgrep # modern update to `grep`
cargo-install rusty-man # CLI viewer for rustdoc docs
cargo-install tokei # SLOC stats
cargo-install wasm-bindgen-cli # essential Rust WASM tooling
cargo-install wasm-pack # essential Rust WASM tooling

# Nushell plugins
cargo-install nu_plugin_gstat # git stat plugin for nushell
register -e json ~/.cargo/bin/nu_plugin_gstat

# Check that the Rust toolchain is installed
def is-rust-installed? [] {
    let rustc-path = (whereis rustc | parse "rustc: {path}")
    if ($rustc-path | empty?) {
        false
    } else {
        $rustc-path
        | get path
        | str trim
        | str collect
        | path exists
    }
}

# Install a Rust binary distributed via https://crates.io
def cargo-install [
    cmd: string,
    --locked: bool,
    --force: bool,
    --all-features: bool,
] {
    let flags = [
        {value: $locked,       repr: "--locked"}
        {value: $force,        repr: "--force"}
        {value: $all-features, repr: "--all-features"}
    ]
    let args = (stringify-flags $flags | where not ($it | empty?))
    let entry = ($cmd | append $args | str collect ' ' | str trim)
    log $"Installing ($entry)"
    cargo install $cmd $args
}

def stringify-flags [flags] {
    $flags | each {|f| if ($f.value) { $f.repr } else { "" }}
}

def log [...msgs: string] {
    $msgs | insert 0 "[fetch-tools]" | str collect ' '
}

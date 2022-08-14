#!/usr/bin/env nu

# Install Rust if not present
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


# Install some portable tools:
cargo-install bat # modern update to `cat`
cargo-install bottom --locked # modern update to `top` and `htop`
cargo-install bacon --locked # A background Rust code checker
cargo-install cargo-asm --locked # Displays the ASM/llvm-ir for Rust src.
cargo-install cargo-audit # vuln auditing tool
cargo-install cargo-cache # manage Rust crate cache
cargo-install cargo-make # build tool for complex projects
cargo-install cargo-outdated # scans a project for outdated deps
cargo-install diesel_cli --locked # Diesel CLI util
cargo-install du-dust # summarize dir disk space usage
cargo-install dua # alternative for du-dust
cargo-install exa # modern update to `ls`
# cargo-install eva  # calculator REPL
cargo-install evcxr_repl --locked # A Rust REPL
cargo-install fd-find --locked # modern update to `find`
cargo-install grex --locked # Generate regexes from samples
cargo-install hyperfine # CLI benchmarking tool
cargo-install irust --locked # A Rust REPL
cargo-install ripgrep # modern update to `grep`
cargo-install rusty-man # CLI viewer for rustdoc docs
cargo-install tokei # SLOC stats
cargo-install wasm-bindgen-cli # essential Rust WASM tooling
cargo-install wasm-pack # essential Rust WASM tooling
install-lazygit # TUI for git

# Configure stack components
log "Configuring the ZO.N.Z.A. stack..."
add-env-entry "let-env PATH = ($env.PATH | uniq)"

configure-zoxide
configure-fzf
configure-zellij
configure-alacritty
configure-nushell


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

def install-lazygit [] {
    let lazygit-version = "0.35"
    let lazygit-file = $"lazygit_($lazygit-version)_Linux_x86_64.tar.gz"
    let lazygit-base-url = (
        "https://github.com/jesseduffield/lazygit/releases/download"
    )
    let tmp-lazygit-dir = "/tmp/lazygit"
    let bin-dir = "~/bin"

    log "Installing lazygit"
    fetch --raw $"($lazygit-base-url)/v($lazygit-version)/($lazygit-file)"
    | save --raw $"/tmp/($lazygit-file)"
    mkdir $tmp-lazygit-dir
    tar -xf $"/tmp/($lazygit-file)" -C $tmp-lazygit-dir
    mkdir $bin-dir
    cp /tmp/lazygit/lazygit $bin-dir
}

def configure-zellij [] {
    log "Configuring Zellij"
    cp ./defaults/zellij/config.yaml ~/.config/zellij/config.yaml
    cp ./defaults/zellij/layout.yaml ~/.config/zellij/layout.yaml
}

def configure-alacritty [] {
    log "Configuring Alacritty"
    # TODO
}

def configure-nushell [] {
    log "Configuring Nushell"

    # Configure Nushell plugins
    cargo-install nu_plugin_gstat # git stat plugin for nushell
    register -e json ~/.cargo/bin/nu_plugin_gstat

    add-config-entry ("
def cargo-clean-dev-projects [] {
    fd --type f Cargo.toml ~/dev
    | split row \"\n\"
    | path dirname
    | par-each {|dir| echo $\"Cleaning ($dir)\"; cd $dir; cargo clean}
}" | str trim)


    # TODO
}

def configure-zoxide [] {
    add-env-entry (
        "zoxide init nushell --hook prompt | save ~/.zoxide.nu"
    )
    add-config-entry "source ~/.zoxide.nu"
}

def configure-fzf [] {
    # TODO: ask user where FZF is installed
    let fzf-path = "~/dev/fzf/bin"
    add-config-entry ($"let-env PATH = \(prepend-to-path ($fzf-path))")
    add-config-entry ("
def prepend-to-path [p: path] {
    if (p in env.PATH) {
        env.PATH | uniq
    } else {
        env.PATH | prepend p | uniq
    }
}" | str trim)
}

def add-env-entry [...msg: string] {
    $msg | prepend '' | save --append ($nu.env-path)
}

def add-config-entry [...msg: string] {
    $msg | prepend '' | save --append ($nu.config-path)
}

def stringify-flags [flags] {
    $flags | each {|f| if ($f.value) { $f.repr } else { "" }}
}

def log [...msgs: string] {
    $msgs | insert 0 "[fetch-tools]" | str collect ' '
}

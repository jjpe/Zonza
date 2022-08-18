#!/usr/bin/env nu

def main [] {
    install_os_libraries
    install_powerline_fonts

    # Install Rust if not present
    if (is_rust_installed?) {
        log "Rust is already installed"
    } else {
        log "Installing Rust"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    }

    install_bins

    let marker_path = $"($nu.home-path)/.zonza"
    if ($marker_path | path exists) {
        log "Updated the ZO.N.Z.A. stack"
    } else {
        log "Configuring the ZO.N.Z.A. stack components..."

        configure_nushell
        configure_alacritty
        configure_zellij
        configure_starship
        configure_zoxide
        configure_fzf

        add_env_entry "let-env PATH = ($env.PATH | uniq)"
    }

    touch $marker_path
}

def install_os_libraries [] {
    if (uname -a | str contains "Ubuntu") {
        log "Installing prerequisite Ubuntu-hosted libraries"
        sudo apt install [
            libsqlite3-dev              # for diesel_cli
            libpq-dev                   # for diesel_cli
            default-libmysqlclient-dev  # for diesel_cli
            gcc gcc-doc g++             # GCC tools
            cmake                       # build tool for C/C++
            libfontconfig-dev           # for alacritty
            libx11-xcb-dev              # for alacritty
            libxcb-render0-dev          # for alacritty
            libxcb-shape0-dev           # for alacritty
            libxcb-xfixes0-dev          # for alacritty
        ]
    } else {
        log "Unsupported OS"
        exit 1;
    }
}

def install_powerline_fonts [] {
    log "Installing powerline fonts"
    let tmp_dir = "/tmp/powerline-fonts"
    if ($"($tmp_dir)/.git" | path exists) {
        log "powerline git repo found"
    } else {
        git clone https://github.com/powerline/fonts.git --depth=1 $tmp_dir
    }
    bash -c $"($tmp_dir)/install.sh"
}

def install_bins [] {
    # The idea behind these tools is to provide a contemporary
    # UX while also improving on functionality.
    # To that end, the sandwhich to be made is:
    # - nushell on top
    # - zellij in the middle
    # - alacritty at the bottom
    # - zoxide for superior path navigation
    cargo_install alacritty         # fast H/W accelerated terminal
    cargo_install zoxide --locked   # CLI navigation on steroids
    cargo_install nu --all_features --git https://github.com/nushell/nushell.git  # a modern, FP-style shell
    # cargo_install nu_plugin_gstat --git https://github.com/nushell/nushell.git   # git stat plugin for nushell
    # nu -c "register -e json ~/.cargo/bin/nu_plugin_gstat"
    cargo_install zellij            # tab/pane support
    cargo_install starship --locked # Useful prompt info

    # Install some portable tools:
    cargo_install bat # modern update to `cat`
    cargo_install bottom --locked # modern update to `top` and `htop`
    cargo_install bacon --locked # A background Rust code checker
    cargo_install cargo-asm --locked # Displays the ASM/llvm-ir for Rust src.
    cargo_install cargo-audit # vuln auditing tool
    cargo_install cargo-cache # manage Rust crate cache
    cargo_install cargo-make # build tool for complex projects
    cargo_install cargo-outdated # scans a project for outdated deps
    cargo_install diesel_cli --locked # Diesel CLI util
    cargo_install du-dust # summarize dir disk space usage
    cargo_install dua # alternative for du-dust
    cargo_install exa # modern update to `ls`
    # cargo_install eva  # calculator REPL
    cargo_install evcxr_repl --locked # A Rust REPL
    cargo_install fd-find --locked # modern update to `find`
    cargo_install grex --locked # Generate regexes from samples
    cargo_install hyperfine # CLI benchmarking tool
    cargo_install irust --locked # A Rust REPL
    cargo_install ripgrep # modern update to `grep`
    cargo_install rusty-man # CLI viewer for rustdoc docs
    cargo_install tokei # SLOC stats
    cargo_install wasm-bindgen-cli # essential Rust WASM tooling
    cargo_install wasm-pack # essential Rust WASM tooling
    install_lazygit # TUI for git
    install_nvm # Manage multiple NodeJS installs
}

# Check that the Rust toolchain is installed
def is_rust_installed? [] {
    let rustc_path = (whereis rustc | parse "rustc: {path}")
    if ($rustc_path | empty?) {
        false
    } else {
        $rustc_path
        | get path
        | str trim
        | str collect
        | path exists
    }
}

# Install a Rust binary distributed via https://crates.io
def cargo_install [
    cmd: string,
    --locked: bool,
    --force: bool,
    --all_features: bool,
    --version: string,
    --git: string,
] {
    let options = ([
        (if ($locked) { "--locked" } else { "" })
        (if ($force) { "--force" } else { "" })
        (if ($all_features) { "--all-features" } else { "" })
        (if ($version != $nothing) { $"--version=($version)" } else { "" })
        (if ($git != $nothing) { $"--git=($git)" } else { "" })
    ] | each {|opt| $opt | where $opt != "" } | flatten)
    log $"Installing ($cmd) ($options)"
    cargo install $cmd $options
}

def install_lazygit [] {
    let version = "0.35"
    let filename = $"lazygit_($version)_Linux_x86_64.tar.gz"
    let base_url = "https://github.com/jesseduffield/lazygit/releases/download"
    let bin_dir = $"($nu.home-path)/bin"
    mkdir $bin_dir
    let tmp_dir = "/tmp/lazygit"
    mkdir $tmp_dir

    log "Installing lazygit"
    fetch --raw $"($base_url)/v($version)/($filename)"
    | save --raw $"($tmp_dir)/($filename)"
    tar -xf $"($tmp_dir)/($filename)" -C $tmp_dir
    cp /tmp/lazygit/lazygit $bin_dir
}

def install_nvm [] {
    let version = "0.39.1"
    let url = $"https://github.com/nvm-sh/nvm/raw/v($version)/install.sh"
    let tmp_dir = "/tmp/nvm"
    mkdir $tmp_dir
    let filepath = $"($tmp_dir)/install_nvm.sh";

    log "Installing NVM"
    fetch $url | save --raw $filepath
    chmod +x $filepath
    $filepath
}

def configure_zellij [] {
    log "Configuring zellij"
    cp -r ./defaults/zellij ~/.config/zellij
    # cp ./defaults/zellij/config.yaml ~/.config/zellij/config.yaml
    # cp ./defaults/zellij/layout.yaml ~/.config/zellij/layout.yaml
}

def configure_alacritty [] {
    log "Configuring alacritty"
    cp -r ./defaults/alacritty ~/.config/alacritty
}

def configure_nushell [] {
    log "Configuring nushell"

    cp -r ./defaults/nushell ~/.config/nushell
    # cp ./defaults/nushell/config.nu ~/.config/nushell/config.nu
    # cp ./defaults/nushell/env.nu    ~/.config/nushell/env.nu

    # Custom commands:
    add_config_entry ("
def cargo_clean_dev_projects [] {
    fd --type f Cargo.toml ~/dev
    | split row \"\\n\"
    | path dirname
    | par-each {|dir| echo $\"Cleaning ($dir)\"; cd $dir; cargo clean}
}" | str trim)

}

def configure_starship [] {
    add_env_entry ("mkdir ~/.cache/starship")
    add_env_entry ("starship init nu | save ~/.cache/starship/init.nu")
    add_config_entry ("source ~/.cache/starship/init.nu")

    # touch $"($nu.home-path)/.config/starship.toml"
    cp ./defaults/starship/starship.toml ~/.config/starship.toml
    # cp ./defaults/starship/starship.toml ~/.config/starship.toml
}

def configure_zoxide [] {
    log "Configuring zoxide"
    add_env_entry (
        "zoxide init nushell --hook prompt | save ~/.zoxide.nu"
    )
    add_config_entry "source ~/.zoxide.nu"
}

def configure_fzf [] {
    log "Configuring fzf"
    # TODO: ask user where FZF is installed
    let fzf_path = "~/dev/fzf/bin"
    add_config_entry ($"let-env PATH = \(prepend_to_path ($fzf_path))")
    add_config_entry ("
def prepend_to_path [p: path] {
    if ($p in $env.PATH) {
        $env.PATH | uniq
    } else {
        $env.PATH | prepend $p | uniq
    }
}" | str trim)
}

def add_env_entry [...msg: string] {
    $msg | prepend '' | save --append ($nu.env-path)
}

def add_config_entry [...msg: string] {
    $msg | prepend '' | save --append ($nu.config-path)
}

def log [...msgs: string] {
    $msgs | insert 0 "[fetch-tools]" | str collect ' '
}

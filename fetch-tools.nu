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
        rustup component add rust-src
        install_rust_analyzer "2022-08-15" # works with Rust v1.63
    }

    install_bins
    install_emacs

    let marker_path = $"($nu.home-path)/.zonza"
    if ($marker_path | path exists) {
        log "Updated the ZO.N.Z.A. stack"
    } else {
        log "Configuring the ZO.N.Z.A. stack components..."
        configure_nushell
        configure_alacritty
        configure_zellij
        configure_starship
        # configure_zoxide
        # configure_fzf
        configure_fnm
    }
    touch $marker_path
}

def install_rust_analyzer [date: string] {
    let base_url = "https://github.com/rust-lang/rust-analyzer/releases/download"
    let binfile = "rust-analyzer-x86_64-unknown-linux-gnu"
    let rafile = $"($binfile).gz"
    let tmp_dir = $"/tmp/rust-analyzer"
    mkdir $tmp_dir
    log "Installing rust-analyzer"
    fetch --raw $"($base_url)/($date)/($rafile)"
    | save --raw $"($tmp_dir)/($rafile)"
    gzip -d $"($tmp_dir)/($rafile)"

    chmod +x $"($tmp_dir)/($binfile)"
    mv $"($tmp_dir)/($binfile)" ~/bin/rust-analyzer
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
            libgccjit0 # for Emacs native compilation
            libgccjit-12-dev # for Emacs native compilation
            autoconf # for compiling Emacs
            make # for compiling Emacs
            texinfo # Emacs dependency
            libgtk-3-dev # Emacs dependency
            gnutls-dev # Emacs dependency
            libgif-dev # Emacs dependency
            libxpm-dev # Emacs dependency
            libtinfo-dev # Emacs dependency
            librsvg2-dev # Emacs dependency
            libxml2-dev # Emacs dependency
            libsystemd-dev # Emacs dependency
            libjansson-dev # Emacs dependency
            libgmp-dev # Emacs dependency
            kde-plasma-desktop # Gnome3 still sucks in 2022
            chromium-browser # Firefox doesn't work everywhere anymore
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
    install_fzf                     # Useful together with zoxide
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
    cargo_install fnm --git https://github.com/zaucy/fnm.git --branch feat/nushell-support # the Fast NodeJS Manager
    cargo_install grex --locked # Generate regexes from samples
    cargo_install hyperfine # CLI benchmarking tool
    cargo_install irust --locked # A Rust REPL
    cargo_install ripgrep # modern update to `grep`
    cargo_install rusty-man # CLI viewer for rustdoc docs
    cargo_install tokei # SLOC stats
    cargo_install wasm-bindgen-cli # essential Rust WASM tooling
    cargo_install wasm-pack # essential Rust WASM tooling
    install_lazygit # TUI for git
}

def install_emacs [] {
    let bin_dir = $"($nu.home-path)/bin"
    let emacs_dir = $"($bin_dir)/emacs"
    mkdir $bin_dir
    cd $bin_dir
    if (not ($"($emacs_dir)/.git" | path exists)) {
        rm -rf $"($emacs_dir)"
        git clone https://github.com/emacs-mirror/emacs.git $"($emacs_dir)"
    } else {
        log "Found existing emacs directory"
    }
    cd $"($emacs_dir)"
    git pull origin master
    ./autogen.sh
    let-env CFLAGS = (
        "-I/usr/lib/gcc/x86_64-linux-gnu/12/include -L/usr/lib/gcc/x86_64-linux-gnu/12"
    )
    ./configure [
        --with-native-compilation
        --with-rsvg
        --with-png
        --with-jpeg
        --with-gif
        --with-gtk
        --with-dbud
        --with-modules
        --without-pop
    ];
    make -j 12
    sudo make install;
    if ("~/.emacs.d/.git" | path exists) {
        log "Found existing Prelude config"
    } else {
        log "Installing Prelude"
        curl -L https://git.io/epre | sh
    }
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
    --branch: string,
] {
    let options = ([
        (if ($locked) { "--locked" } else { "" })
        (if ($force) { "--force" } else { "" })
        (if ($all_features) { "--all-features" } else { "" })
        (if ($version != $nothing) { $"--version=($version)" } else { "" })
        (if ($git != $nothing) { $"--git=($git)" } else { "" })
        (if ($branch != $nothing) { $"--branch=($branch)" } else { "" })
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

def install_fzf [] {
    let tmp_dir = "/tmp/fzf"
    let bin_dir = $"($nu.home-path)/bin"
    mkdir $bin_dir
    log "Installing fzf"
    if ($"($tmp_dir)/.git" | path exists) {
        log "fzf git repo found"
    } else {
        rm -rf $tmp_dir # prevent dir content mingling
        git clone https://github.com/junegunn/fzf.git --depth 1 $tmp_dir
    }
    cd $tmp_dir
    ./install --no-bash --no-zsh --no-fish
    do -i {
        cp $"($tmp_dir)/bin/fzf" $"($bin_dir)/fzf"
    }
}

def configure_nushell [] {
    log "Configuring nushell"
    cp -r ./defaults/nushell/config.nu ~/.config/nushell/config.nu
    cp -r ./defaults/nushell/env.nu    ~/.config/nushell/env.nu
}

def configure_alacritty [] {
    log "Configuring alacritty"
    let user = ($"$env.USER")
    let alacritty_dir = "/home/($user)/.config/alacritty"
    cp -r ./defaults/alacritty $"($alacritty_dir)"

    let version = "0.10.1"
    let base_url = ("https://github.com/alacritty/alacritty/releases/download")
    let svg_filename = "Alacritty.svg"
    fetch --raw $"($base_url)/v($version)/($svg_filename)"
    | save --raw $"($alacritty_dir)/($svg_filename)";

    # TODO: .desktop files are only for Linux systems, not MacOS or Windows.
    let desktop_filename = "Alacritty.desktop"
    ($"[Desktop Entry]
Type=Application
TryExec=alacritty
Exec=/home/($user)/.cargo/bin/alacritty
Icon=($alacritty_dir)/($svg_filename)
Terminal=false
Categories=System;TerminalEmulator;

Name=Alacritty
GenericName=Terminal
Comment=A fast, cross-platform, OpenGL terminal emulator
StartupWMClass=Alacritty
Actions=New;

[Desktop Action New]
Name=New Terminal
Exec=/home/($user)/.cargo/bin/alacritty")
    | save --raw "~/.local/share/applications/($desktop_filename)"

    desktop-file-install [
        "~/.local/share/applications/($desktop_filename)"
        --dir "~/.local/share/applications/"
    ]
}

def configure_zellij [] {
    log "Configuring zellij"
    cp -r ./defaults/zellij ~/.config/zellij
}

def configure_starship [] {
    log "Configuring starship"
    cp ./defaults/starship/starship.toml ~/.config/starship.toml
}

# def configure_zoxide [] {
#     # log "Configuring zoxide"
# }

# def configure_fzf [] {
#     # log "Configuring fzf"
#     # TODO: ask user where FZF is installed
# }

def configure_fnm [] {
    log "Configuring fnm"
    # TODO: re-enable autoconfigure based on fnm iteself
    # fnm env --shell=nushell --use-on-cd | save --append ($nu.config-path)
}

def log [...msgs: string] {
    $msgs | insert 0 "[fetch-tools]" | str collect ' '
}

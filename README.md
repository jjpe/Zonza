# The ZO.N.Z.A. stack

## Introduction

The ZO.N.Z.A. stack is an opinionated combination of the following tools:

- At the bottom, [Alacritty](https://github.com/alacritty/alacritty). This is a
  blazing fast, GPU-accelerated terminal emulator
- On top of Alacritty is [Zellij](https://github.com/zellij-org/zellij), a
  human-friendly and self-documenting terminal multiplexer (similar to tmux
  and screen). Its role here is to provide support for tabs and pane splitting
  within the terminal.
- On top of that, [Nushell](https://github.com/nushell/nushell) as shell. This
  is a modern, pipeline-oriented shell with a powerful scripting language
- The cherry on top is [Zoxide](https://github.com/ajeetdsouza/zoxide), a
  powerful and easy to use way to navigate around

All of these projects are:
- Written in Rust
- Cross-platform
- Configurable

## But why? Why not just use the default tools for `$OS`?

Ironically this journey started in the middle of the cake, with `Nushell`. I was
already kind of fed up with the `Bash` language, I find working with it is no
fun at all and often even frustrating. Simple things are hard and require
constant lookup due to a lack of consistency within the `Bash` language.
`Zsh` is a marginal improvement in this regard, small things but nothing major.

So I tried `Nushell`, and I've found it such an improvement over `Bash` and `Zsh`
in this regard that I decided to switch shells.
I also knew about the GPU rendering capabilities of `Alacritty`, so it occurred
to me that perhaps I should try a wholesale stack upgrade of both shell and
terminal.

`Alacritty` is a pretty cool piece of tech. However, 1 thing Alacritty does
not do is provide support for tabs or pane splitting. Enter `Zellij`, so that
easy navigation between multiple shell instances is possible in a sane way.
`Zellij` accomplishes this by providing a self-documenting TUI.

The final piece is Zoxide, which I included because I like convenient navigation :)

## Installation

1. Clone this repo
2. Run the `setup.sh` script. This will download a temporary Nushell instance,
   then execute the `fetch-tools.nu` script with it.

NOTE: At present I have invested no effort in providing Windows or MacOS
   versions, though these should be possible.

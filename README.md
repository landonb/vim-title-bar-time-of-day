# vim-command-line-clock

An answer to the age-old question after hiding the macOS menu bar,

[*Quelle heure est il?*](https://www.google.com/search?q=Quelle+heure+est+il)

## Introduction

In MacVim, this plugin maintains a clock in the command window.

*(WIP: I'm also demoing a clock in the titlebar. This plugin is new and these first few commits are very much works-in-progress. -2021-02-01)*

### Requirements

This plug-in requires Vim v8.0 or greater, to take advantage of timers.

## Usage

Nothing. If this plugin is loaded, it'll show a clock in MacVim.

## Options

To set an option, include a line like the following in your `~/.vimrc`:

  ```
  let g:CommandLineClockDisabled = 1
  ```

The following options are available:

- `g:CommandLineClockDisabled` — Boolean value; either 0 or 1 (default: 0)

  Set this variable truthy to disable the plugin.

- `g:CommandLineClockRepeatTime` — Non-negative integer value (default: 1010).

  Determines how often to run the timer that updates the clock (in milliseconds).

## Installation

Installation is easy using the packages feature (see ``:help packages``).

If you want the plugin to load automatically on Vim startup,
use a ``start/`` directory, e.g.,

  ```shell
  mkdir -p ~/.vim/pack/landonb/start
  ```

And then clone the project to that path:

  ```shell
  cd ~/.vim/pack/landonb/start
  git clone https://github.com/landonb/vim-command-line-clock.git
  ```

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

  ```shell
  mkdir -p ~/.vim/pack/landonb/opt
  cd ~/.vim/pack/landonb/opt
  git clone https://github.com/landonb/vim-command-line-clock.git

  " When ready, load the [opt]ional plugin (or is it [opt]-in?).
  :packadd! vim-command-line-clock
  ```

To build the help, ensure the plugin is loaded, and then
run the following command just one time from within Vim:

  ```shell
  :Helptags
  ```

Or, you can build the help from the terminal instead. Run:

  ```shell
  vim -u NONE -c "helptags vim-command-line-clock/doc" -c q
  ```

And then to view the help from within Vim, run:

  ```shell
  :help vim-command-line-clock
  ```

Enjoy!


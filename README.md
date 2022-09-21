# vim-title-bar-time-of-day

An answer to the age-old question after hiding the macOS menu bar,

[*Quelle heure est il?*](https://www.google.com/search?q=Quelle+heure+est+il)

## Introduction

This plugin shows the date and time of day in the Vim titlebar.

The author finds this useful on macOS, because I like to hide the
macOS menu bar, which is normally where you'd see the clock.

### Requirements

This plug-in requires Vim v8.0 or greater, to take advantage of timers.

## Usage

Nothing. If this plugin is loaded, it'll show a clock in the titlebar.

## Options

To set an option, include a line like the following in your `~/.vimrc`:

  ```
  let g:TitleBarTimeOfDayDisabled = 1
  ```

The following options are available:

- `g:TitleBarTimeOfDayDisabled` — Boolean value; either 0 or 1 (default: 0)

  Set this variable truthy to disable the plugin.

- `g:TitleBarTimeOfDayRepeatTime` — Non-negative integer value (default: 101).

  Determines how often to run the timer that updates the clock (in milliseconds).

## See Also

If you'd like to show a clock in the Vim command window, see a similar plugin:
[vim-command-line-clock](https://www.github.com/landonb/vim-command-line-clock)

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
  git clone https://github.com/landonb/vim-title-bar-time-of-day.git
  ```

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

  ```shell
  mkdir -p ~/.vim/pack/landonb/opt
  cd ~/.vim/pack/landonb/opt
  git clone https://github.com/landonb/vim-title-bar-time-of-day.git

  " When ready, load the [opt]ional plugin (or is it [opt]-in?).
  :packadd! vim-title-bar-time-of-day
  ```

To build the help, ensure the plugin is loaded, and then
run the following command just one time from within Vim:

  ```shell
  :Helptags
  ```

Or, you can build the help from the terminal instead. Run:

  ```shell
  vim -u NONE -c "helptags vim-title-bar-time-of-day/doc" -c q
  ```

And then to view the help from within Vim, run:

  ```shell
  :help vim-title-bar-time-of-day
  ```

Enjoy!


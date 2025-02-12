# vim-title-bar-time-of-day 🕰️

An answer to the age-old question after hiding all desktop menu bars,
docks, and panels,

[*Quelle heure est il?*](https://www.google.com/search?q=Quelle+heure+est+il)

## Introduction

This plugin shows the date and time in the Vim titlebar.

The author finds this useful on macOS and GNOME Shell, because I like
to hide the menu bar, which is normally where you'd see the clock.

## Features

This plugin generates a fairly standard title, albeit with a few
extra features.

- If `ITERM_SESSION_ID` is defined, the window ID [0-9] is printed
  first, followed by a dot and a space (e.g., "1. ").

  - This enables you to add OS accelerators to find-and-front terminal
    windows using their window number, even when running (n)vim in the
    shell (e.g., you might use `<Cmd-1>` to front the window with the
    "1. " prefix, `<Cmd-2>` to front the "2. " window, etc.).

- The file name follows next.

  - You'll usually see the base name before other values,
    in case the window is narrow and that's all you can see.

- The modification indicator comes after.

- Then the full path.

- Next the server or socket name.

- And finally the date and time.

For example, here's a screenshot of the Vim titlebar running on Linux Mint MATE:

![vim-title-bar-time-of-day example](doc/assets/vim-title-bar-time-of-day-MATE-desktop.png "vim-title-bar-time-of-day example")

## Configuration

[lazy.nvim]: https://github.com/folke/lazy.nvim
[vim-plug]: https://github.com/junegunn/vim-plug

This plugin is inactive by default.

Call its `Setup({opts})` function to load and unload it.

E.g., here's how you might install and configure the plugin
from Lua using [`lazy.nvim`][lazy.nvim]:

    ```
    {
      "landonb/vim-title-bar-time-of-day",

      config = function()
        -- These are the default values if you
        -- don't specify them.

        vim.fn['embrace#titlebar#Setup']({
          titlebar_enable = 1,
          clock_rate = 2500,
        })
      end,
    },
    ```

Or from your ``.vimrc``:

    ```
    " These are the default values if you
    " don't specify them.
    call g:embrace#titlebar#Setup({
      \ 'titlebar_enable': 1,
      \ 'clock_rate': 2500,
      \ })
    ```

Some notes:

- When `titlebar_enable` is truthy, the `clock_rate` controls how often the
  background timer runs. The background timer is used to update the titlebar
  clock, so that if you're not using (Neo)Vim, the clock still updates
  (otherwise the plugin only refreshes the titlebar when you interact with a
  buffer). If you set a longer clock rate, the title bar clock may not
  update for that many milliseconds after the minute changes.

### Requirements

This plug-in requires Vim v8.0 or greater, or Neovim, for `timer`
support.

## Installation

Install this plugin like you would any Neovim or Vim plugin —
probably using [`lazy.nvim`][lazy.nvim] or [`vim-plug`][vim-plug].

## See Also

If you'd like to show a clock in the status line, see another plugin I publish:
[dubs_mescaline](https://github.com/landonb/dubs_mescaline) 🍄

If you'd like to add OS accelerators to find-and-front windows using their
terminal window numbers, check out [Hammerspoon](https://www.hammerspoon.org/)
for macOS, or [`window-calls`](https://github.com/ickyicky/window-calls) for
GNOME Shell.


" Maintain a clock in the title bar
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-title-bar-time-of-day
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2021 Landon Bouma.

" Age-old answer to Quelle heure est il on a mac with no menu bar.

" Note that the titlebar title in MacVim does not update regularly,
" but only when you are interacting with Vim. So you might want to
" consider an alternative (or better yet, complementary) plugin to
" display a clock in the command line window instead (or in addition):
"
"     https://github.com/landonb/vim-command-line-clock

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" YOU: Uncomment next 'unlet', then <F9> to reload this file.
"      (Iff: https://github.com/landonb/vim-source-reloader)
"
" silent! unlet g:loaded_plugin_title_bar_time_of_day

if exists('g:loaded_plugin_title_bar_time_of_day') || &cp || v:version < 800
    finish
endif

let g:loaded_plugin_title_bar_time_of_day = 1

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" Timer ID, which would never be called except on <F9> plug reload.
let s:timer = 0

function! s:StopTheClock()
  if ! exists('s:timer') || ! s:timer | return | endif

  echom "Stopping timer: " . s:timer
  call timer_stop(s:timer)
  let s:timer = 0
endfunction

function! s:StartTheClock()
  call s:StopTheClock()

  " Guard clause: Users opt-out by setting g:TitleBarTimeOfDayDisabled truthy.
  if exists('g:TitleBarTimeOfDayDisabled') && g:TitleBarTimeOfDayDisabled
    return
  endif


  " Timer repeat time, configurable via g:TitleBarTimeOfDayRepeatTime.
  " - The timer delay determines the longest length of time after the clock
  "   time changes that the user might have to wait until the clock updates.
  if !exists('g:TitleBarTimeOfDayRepeatTime')
    let g:TitleBarTimeOfDayRepeatTime = 101
  endif

  let s:timer = timer_start(g:TitleBarTimeOfDayRepeatTime, 'TitleBarTimeOfDayPaint', { 'repeat': -1 })
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! TitleBarTimeOfDayPaint(timer)
  let l:clock_day = strftime('%Y-%m-%d')
  let l:clock_hours = strftime('%H:%M')
  let l:clock_datetime = printf('%s %s', l:clock_day, l:clock_hours)

  " +++

  " See `:h statusline` for % meanings in the `titlestring`.
  "
  " - %F is full path
  "   %f is path relative to lcd
  "   %m is modified flag
  "
  " - Note that Vim defaults to `titlestring=` which generates a title
  "   similar to this but not exactly the same:
  "
  "       exec "set titlestring=%t\\ %m\\ (%f)\\ -\\ " . v:servername
  "
  "   The difference being that the %f is more like an expand('%:~:h'), i.e.,
  "   the basename of the file, and ~-prefixed rather than absolute, when
  "   relevant. (And I don't see a %-var to choose such a format.)

  " NOTE: MacVim precedes titlestring with a file icon.
  " - I hoped to find a way to control it, but so far have not.
  "   - I tried set noicon, nothing.
  "   - I tried set guioptions-=i, nothing.
  "   - I tried set guioptions+=i, hides the command line clock (doesn't matter
  "     if command line window `echo` before or after).

  " NOTE: I cannot figure out how to force update the titlebar title.
  " That is, setting titlestring does not take effect immediately, but
  " will await the next key press or mouse movement.
  " - This has an interesting side-effect of letting you know how long
  "   you've been staring at the screen or playing with your phone, etc.
  "   By which I mean, how long you've been not Vimming -- if you also
  "   run vim-command-line-clock, that clock will continue to update,
  "   but the vim-title-bar-time-of-day clock will be stuck at the last
  "   time you interacted with Vim. Use that to mark in your dob time
  "   tracker how long you've been away from work, taking a break. =)
  " - I tried `set notitle`, `set titlestring=...`, `set title`... hrmpf.

  " Process specially to get space *exactly* right for modified vs. not.
  " - Note there's sometimes a lag between editing a file and seeing the
  "   the title bar update.
  if getbufinfo(bufnr('%'))[0].changed
    " Modified buffer: show the '+' symbol.
    call s:PaintTheClock_Modified(l:clock_day, l:clock_hours)
  else
    " Use a slightly different format for an unmodified buffer to
    " avoid adding extra whitespace in the title (around the '+').
    call s:PaintTheClock_Unmodified(l:clock_day, l:clock_hours)
  endif

  " Vim doesn't necessarily update the title bar when titlestring is set.
  " For instance, Vim will update the title when you change buffers -- e.g.,
  " you'll see the `%F` and other %-{} options in titlestring update. But
  " Vim uses the old titlestring value. That is, you won't see the expand()
  " value used below nor the updated clock time reflected in the title, at
  " least not until the user moves the cursor, or interacts more with Vim.
  " (So you could type <Ctrl-W w> to move the cursor to the next window,
  "  and the titlebar updates the %-{} options, but it won't reflect the
  "  new titlestring set below -- so you won't see an updated clock time
  "  until moving the cursor or editing.)
  redraw
endfunction

" +++

function! s:PaintTheClock_Modified(clock_day, clock_hours)
  " On GNOME 2/MATE, the title bar title also appears in gnome-panel or
  " mate-panel, which is usually also truncated (...), so show the file-
  " name first, and without leading whitespace, for the cleaneast look.
  if has("gui_gtk2")
    call s:PaintTheClock_Modified_gtk2(a:clock_day, a:clock_hours)
  else
    call s:PaintTheClock_Modified_Rest(a:clock_day, a:clock_hours)
  endif
endfunction

function! s:PaintTheClock_Unmodified(clock_day, clock_hours)
  if has("gui_gtk2")
    call s:PaintTheClock_Unmodified_gtk2(a:clock_day, a:clock_hours)
  else
    call s:PaintTheClock_Unmodified_Rest(a:clock_day, a:clock_hours)
  endif
endfunction

" +++

function! s:PaintTheClock_Modified_gtk2(clock_day, clock_hours)
  " Rather than use titlestring's/statusline's %F, make path specially to be
  " more like default titlestring title (which collapses to ~/ when possible).
  exec "set titlestring=%t\\ \\ \\ \\ %m\\ \\ \\ " . expand('%:~:h') . "\\ \\ \\ \\ «\\ \\ " . tolower(v:servername) . "\\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

function! s:PaintTheClock_Unmodified_gtk2(clock_day, clock_hours)
  " Note: Character before the » is ' ' aka U+2000 En Quad Space.
  " Note: Character before the double quote (") before the expand()
  "       is ' ' aka U+2006 Six-per-Em Space.
  " - Both of these spaces make it so none of the title shifts when
  "   it changes from modified to not, or vice versa! At least in my
  "   Mint MATE 19.3 window manager environment, it looks perfect!
  exec "set titlestring=%t\\ \\ \\  »\\ \\ \\ \\ \\  " . expand('%:~:h') . "\\ \\ \\ \\ «\\ \\ " . tolower(v:servername) . "\\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

" +++

function! s:PaintTheClock_Modified_Rest(clock_day, clock_hours)
  exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ %m\\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

function! s:PaintTheClock_Unmodified_Rest(clock_day, clock_hours)
  exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ \\ «\\ \\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! s:CreateEventHandlers()
  " Note that local l:not_timer won't work during autocmd callback.
  let s:not_timer = -1
  augroup title_bar_time_of_day_autocommands
    autocmd!
    " To ensure there's no delay between switching buffers and the new
    " buffer's filename appearing in the title, don't wait for the timer
    " to fire, but update the title immediately,
    autocmd BufEnter * call TitleBarTimeOfDayPaint(s:not_timer)
    " Similar to changing buffers, also ensure the '+' modified symbol
    " appears as soon as the user edits a buffer.
    " - Normal mode edits.
    autocmd TextChanged * call TitleBarTimeOfDayPaint(s:not_timer)
    " - Insert mode edits, sans popup.
    autocmd TextChangedI * call TitleBarTimeOfDayPaint(s:not_timer)
    " - Like TextChangeI but only when the popup menu is visible.
    autocmd TextChangedP * call TitleBarTimeOfDayPaint(s:not_timer)
    " Just testing this Easter Event I found, out of curiosity.
    " - Oh, haha, it's not implemented, the docs totally tricked me!
    "  autocmd UserGettingBored * echom 'No egg to see here'
  augroup END
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

call s:CreateEventHandlers()

call s:StartTheClock()

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "


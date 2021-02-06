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
    exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ %m\\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . l:clock_day . "',\\ '" . l:clock_hours . "')}"
  else
    exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ \\ «\\ \\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . l:clock_day . "',\\ '" . l:clock_hours . "')}"
  endif

endfunction

call s:StartTheClock()

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "


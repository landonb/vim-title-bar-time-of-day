" Maintain a clock in the command line window *in MacVim*
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-ovm-easyescape-kj-jk
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2021 Landon Bouma.

" Age-old answer to Quelle heure est il on a mac with no menu bar.

" MAYBE/2021-02-01: Make which environments in which to operate user-configurable.
"
" - But I'm just making this for myself on a Monday after as a distraction from
"   real work, and I only need it for @macOS -- where I want to hide the Darwin
"   menu bar, which contains only 1 item of endless value, the clock! (That is,
"   I almost drive exclusively with the keyboard, and I really access menu items,
"   either the application's, the Apple menu, or any of the system tray droppies.)

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" YOU: Uncomment next 'unlet', then <F9> to reload this file.
"      (Iff: https://github.com/landonb/vim-source-reloader)
"
" silent! unlet g:loaded_plugin_command_line_clock

if exists('g:loaded_plugin_command_line_clock') || &cp || v:version < 800
    finish
endif

let g:loaded_plugin_command_line_clock = 1

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" Ref:
"
"   :h cmdline-editing for help on command-line mode and command-line window.

let s:timer = 0

function! s:StopTheClock()
  if ! exists('s:timer') || ! s:timer | return | endif

  echom "Stopping timer: " . s:timer
  call timer_stop(s:timer)
  let s:timer = 0
endfunction

function! s:StartTheClock()
  call s:StopTheClock()

  " Guard clause: Users opt-out by setting g:CommandLineClockDisabled truthy.
  if exists('g:CommandLineClockDisabled') && g:CommandLineClockDisabled
    return
  endif

  " Guard clause: Restrict by runtime context.
  " - (lb): I only want this on @macOS, so I can hide the menu bar.
  "   - I don't care in the other environment I roll, MATE, where I have
  "     the date and clock in the lower right of my display, just below
  "     where you'd see a right-aligned value in the command line window.
  " - MAYBE/2021-02-01: Make platforms on which to run configurable,
  "   for the benefit of all who might use this plugin.
  "   - See:
  "       has('gui_running')
  "       has('nvim')
  "       has('win32') || has('win64')
  "       has('win32unix')
  if ! has('gui_macvim') | return | endif

  " Timer repeat time, configurable via g:CommandLineClockRepeatTime.
  " - The timer delay determines longest wait after minute changes to see clock
  "   updated, and also longest wait after some other message writes to command
  "   window after which the clock will reappear.
  if !exists('g:CommandLineClockRepeatTime')
    let g:CommandLineClockRepeatTime = 1010
  endif

  let s:timer = timer_start(g:CommandLineClockRepeatTime, 'EchoCurrentDateTime', { 'repeat': -1 })
endfunction

function! EchoCurrentDateTime(timer)
  " MAYBE/2021-02-01: Make optional: right-alignment and padding from edge.
  " - Currently, right-aligned with no padding.
  "     let s:cols = &columns - 1
  " - Scratch that, right-aligned with 1 character padding.
  let s:cols = &columns - 2

  " The %{width}S right-aligns a string in the indicated width.
  exec "echo printf('%" . s:cols . "S', strftime('%Y-%m-%d %H:%M'))"

" FIXME/2021-02-01: Evaluate clock time in titlebar alternative:
  " %F is full path, %f is relative to lcd.
  " %m is modified flag
  "  exec "set titlestring=filename\\ %m\\ (%f)\\ -\\ " . v:servername . "\\ -\\ " . strftime('%Y-%m-%d\ %H:%M')
  " Right-aligned, but looks weird, because than filename etc. off-center:
  "  exec "set titlestring=filename\\ %m\\ (%f)\\ -\\ " . v:servername . "\\ -\\ %=\\ " . strftime('%Y-%m-%d\ %H:%M')
  " Here it is with clock padded off right a bit...
  exec "set titlestring=filename\\ %m\\ (%f)\\ -\\ " . v:servername . "\\ -\\ %21.(" . strftime('%Y-%m-%d\ %H:%M') . "%)"

  " Maybe I like just relative path including filename, rather than default
  " 'basename (dirname)' -- with the latter, I always look at the dirname,
  " then scan back to find the filename.
  "exec "set titlestring=%f\\ \\ \\ %m\\ \\ \\ {\\ " . v:servername . "\\ }\\ \\ \\ %(" . strftime('%Y-%m-%d\ %H:%M') . "%)"

  " This is nice, but only relative path, leaves me wanting.
  "  exec "set titlestring={\\ " . v:servername . "\\ }\\ \\ \\ %m\\ \\ \\ «\\ \\ \\ %f\\ \\ \\ »\\ \\ \\ %(" . strftime('%Y-%m-%d\ %H:%M') . "%)"

  exec "set titlestring={\\ " . v:servername . "\\ }\\ \\ \\ %m\\ \\ \\ «\\ \\ \\ %F\\ \\ \\ »\\ \\ \\ %(" . strftime('%Y-%m-%d\ %H:%M') . "%)"

endfunction

call s:StartTheClock()

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "


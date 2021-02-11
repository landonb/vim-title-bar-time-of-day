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

  let s:timer = timer_start(g:TitleBarTimeOfDayRepeatTime, 'TitleBarTimeOfDayTimer', { 'repeat': -1 })
endfunction

function! TitleBarTimeOfDayTimer(timer)
  let l:call_redraw = 1

  call TitleBarTimeOfDayPaint(l:call_redraw)
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" Note that the title bar title does not update immediately when
" `titlestring` is set. It happens on certain events, like BufEnter.
" Or by calling `redraw`. But don't call `redraw` too frequently, or
" it'll have undesired effects, e.g., it clears the output from
" :messages().
"
" Without an explicit `redraw`, moving the cursor or interacting with
" Vim will generally update the title bar title, but if you let Vim sit
" idle, the title bar title (and the clock time we set) are not updated.
" So below we'll hook some events, like BufEnter, and TextChanged*, so
" that we can ensure the title bar title is updated promptly (because
" Vim will always redraw the title bar title after processing certain
" autocommands, like BufEnter).
"
" - Note that if we only used the timer event, and if we removed the
"   autocommand hooks (BufEnter, TextChanged, etc.) and didn't call
"   `redraw`, so that the title bar title only updates when the user
"   interacts with Vim, it has an interesting side-effect. It lets
"   you know how long you've been staring at the screen or playing
"   with your phone, etc. By which I mean, how long you've been not
"   Vimming. For instance, if you also run vim-command-line-clock,
"   that clock will continue to update while you're idle, but the
"   vim-title-bar-time-of-day clock will be stuck at the last time you
"   interacted with Vim. And you could use that to mark in your dob time
"   time tracker how long you've been not working, or taking a break. =)

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

let s:previous_clock_datetime = ''

function! TitleBarTimeOfDayPaint(call_redraw)
  let l:clock_day = strftime('%Y-%m-%d')
  let l:clock_hours = strftime('%H:%M')
  let l:clock_datetime = printf('%s %s', l:clock_day, l:clock_hours)

  " +++

  " Not that I saw a problem with setting titlestring frequently, but there's
  " no reason to continue if the clock has not changed nor anything of import.
  " - Note that call_redraw = 1 means the timer called us, in which case only
  "   maybe the clock changed; but when call_redraw = 0, it means BufEnter or
  "   TextChanged*, and we should always update titlestring.
  if (a:call_redraw == 1) && (l:clock_datetime == s:previous_clock_datetime)
    return
  endif

  " +++

  " Set a slightly different titlestring depending on if the '+' modifier
  " is expected to show or not, so that we can get the spacing *exactly*
  " right. Specifically, I don't like it when the different parts of the
  " title -- filename, path, server name, date, and delimiters -- shift
  " around slightly when the buffer modified status changes.
  if getbufinfo(bufnr('%'))[0].changed
    " Modified buffer: show the '+' symbol.
    call s:PaintTheClock_Modified(l:clock_day, l:clock_hours)
  else
    " Use a slightly different format for an unmodified buffer to avoid
    " adding extra whitespace in the title (around the '+'), and to
    " better align the parts title so there's as little a noticeable
    " change as possible it the title when you start editing.
    call s:PaintTheClock_Unmodified(l:clock_day, l:clock_hours)
  endif

  let l:redrawed = s:ForceTitleBarTitleRedraw(a:call_redraw)

  if l:redrawed || (a:call_redraw == 0)
    let s:previous_clock_datetime = l:clock_datetime
  endif
endfunction

" +++

" MAYBE/2021-02-09: I decided that I like the gtk2 style on macOS, too,
" so I disabled the macOS variants, but maybe make this style optional.
" (The PaintTheClock_Modified_Rest/PaintTheClock_Unmodified_Rest fcns.)

function! s:PaintTheClock_Modified(clock_day, clock_hours)
  " On GNOME 2/MATE, the title bar title also appears in gnome-panel or
  " mate-panel, which is usually also truncated (...), so show the file-
  " name first, and without leading whitespace, for the cleaneast look.
  "
  "  if has("gui_gtk2")
  "    call s:PaintTheClock_Modified_gtk2(a:clock_day, a:clock_hours)
  "  else
  "    call s:PaintTheClock_Modified_Rest(a:clock_day, a:clock_hours)
  "  endif
  "
  " On second thought, having the filename first looks good on macOS, too.
  call s:PaintTheClock_Modified_gtk2(a:clock_day, a:clock_hours)
endfunction

function! s:PaintTheClock_Unmodified(clock_day, clock_hours)
  "  if has("gui_gtk2")
  "    call s:PaintTheClock_Unmodified_gtk2(a:clock_day, a:clock_hours)
  "  else
  "    call s:PaintTheClock_Unmodified_Rest(a:clock_day, a:clock_hours)
  "  endif
  "
  " On second thought, having the filename first looks good on macOS, too.
  call s:PaintTheClock_Unmodified_gtk2(a:clock_day, a:clock_hours)
endfunction

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
"   relevant. (And I don't see a %-var that matches that format, so we'll
"   hard code that path in titlestring, which is another reason we need to
"   manage `redraw` specially, as commented above.)

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

" Note: MacVim precedes titlestring with a file icon.
" - I hoped to find a way to control it, but so far have not.
"   - I tried set noicon, nothing.
"   - I tried set guioptions-=i, nothing.
"   - I tried set guioptions+=i, hides the command line clock (does
"     not matter if command line window `echo` before or after).

function! s:PaintTheClock_Modified_Rest(clock_day, clock_hours)
  exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ %m\\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

function! s:PaintTheClock_Unmodified_Rest(clock_day, clock_hours)
  exec "set titlestring=\\ \\ \\ " . tolower(v:servername) . "\\ \\ \\ \\ \\ «\\ \\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! s:ForceTitleBarTitleRedraw(call_redraw)
  " Don't redraw in certain modes. E.g., if you run `:messages`, which
  " is 'r' mode, `redraw` will dismiss the output. Note that when
  " :messages is open, the title bar will still eventually update,
  " even if we're not calling `redraw` here. (lb): I tested and ran
  " `:messages` and left it's prompt unanswered, and it took ~10 secs.
  " after the minute changed for Vim to update the title bar title.
  " Though I've also tested with the timer only, no redraw, and no
  " autocommands, and I've seen Vim not update the title bar at all
  " until the user interacts with Vim. In any case, be picky about
  " modes we'll redraw from.
  if mode() !=# 'n' && mode() !=# 'i' && mode() !=# 's' | return 0 | endif

  if (a:call_redraw == 1)
    redraw
    return 1
  endif

  return 0
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! s:CreateEventHandlers()
  " Vim doesn't update the title bar title when titlestring is set, but
  " waits until the next redraw (lb: I have not checked sources, so my
  " explanation here may not be 100% accurate). We could call `redraw`
  " explicitly, if necessary, but Vim also redraws automatically after
  " certain autocommands, like BufEnter (lb: at least that's my
  " experience, e.g., if we set titlestring on BufEnter, the new
  " titlestring shows up immediately). The TextChanged* autocommands also
  " appear to precede a redraw, and drive the '+' modified indicator.

  " [Note: Using s:variables, as autocmd callback can't see l:ocals.]
  " No need to call redraw, as Vim will do it soon enough.
  let s:_call_redraw = 0

  augroup title_bar_time_of_day_autocommands
    autocmd!
    " Changing buffers affects filename, path, and modified.
    autocmd BufEnter * call TitleBarTimeOfDayPaint(s:_call_redraw)
    " Reacting to file-saved seems necessary, but empirical evidence
    " suggests this is not necessary. So not necessary, but complete!
    autocmd BufWritePost * call TitleBarTimeOfDayPaint(s:_call_redraw)
    " Editing the buffer might change the '+' modified symbol.
    " - Normal mode edits.
    autocmd TextChanged * call TitleBarTimeOfDayPaint(s:_call_redraw)
    " - Insert mode edits, sans popup.
    autocmd TextChangedI * call TitleBarTimeOfDayPaint(s:_call_redraw)
    " - Like TextChangeI but only when the popup menu is visible.
    autocmd TextChangedP * call TitleBarTimeOfDayPaint(s:_call_redraw)
    " Just testing this Easter Event I found, out of curiosity.
    " - Oh, haha, it's not implemented, the docs totally tricked me!
    "  autocmd UserGettingBored * echom 'No egg to see here'
  augroup END
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

call s:CreateEventHandlers()

call s:StartTheClock()

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "


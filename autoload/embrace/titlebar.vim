" Maintain a clock in the title bar
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-title-bar-time-of-day#🕰️
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2021 Landon Bouma.

" -------------------------------------------------------------------

function! g:embrace#titlebar#StopTheClock() abort
  if ! exists('s:timer') || ! s:timer

    return
  endif

  echom "Stopping timer: " . s:timer

  call timer_stop(s:timer)

  let s:timer = 0
endfunction

function! g:embrace#titlebar#StartTheClock() abort
  call g:embrace#titlebar#StopTheClock()

  " Guard clause: Users opt-out by setting g:TitleBarTimeOfDayDisabled truthy.
  if exists('g:TitleBarTimeOfDayDisabled') && g:TitleBarTimeOfDayDisabled

    return
  endif

  " Implicit enable in Vim on `set titlestring=`, but must be explicitly
  " enabled in Neovim.
  " - Can also be set inline with titlestring; see below.
  "
  "  set title

  " Timer repeat time, configurable via g:TitleBarTimeOfDayRepeatTime.
  " - The timer delay determines the longest length of time after the clock
  "   time changes that the user might have to wait until the clock updates.
  if !exists('g:TitleBarTimeOfDayRepeatTime')
    let g:TitleBarTimeOfDayRepeatTime = 3123
  endif

  call s:TitleBarTimeOfDayTaint()

  call s:CaptureServernamePostfix()

  let s:timer = timer_start(g:TitleBarTimeOfDayRepeatTime, 'TitleBarTimeOfDayTimer', { 'repeat': -1 })
endfunction

function! TitleBarTimeOfDayTimer(timer) abort
  let l:clock_check = 1

  call TitleBarTimeOfDayPaint(l:clock_check)
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" The Vim servername, or part of the Neovim socket name, is included
" in the Vim titlebar title and can be used to find and front a
" Vim/Neovim TUI or GUI window.

" CXREF: If the nvim server was started by author's open shim,
"        the substitute below removes the uninteresting path
"        prefix used by the shim.
"        - See:
"          https://github.com/DepoXy/gvim-open-kindness#🐬
" - That project lets you open files in the same Vim, GVim, MacVim,
"   Neovim, Neovide, etc., instance, from callers in different domains,
"   e.g., the user calling from the command line, or an OS accelerator
"   calling from Hammerspoon (or Karabiner Elements, or skhd, or GNOME
"   Shell Keyboard Shortcuts), or a tig-newtons tig command, or the
"   `mropen` myrepos command, etc.
" - The user can customize the socket name using an environ named
"   NVIM_OPEN_SOCKETNAME. The value is used to suffix the socket name,
"   which is created under /tmp using the common prefix, "nvim.socket-".
"   - For example, using
"       NVIM_OPEN_SOCKETNAME="💚"
"     will create the socket:
"       /tmp/nvim.socket-💚
"   - And here we ensure the prefix isn't printed to the titlebar.
"
" CXREF: On macOS, the gvim-open-kindness script also uses the
"        URISetFrontmost Spoon from Hammyspoony:
"      https://github.com/DepoXy/macOS-Hammyspoony#🥄
"   https://github.com/DepoXy/macOS-Hammyspoony/blob/release/Source/URISetFrontmost.spoon/init.lua
" Which effectively calls:
"   hs.window.find(<s:servername>):raise:focus()
" To bring the nvim TUI window to the front.
" - Note that both gvim-open-kindness and URISetFrontmost rely on
"   this or a similar plugin printing the socket name postfix
"   to the Vim title for all this "magic" to shine.
" - The gvim-open-kindness script also works on Wayland, albeit
"   requiring a third-party GNOME Extension to find the window.

function! s:CaptureServernamePostfix() abort
  let s:servername = v:servername

  if has('nvim')
    let l:sock_fmt = get(g:, 'TitleBarTimeOfDayServernameFormat', '^/tmp/nvim.socket-')
    let s:servername = substitute(v:servername, l:sock_fmt, '', '')
  endif
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

function! s:TitleBarTimeOfDayTaint() abort
  let s:previous_clock_datetime = ''
  let s:previous_modified = -1
endfunction

function! TitleBarTimeOfDayPaint(clock_check = 0) abort
  let s:clock_datetime = strftime('%Y-%m-%d %H:%M')

  " Not that I saw a problem with setting titlestring frequently, but there's
  " no reason to continue if the clock has not changed nor anything of import.
  " - Note that clock_check = 1 means the timer called us, in which case only
  "   maybe the clock changed; but when clock_check = 0, it means BufEnter or
  "   TextChanged*, and we should always update titlestring.
  if (a:clock_check == 1) && (s:clock_datetime == s:previous_clock_datetime)

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
    if s:previous_modified != 1
      call s:PaintTheClock_Modified()
    endif
    let s:previous_modified = 1
  else
    " Use a slightly different format for an unmodified buffer to avoid
    " adding extra whitespace in the title (around the '+'), and to
    " better align the parts title so there's as little a noticeable
    " change as possible it the title when you start editing.
    if s:previous_modified != 0
      call s:PaintTheClock_Unmodified()
    endif
    let s:previous_modified = 0
  endif

  if s:ForceTitleBarTitleRedraw()
    let s:previous_clock_datetime = s:clock_datetime
  endif
endfunction

" +++

" MAYBE/2021-02-09: I decided that I like the gtk2 style on macOS, too,
" so I disabled the macOS variants, but maybe make this style optional.
" (The PaintTheClock_Modified_Rest/PaintTheClock_Unmodified_Rest fcns.)

function! s:PaintTheClock_Modified() abort
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
  call s:PaintTheClock_Modified_gtk2()
endfunction

function! s:PaintTheClock_Unmodified() abort
  "  if has("gui_gtk2")
  "    call s:PaintTheClock_Unmodified_gtk2(a:clock_day, a:clock_hours)
  "  else
  "    call s:PaintTheClock_Unmodified_Rest(a:clock_day, a:clock_hours)
  "  endif
  "
  " On second thought, having the filename first looks good on macOS, too.
  call s:PaintTheClock_Unmodified_gtk2()
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
"       exec "set titlestring=%t\\ %m\\ (%f)\\ -\\ " . s:servername
"
"   The difference being that the %f is more like an expand('%:~:h'), i.e.,
"   the basename of the file, and ~-prefixed rather than absolute, when
"   relevant. (And I don't see a %-var that matches that format, so we'll
"   hard code that path in titlestring, which is another reason we need to
"   manage `redraw` specially, as commented above.)

function! s:PaintTheClock_Modified_gtk2() abort
  " Rather than use titlestring's/statusline's %F, make path specially to be
  " more like default titlestring title (which collapses to ~/ when possible).
  exec "set title titlestring=%t\\ \\ \\ \\ %m\\ \\ \\ %{g:embrace#titlebar#TildePrefixedPath()}\\ \\ \\ \\ «\\ \\ " . s:servername . "\\ \\ »\\ \\ \\ \\ %{g:embrace#titlebar#DateAndTimeString()}"
endfunction

function! s:PaintTheClock_Unmodified_gtk2() abort
  " Note: Character before the » is ' ' aka U+2000 En Quad Space.
  " Note: Character before the double quote (") before the expand()
  "       is ' ' aka U+2006 Six-per-Em Space.
  " - Both of these spaces make it so none of the title shifts when
  "   it changes from modified to not, or vice versa! At least in my
  "   Mint MATE 19.3 window manager environment, it looks perfect!
  exec "set title titlestring=%t\\ \\ \\  »\\ \\ \\ \\ \\  %{g:embrace#titlebar#TildePrefixedPath()}\\ \\ \\ \\ «\\ \\ " . s:servername . "\\ \\ »\\ \\ \\ \\ %{g:embrace#titlebar#DateAndTimeString()}"
endfunction

" +++

function! g:embrace#titlebar#TildePrefixedPath() abort
  return substitute(expand('%:~:h'), ' ', '\\ ', 'g')
endfunction

function! g:embrace#titlebar#DateAndTimeString() abort
  return s:clock_datetime
endfunction

" +++

" Note: MacVim precedes titlestring with a file icon.
" - I hoped to find a way to control it, but so far have not.
"   - I tried set noicon, nothing.
"   - I tried set guioptions-=i, nothing.
"   - I tried set guioptions+=i, hides the command line clock (does
"     not matter if command line window `echo` before or after).

function! s:PaintTheClock_Modified_Rest(clock_day, clock_hours) abort
  exec "set title titlestring=\\ \\ \\ " . s:servername . "\\ \\ \\ \\ %m\\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

function! s:PaintTheClock_Unmodified_Rest(clock_day, clock_hours) abort
  exec "set title titlestring=\\ \\ \\ " . s:servername . "\\ \\ \\ \\ \\ «\\ \\ \\ \\ %F\\ \\ \\ \\ »\\ \\ \\ \\ %{printf('%s\\ %s',\\ '" . a:clock_day . "',\\ '" . a:clock_hours . "')}"
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! s:ForceTitleBarTitleRedraw() abort
  " Don't redraw in certain modes. E.g., if you run `:messages`, which
  " is 'r' mode, `redraw` will dismiss the output. Note that when
  " :messages is open, the title bar will still eventually update,
  " even if we're not calling `redraw` here. (lb): I tested and ran
  " `:messages` and left its prompt unanswered, and it took ~10 secs.
  " after the minute changed for Vim to update the title bar title.
  " Though I've also tested with the timer only, no redraw, and no
  " autocommands, and I've seen Vim not update the title bar at all
  " until the user interacts with Vim. In any case, be picky about
  " modes we'll redraw from.
  if mode() !=# 'n' && mode() !=# 'i' && mode() !=# 's'

    return 0
  endif

  redraw

  return 1
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

function! g:embrace#titlebar#CreateEventHandlers() abort
  " Vim doesn't update the title bar title when titlestring is set, but
  " waits until the next redraw (lb: I have not checked sources, so my
  " explanation here may not be 100% accurate). We could call `redraw`
  " explicitly, if necessary, but Vim also redraws automatically after
  " certain autocommands, like BufEnter (lb: at least that's my
  " experience, e.g., if we set titlestring on BufEnter, the new
  " titlestring shows up immediately). The TextChanged* autocommands also
  " appear to precede a redraw, and drive the '+' modified indicator.

  augroup title_bar_time_of_day_autocommands
    autocmd!
    " Changing buffers affects filename, path, and modified.
    autocmd BufEnter * call TitleBarTimeOfDayPaint()
    " Reacting to file-saved seems necessary, but empirical evidence
    " suggests this is not necessary. So not necessary, but complete!
    autocmd BufWritePost * call TitleBarTimeOfDayPaint()
    " Editing the buffer might change the '+' modified symbol.
    " - Normal mode edits.
    autocmd TextChanged * call TitleBarTimeOfDayPaint()
    " - Insert mode edits, sans popup.
    autocmd TextChangedI * call TitleBarTimeOfDayPaint()
    " - Like TextChangeI but only when the popup menu is visible.
    autocmd TextChangedP * call TitleBarTimeOfDayPaint()
    " Just testing this Easter Event I found, out of curiosity.
    " - Oh, haha, it's not implemented, the docs totally tricked me!
    "  autocmd UserGettingBored * echom 'No egg to see here'
  augroup END
endfunction


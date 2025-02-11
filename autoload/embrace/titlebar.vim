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

  call s:PrepareWindowNumberPrefix()

  call s:CaptureServernamePostfix()

  let s:timer = timer_start(g:TitleBarTimeOfDayRepeatTime, 'TitleBarTimeOfDayTimer', { 'repeat': -1 })
endfunction

function! TitleBarTimeOfDayTimer(timer) abort
  let l:timer_callback = 1

  call TitleBarTimeOfDayPaint(l:timer_callback)
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
    " - REFER: https://github.com/DepoXy/gvim-open-kindness#🐬
    "   - `gvim-open-kindness` looks for the server name in window titles
    "     to find and front the editor instance.
    let l:sock_fmt = get(g:, 'TitleBarTimeOfDayServernameFormat', '^/tmp/nvim.socket-')
    let s:servername = substitute(v:servername, l:sock_fmt, '', '')
  endif

  " If servername wasn't in gvim-open-kindness format (/tmp/nvim.socket-*)
  " if might be a long path, e.g.,
  "   /var/folders/4r/vs_plqd91h9dclfh5c020cdh0000gn/T/nvim.user/XKp10a/nvim.6590.0
  if s:servername == v:servername
    let s:servername = fnamemodify(v:servername, ":t")
    let s:servername = substitute(s:servername, '[0-9.]\+$', '', '')
  endif
endfunction

" ***

" REFER: sh-humble-prompt adds window number prefix to terminal window
" title via PS1 — and Hammerspoon accelerators (and GNOME accelerators)
" use window number prefix to find-and-front specific terminals.
" - E.g., author uses <Cmd-1> to front terminal window with "1." prefix,
"   <Cmd-2> to front terminal windown with "2." prefix, etc.
"   https://github.com/DepoXy/sh-humble-prompt#🙇
"   https://github.com/DepoXy/macOS-Hammyspoony#🥄
" - The window number is sussed from an environ named ITERM_SESSION_ID,
"   which honors the environment wherein the author first saw this
"   feature (though the feature itself has nothing to do with iTerm).
"   - The value starts with a 'w' followed by a 0-based window number.
"     This is followed by the tab id, not sure that 'p' is for, and
"     then a GUID, none of which we care about.
"   - E.g., w1t0p0:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
" - By including the window number prefix in the (n)vim title, if the
"   user uses (n)vim as their EDITOR, then when (n)vim is running, e.g.,
"   during a `git commit -v`, the OS accelerators will still be able to
"   find that terminal window.

function! s:PrepareWindowNumberPrefix() abort
  let s:winnum_prefix = ''

  if $ITERM_SESSION_ID == ''

    return
  endif

  " Don't include window number prefix in GUI window title string.
  if has('gui_running')

    return
  endif

  let l:winnum = substitute($ITERM_SESSION_ID, '^w\([0-9]\+\).*', '\1', '')

  let s:winnum_prefix = string(str2nr(l:winnum) + 1) .. '.\ '
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
  let s:previous_bufnr = -1
endfunction

function! TitleBarTimeOfDayPaint(timer_callback = 0) abort
  let s:clock_datetime = strftime('%Y-%m-%d %H:%M')

  " Not that I saw a problem with setting titlestring frequently, but there's
  " no reason to continue if the clock has not changed nor anything of import.
  " - Note that timer_callback = 1 means the timer called us, in which case only
  "   maybe the clock changed; but when timer_callback = 0, it means BufEnter or
  "   TextChanged*, and we should always update titlestring.
  if (a:timer_callback == 1) && (s:clock_datetime == s:previous_clock_datetime)

    return
  endif

  " +++

  let l:needs_redraw = 0

  let l:bufnr = bufnr('%')

  " Set a slightly different titlestring depending on if the '+' modifier
  " is expected to show or not, so that we can get the spacing *exactly*
  " right. Specifically, I don't like it when the different parts of the
  " title -- filename, path, server name, date, and delimiters -- shift
  " around slightly when the buffer modified status changes.
  if getbufinfo(l:bufnr)[0].changed
    " Modified buffer: show the '+' symbol.
    if s:previous_modified != 1 || s:previous_bufnr != l:bufnr
      call s:SetTitlestringModified()
      let l:needs_redraw = 1
    endif
    let s:previous_modified = 1
  else
    " Use a slightly different format for an unmodified buffer to avoid
    " adding extra whitespace in the title (around the '+'), and to
    " better align the parts title so there's as little a noticeable
    " change as possible it the title when you start editing.
    if s:previous_modified != 0 || s:previous_bufnr != l:bufnr
      call s:SetTitlestringUnmodified()
      let l:needs_redraw = 1
    endif
    let s:previous_modified = 0
  endif

  let s:previous_bufnr = l:bufnr

  if l:needs_redraw && s:ForceTitleBarTitleRedraw()
    let s:previous_clock_datetime = s:clock_datetime
  endif
endfunction

" +++

" SAVVY: Generally show the filename first, before the full path,
" for cases where only a short snippet of the title can be shown.
" - E.g., the text in GNOME 2/MATE window list icons.
" - For narrow terminal windows.
" - Etc.

" Note: MacVim precedes titlestring with a file icon.
" - I hoped to find a way to control it, but so far have not.
"   - I tried set noicon, nothing.
"   - I tried set guioptions-=i, nothing.
"   - I tried set guioptions+=i, hides the command line clock (does
"     not matter if command line window `echo` before or after).

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

function! s:SetTitlestringModified() abort
  " Rather than use titlestring's/statusline's %F, make path specially to be
  " more like default titlestring title (which collapses to ~/ when possible).
  exec "set title titlestring=" .. s:winnum_prefix .. "%t\\ \\ \\ \\ %m\\ \\ \\ %{g:embrace#titlebar#TildePrefixedPath()}\\ \\ \\ \\ «\\ \\ " . s:servername . "\\ \\ »\\ \\ \\ \\ %{g:embrace#titlebar#DateAndTimeString()}"
endfunction

function! s:SetTitlestringUnmodified() abort
  " Note: Character before the » is ' ' aka U+2000 En Quad Space.
  " Note: Character before the double quote (") before the expand()
  "       is ' ' aka U+2006 Six-per-Em Space.
  " - Both of these spaces make it so none of the title shifts when
  "   it changes from modified to not, or vice versa! At least in my
  "   Mint MATE 19.3 window manager environment, it looks perfect!
  exec "set title titlestring=" .. s:winnum_prefix .. "%t\\ \\ \\  »\\ \\ \\ \\ \\  %{g:embrace#titlebar#TildePrefixedPath()}\\ \\ \\ \\ «\\ \\ " . s:servername . "\\ \\ »\\ \\ \\ \\ %{g:embrace#titlebar#DateAndTimeString()}"
endfunction

" +++

function! g:embrace#titlebar#TildePrefixedPath() abort
  return substitute(expand('%:~:h'), ' ', '\\ ', 'g')
endfunction

function! g:embrace#titlebar#DateAndTimeString() abort
  return s:clock_datetime
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

" -------------------------------------------------------------------

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

" -------------------------------------------------------------------

function! g:embrace#titlebar#Setup() abort
  call g:embrace#titlebar#CreateEventHandlers()
  call g:embrace#titlebar#StartTheClock()
endfunction


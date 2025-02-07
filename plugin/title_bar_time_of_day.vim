" Maintain a clock in the title bar
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-title-bar-time-of-day#🕰️
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2021 Landon Bouma.

" Age-old answer to Quelle heure est il on a mac with no menu bar.

" Note that the titlebar title in MacVim does not update regularly,
" but only when you are interacting with Vim. So you might want to
" consider an alternative (or better yet, complementary) plugin to
" display a clock in the command line window instead (or in addition):
"
"     https://github.com/embrace-vim/vim-command-line-clock

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_plugin_title_bar_time_of_day
endif

" SAVVY: Requires Vim 8+ because timers.
if exists('g:loaded_plugin_title_bar_time_of_day') || &cp || v:version < 800

  finish
endif

let g:loaded_plugin_title_bar_time_of_day = 1

" -------------------------------------------------------------------

call g:embrace#titlebar#Setup()


" trzsz.nvim - Neovim plugin for trzsz file transfer
" Author: Sang
" License: MIT

if exists('g:loaded_trzsz') || &compatible
  finish
endif
let g:loaded_trzsz = 1

" Lua module loader
lua require('trzsz').setup()
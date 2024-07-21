if has('nvim-0.10')
lua<<EOF
  local dmacro = require('dmacro')
  local ns_id = vim.api.nvim_create_namespace('dmacro_record_macro')
  vim.on_key(dmacro.record_macro, ns_id)
  vim.keymap.set({ "i", "n", "v", "x", "s", "o", "c", "t" }, "<Plug>(dmacro-play-macro)", dmacro.play_macro)
  -- Note:
  -- 一文字分のdmacro_keyではなく、複数のキー組合せの列をdmacro_key として指定しても、
  -- vim.on_keyは、そのキー組み合わせが全て入力されたあとの一度のみに発火する。
  -- dmacro_key = "g@" の場合、"g" と "@" の間に vim.on_keyが発火することはない。
  -- "g@" が入力されたときに、"g@"が入力されたとして、ひとまとめに関数が実行される。
EOF
elseif has('patch-9.1.0597')
  augroup Dmacro
    autocmd!
    autocmd KeyInputPre * call dmacro#RecordMacro(v:event.typedchar)
  augroup End
  inoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  nnoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  vnoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  xnoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  snoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  onoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  cnoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
  tnoremap <Plug>(dmacro-play-macro) <Cmd>call dmacro#PlayMacro()<CR>
else
  echoerr "dmacro.vim: Please upgrade to Vim 9.1.0597 or Neovim 0.10.0."
endif

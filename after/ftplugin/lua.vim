" Load manillua.nvim into lua gloabl
lua package.loaded['manillua'] = nil
lua manillua = require('manillua')

setlocal foldmethod=expr
setlocal foldexpr=v:lua.manillua.foldexpr(v:lnum)
setlocal foldtext=v:lua.manillua.foldtext()
setlocal fillchars=fold:\ 


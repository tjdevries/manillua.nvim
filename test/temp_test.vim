let text = "function manillua.foldtext(line_start, line_end, fold_level)"

lua package.loaded['manillua'] = nil
lua package.loaded['str_util'] = nil

lua manillua = require('manillua')
lua str_util = require('str_util')

" lua print(str_util.startswith('_hello', '_'))
lua print(vim.inspect(manillua._get_object_property_attributes("function manillua.foldtext(line_start, line_end, fold_level)")))
lua print(vim.inspect(manillua._get_object_property_attributes("function manillua._foldtext(line_start, line_end, fold_level)")))

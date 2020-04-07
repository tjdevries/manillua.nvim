local vim = vim
local str_util = require('str_util')

--- TODO:
--  - I would to like to perf test some things about `find` vs `match`
--      Especially for simple matches, maybe we can keep pure lua.
--      I think it might be easy enough to define a metatable for the patterns
--          And then, within the metatable, allow them to specify how they will be compared

local l = {}
l.same = '='
l.subtract = function(amount) return string.format("s%s", amount) end
l.add      = function(amount) return string.format("a%s", amount) end
l.start    = function(level)  return string.format(">%s", level)  end
l.finish   = function(level)  return string.format("<%s", level)  end

local patterns = {}

patterns.object_start = '^local .* = {}'
patterns.object_property_start = {
  [[^%.*\..* = function(]],
  [[^function .*\..*(]],
}

patterns.function_start = [[^\%[local ]function]]
patterns.comment_start = "^--\\[^-]"
patterns.docstring_start = [[^---]]
patterns.end_only = '^end$'

patterns.module_return= '^return'

--- Match `str` to `patterns`
-- @param str string - The string to match
-- @param patterns table|string - A single or list of patterns to match upon
local function matches(str, patterns)
  if type(patterns) == 'string' then
    return vim.fn.match(str, patterns) ~= -1
  else
    for _, v in ipairs(patterns) do
      if vim.fn.match(str, v) > -1 then
        return true
      end
    end

    return false
  end
end

local manillua = {}

--- Fold Expression Function
-- Handles all of the folding logic.
--
-- TODO: Would like to move to using some lua library for this, rather than vim regexp
-- TODO: Make it possible to turn off / on docstring folding into next funcion, not folded, etc.
function manillua.foldexpr(line_num)
  if line_num == nil then
    line_num = vim.fn.nvim_get_vvar('lnum')
  end

  if line_num == 1 then
    return l.start(1)
  end

  local line = vim.fn.getline(line_num)
  local next_line = vim.fn.getline(line_num + 1)

  if line == '' then
    return l.same
  end

  if matches(line, patterns.end_only) then
    if next_line == '' then
      return l.same
    end

    return l.subtract(1)
  end

  if matches(line, patterns.function_start) then
    return l.start(1)
  end

  if matches(line, patterns.object_start) then
    return l.start(1)
  end

  if matches(line, patterns.object_property_start) then
    return l.start(2)
  end

  if matches(line, patterns.docstring_start) then
    return l.start(2)
  end

  if matches(line, patterns.comment_start) then
    if matches(next_line, patterns.object_property_start) then
      return l.subtract(1)
    else
      return l.same
    end
  end

  if matches(line, patterns.module_return) then
    return l.start(1)
  end

  -- TODO: "spec" files
  _ = [[
  " Old vimscript code
  if s:matches(line, s:test_start)
    return ">1"
  endif
  if s:matches(line, s:nested_test_start)
    return "a1"
  endif

  if s:matches(line, s:test_case_start)
    return "a1"
  endif

  if s:matches(line, '^\s*end)$')
    return "s1"
  endif

  if s:matches(line, '^\s*before_each')
    return "a1"
  endif
  ]]

  return l.same
end

--- Fold text
-- blah
function manillua.foldtext(line_start, line_end, fold_level)
  if line_start == nil then
    line_start = vim.fn.nvim_get_vvar('foldstart')
  end

  if line_end == nil then
    line_end = vim.fn.nvim_get_vvar('foldend')
  end

  if fold_level == nil then
    fold_level = vim.fn.nvim_get_vvar('foldlevel')
  end

  local start_line = vim.fn.getline(line_start)

  if fold_level == 1 and matches(start_line, patterns.object_start) then
    return string.format('Object: %s', vim.split(start_line, ' ')[2])
  end

  if fold_level >= 1 and matches(start_line, patterns.object_property_start) then
    local object_props = manillua._get_object_property_attributes(start_line)

    -- TODO: Add back in the args, but I don't really like them usually.
    --  object_props.args
    return string.format(
      '―→ %7s %-8s %s%s%-25s',
      object_props.prefix,
      object_props.scope,
      object_props.object,
      object_props.separator,
      object_props.name
    )
  end

  return vim.fn.getline(line_start)
end

function manillua._get_object_property_attributes(text)
  local object, name, args
  if matches(text, '^function') then
    local temp = vim.fn.matchlist(text, [[^function \(.*\)(]])
    local intermediate = vim.split(temp[2], '.', true)
    object = intermediate[1]
    name = intermediate[2]

    args = '...'
  else
    return 'that way'
  end

  local prefix = ''
  local scope
  if str_util.startswith(name, '_') then
    scope = 'private'
  else
    scope = 'public'
  end


  local separator = '.'

  return {
    prefix=prefix,
    scope=scope,
    object=object,
    separator=separator,
    name=name,
    args=args
  }
end

return manillua

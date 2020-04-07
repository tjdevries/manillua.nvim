return {
  startswith = function(str, prefix)
    return string.sub(str, 1, #prefix) == prefix
  end
}

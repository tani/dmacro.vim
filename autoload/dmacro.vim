vim9script

export def GuessMacro1(keys: list<string>): list<string>
  # keys = { 'd', 'c', 'b', 'a', 'c', 'b', 'a' }, len(keys) = 7
  # (1) i = 3
  for i in range(len(keys) / 2, len(keys) - 1)
    # span1 = [ 'c', 'b', 'a' ]
    var span1 = keys[i + 1 : len(keys) - 1]
    # span2 = [ 'c', 'b', 'a' ]
    var span2 = keys[i + 1 - len(span1) : i]
    if (span1 == span2)
      return span1
    endif
  endfor
  return []
enddef

export def GuessMacro2(keys: list<string>): list<string>
  # keys = { 'd', 'c', 'b', 'a', 'c', 'b' }, len(keys) = 6
  # i = 3
  # i = 4
  for i in range(len(keys) / 2, len(keys))
    # span1 = [ 'a', 'c', 'b' ]
    # span1 = [ 'c', 'b' ]
    var span = keys[i : len(keys) - 1]
    # j = i = 3 = 3
    # j = i = 4 > 2
    # j = i = 3 > 2
    for j in range(i, len(span), -1)
      #prevspan = [ 'd', 'c' 'b' ]
      #prevspan = [ 'b', 'a' ]
      #prevspan = [ 'c', 'b' ]
      var prevspan = keys[j - len(span) : j - 1]
      if (prevspan == span)
        return keys[j : i - 1]
      endif
    endfor
  endfor
  return []
enddef

export def SetState(keys: list<string>, macro: list<string>): void
  b:dmacro_keys = keys
  b:dmacro_macro = macro
enddef

export def GetState(): list<list<string>>
  return [get(b:, 'dmacro_keys', []), get(b:, 'dmacro_macro', [])]
enddef

export def PlayMacro(): void
  var [keys, macro] = GetState()
  if !empty(keys)
    keys = keys[0 : len(keys) - 2]
    macro = empty(macro) ?  GuessMacro1(keys) : macro
    if !empty(macro)
      feedkeys(join(macro, ''))
      SetState(extend(copy(keys), copy(macro)), macro)
      return
    endif
    macro = empty(macro) ? GuessMacro2(keys) : macro
    if !empty(macro)
      feedkeys(join(macro, ''))
      SetState(extend(copy(keys), copy(macro)), [])
      return
    endif
    SetState(keys, macro)
  endif
enddef

export def RecordMacro(typed: string): void
  if !empty(typed)
    var [keys, macro] = GetState()
    if !empty(keys) && !empty(macro) && len(keys) >= len(macro)
      for i in range(0, len(macro) - 1)
        var j = len(keys) - 1 - i
        var k = len(macro) - 1 - i
        if (keys[j] != macro[k])
          keys = []
          macro = []
          break
        endif
      endfor
    endif
    SetState(extend(copy(keys), [ typed ]), macro)
  endif
enddef

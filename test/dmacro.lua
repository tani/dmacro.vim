local dmacro = require('./lua/dmacro')

function test(name, func)
  print('Test: ' .. name .. ' started')
  func()
  print('Test: ' .. name .. ' passed')
end

test('guess_macro_1', function()
  local keys = { 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  local expected = {'a', 'b', 'c'}
  local actual = dmacro.guess_macro_1(keys)
  assert(vim.deep_equal(expected, actual))
end)

test('guess_macro_2', function()
  local keys = { 'b', 'c', 'a', 'b', 'c', 'd' }
  local expected = { 'a' }
  local actual = dmacro.guess_macro_2(keys)
  assert(vim.deep_equal(expected, actual))
end)

test('get_and_set_state', function()
  local keys = { 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  local macro = { 'a' }
  local expected_keys = keys
  local expected_macro = macro
  dmacro.set_state(keys, macro)
  local actual_keys, actual_macro = dmacro.get_state()
  assert(vim.deep_equal(expected_keys, actual_keys))
  assert(vim.deep_equal(expected_macro, actual_macro))
end)

test('create_macro_recoder', function()
  local dmacro_key = '<C-t>'
  local recorder = dmacro.create_macro_recorder(dmacro_key)
  local keys = { 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  local macro = { 'a' }
  dmacro.set_state(keys, macro)
  recorder(_, 'a')
  local actual_keys, actual_macro = dmacro.get_state()
  local expected_keys = {}
  local expected_macro = nil
  assert(vim.deep_equal(expected_keys, actual_keys))
  assert(vim.deep_equal(expected_macro, actual_macro))
  keys = { 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  macro = nil
  dmacro.set_state(keys, macro)
  recorder(_, 'a')
  actual_keys, actual_macro = dmacro.get_state()
  expected_keys = { 'a', 'a', 'b', 'c', 'a', 'b', 'c', 'd' }
  expected_macro = nil
  assert(vim.deep_equal(expected_keys, actual_keys))
  assert(vim.deep_equal(expected_macro, actual_macro))
end)

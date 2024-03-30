local this_group = vim.api.nvim_create_augroup('dmacro', {})
local this_namespace = vim.api.nvim_create_namespace('dmacro')

local function drop(tbl, start)
    local ret = {}
    for i = start, #tbl - 1 do
        table.insert(ret, tbl[i])
    end
    return ret
end

local function take(tbl, _end)
    local ret = {}
    for i = 0, _end do
        table.insert(ret, tbl[i])
    end
    return ret
end

local function merge(a, b)
    local ret = {}
    for _, e in ipairs(a) do
        table.insert(ret, e)
    end
    for _, e in ipairs(b) do
        table.insert(ret, e)
    end
    return ret
end

local function equal(a, b)
    if #a == #b then
        for i = 0, #a - 1 do
            if a[i] ~= b[i] then
                return false
            end
        end
        return true
    end
    return false
end

local function repeat_dmacro()
    local hist = { unpack(vim.fn.slice(vim.fn.reverse(vim.b.dmacro_history), 1)) }
    for i = 0, (#hist / 2) do
       vim.print({take(hist, i * 2), merge(take(hist, i), take(hist, i)) })
       if equal(take(hist, i * 2), merge(take(hist, i), take(hist, i))) then
            vim.print(take(hist, i * 2))
       end
    end
end

local function init_dmacro()
    vim.b.dmacro_history = {}
    vim.on_key(function(key, typed)
        if typed ~= "" and typed ~= nil then
            vim.b.dmacro_history = vim.fn.add(vim.b.dmacro_history, typed)
        end
    end, this_namespace)
    vim.keymap.set({"i"}, "<leader>t", repeat_dmacro, { buffer = true })
    print("dmacro is initialized")
end

vim.api.nvim_create_autocmd('BufWinEnter', {
    group = this_group,
    callback = init_dmacro
})
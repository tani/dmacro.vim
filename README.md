# dmacro.nvim

> [!CAUTION]
> You need to use neovim **0.10.0** or later.

Text editors have evolved to support input in different ways.

- Word completion based on dictionary data (e.g. CTRL-X completion in Vim)
- Code fragment completion based on dictionary data (e.g. Snippet Completion)
- Contextual, rule-based word completion (e.g. Language Server Protocol)
- Completion of larger code fragments using generative AI (GitHub Copilot)

All of these were hailed as revolutionary when they first appeared.
What's the next big assistive feature? I say **operation completion**.
Currently, completion is for new code. But most coding isn't new creation.
It's overwriting, like editing or updating. Shouldn't this be supported?

## Related works

- [dmacro.el](https://github.com/emacs-jp/dmacro)
- [Dynamic Macro for Visual Studio Code](https://github.com/tshino/vscode-dynamic-macro)

## Example

[dmacro.webm](https://github.com/tani/dmacro.nvim/assets/5019902/7190245b-3c48-4170-bd41-6df781f21feb)

This plugin dynamically defines a macro.
**You do not need to make any markers for the macro.**
To define a macro, this plugin detects the reputation as follows:

- If you enter the same key sequence twice (e.g. `abcabc`), this plugin will define a macro with the key sequence (e.g. `abc`).
  ```mermaid
  graph LR
    start(( )) --> a1((a))
    subgraph 1st
    a1 --> b1((b))
    b1 --> c1((c))
    end
    subgraph 2nd
    c1 --> a2((a))
    a2 --> b2((b))
    b2 --> c2((c))
    end
    subgraph 3rd
    c2 --> dmacro(dmacro)
    dmacro -.- a3((a))
    subgraph MacroExecution
    a3 -.- b3((b))
    b3 -.- c3((c))
    end
    end
    c3 --> quit(( ))
  ```
  

- If you type the subsequence (e.g. `a`) of the previous key sequence (e.g. `abc`), this plugin will define a macro with the rest of the previous sequence (e.g. `bc`). After expanding the macro, the whole sequence (e.g. `abc`) will be the macro.
  ```mermaid
  graph LR
    start(( )) --> a1((a))
    subgraph 1st
    a1 --> b1((b))
    b1 --> c1((c))
    end
    subgraph 2nd
    c1 --> a2((a))
    a2 --> dmacro1(dmacro)
    dmacro1 -.- b2((b))
    subgraph MacroExecution_1
    b2 -.- c2((c))
    end
    end
    subgraph 3rd
    c2 --> dmacro2(dmacro)
    dmacro2 -.- a3((a))
    subgraph MacroExecution_2
    a3 -.- b3((b))
    b3 -.- c3((c))
    end
    end
    c3 --> quit(( ))
  ```

## Usage

You need to call `dmacro.setup()` at the very early phase;
e.g., `VimEnter` or `BufEnter` event to start key logging.

```lua
require('dmacro').setup({
    dmacro_key = '<C-t>' --  you need to set the dmacro_key
})
```

Or, you can intensively use `dmacro.setup()` in the `CursorHold` event.

```lua
vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
        require('dmacro').setup()
    end,
    once = true
})
vim.keymap.set({ "i", "n" }, '<C-t>', function() require('dmacro').play_macro() end)
-- vim.keymap.set({ "i", "n" }, '<C-t>', "<Plug>(dmacro-play-macro)")
-- vim.keymap.set({ "i", "n" }, '<C-t>', "<Cmd>lua require('dmacro').play_macro()<CR>")
```

## Licence

This software is released under the MIT licence.

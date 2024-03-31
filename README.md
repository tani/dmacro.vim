# dmacro.nvim

> [!CAUTION]
> You need to use the nightly build of neovim (3-31-2024 or later).<br>
> <s>This plugin depends on the pull request https://github.com/neovim/neovim/pull/28098 .
> You need to build neovim, which is available at https://github.com/zeertzjq/neovim/tree/on-key-typed . </s>

## Related works

- [dmacro.el](https://github.com/emacs-jp/dmacro)
- Dynamic Macro for Visual Studio Code](https://github.com/tshino/vscode-dynamic-macro)

## Example

This plugin dynamically defines a macro.
**You do not need to make any markers for the macro.
To define a macro, this plugin detects the reputation as follows:

- If you enter the same key sequence twice (e.g. `abcabc`), this plugin will define a macro with the key sequence (e.g. `abc`).
  ```
  abcabc -(dmacro)-> abcabcabc -(dmacro)-> abcabcabcabc -> ...
  ```

- If you type the subsequence (e.g. `ab`) of the previous key sequence (e.g. `abc_`), this plugin will define a macro with the rest of the previous sequence (e.g. `c_`). After expanding the macro, the whole sequence (e.g. `abc_`) will be the macro.
  ```
  abc_ab -(dmacro)-> abc_abc_ -(dmacro)-> abc_abc_abc_ -> ...
  ```

## Usage

Before loading buffers, call the `setup()` function.

```lua
require('dmacro').setup()
```

You can specify a `dmacro_key` option

```lua
require('dmacro').setup({
    dmacro_key = '<leader>.' -- this is a default
})
```

## Licence

This software is released under the MIT licence.

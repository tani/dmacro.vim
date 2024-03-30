# dmacro.nvim

> [!CAUTION]
> This plugin is depends on the pull requiest https://github.com/neovim/neovim/pull/28098 .
> You need to build neovim that is available at https://github.com/zeertzjq/neovim/tree/on-key-typed .

## Related works

- [dmacro.el](https://github.com/emacs-jp/dmacro)
- [Dynamic Macro for Visual Studio Code](https://github.com/tshino/vscode-dynamic-macro)

## Example

This plugin defines a macro dynamically.
**You do not need to make marks for the macro.**
To define a macro, this plugin detect the reputation as follows:

- If you type the same key sequence twice (e.g., `abcabc`), then this plugin defines a macro with the key sequence (e.g., `abc`).
  ```
  abcabc -(dmacro)-> abcabcabc -(dmacro)-> abcabcabcabc -> ...
  ```

- If you type the sub-sequence (e.g., `ab`) of the previous key sequence (e.g., `abc_`), then this plugin defiens a macro with the rest of the previous sequence (e.g., `c_`). After the macro expansion, the whole sequence (e.g., `abc_`) will be the macro.
  ```
  abc_ab -(dmacro)-> abc_abc_ -(dmacro)-> abc_abc_abc_ -> ...
  ```

## Usage

Before loading buffers, please call `setup()` function.

```lua
require('dmacro').setup()
```

You can give an option `dmacro_key`

```lua
require('dmacro').setup({
    dmacro_key = '<leader>.' -- this is a default value
})
```

## License

This software is licensed under the MIT License.

## Copyright

(C) 2024, TANIGUCHI Masaya


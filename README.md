# trzsz.nvim

A Neovim plugin that provides seamless file transfer integration with [trzsz](https://github.com/trzsz/trzsz) through terminal windows in a vertical split.

## Commands

- `:Trz` receive files in a transfer terminal.
- `:Tsz {filename}` send a file with `tsz` in a transfer terminal.

## Install

### Via lazy.nvim

```lua
return {
  {
    "gitsang/trzsz.nvim",
    opts = {
      trz_cmd = "trz",
      tsz_cmd = "tsz -y",
    },
    cmd = { "Trz", "Tsz" },
    keys = {
      { "<leader>tu", "<cmd>Trz<cr>", desc = "Upload files with trz" },
      { "<leader>td", "<cmd>Tsz<cr>", desc = "Download files with trz" },
    },
  },
}
```

# trzsz.nvim

A Neovim plugin that provides seamless file transfer integration with [trzsz](https://github.com/trzsz/trzsz) through floating terminal windows.

## Features

- **`:Trz`** - Upload files using `trz` in a floating terminal window and automatically insert uploaded filenames at the cursor position
- **`:Tsz`** - Download files using `tsz` in a floating terminal window
- Floating terminal windows with proper sizing and borders
- Automatic filename extraction and insertion for uploaded files
- Configurable commands and options

## 1. Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'gitsang/trzsz.nvim',
  opts = {
    width = 80,                           -- Width of the floating window (percentage of screen width)
    trz_cmd = "trz | tee /tmp/trz.log",  -- Command for uploading files
    tsz_cmd = "tsz",                      -- Command for downloading files  
    temp_log = "/tmp/trz.log"             -- Temporary log file for trz output
  },
  cmd = { "Trz", "Tsz" },
  keys = {
    { "<leader>tu", "<cmd>Trz<cr>", desc = "Upload files with trz" },
    { "<leader>td", "<cmd>Tsz ", desc = "Download files with tsz" },
  },
}
```

## 2. Usage

### 2.1 Upload Files (`:Trz`)

Run `:Trz` to open a floating terminal window running the `trz` command:

1. Execute `:Trz` or press `<leader>tu`
2. A floating terminal window appears running `trz`
3. Use your trzsz client to upload files
4. After the upload completes, the filenames are automatically extracted and inserted at your cursor position

Example workflow:
```sh
# In the floating terminal:
$ trz | tee /tmp/trz.log
::TRZSZGO:TRANSFER:R:1.1.8:6587171919300:45405
Saved 1 file/directory to /tmp
- secure-login-server-flow.png
```

The plugin automatically extracts `secure-login-server-flow.png` and inserts it at the cursor position.

### 2.2 Download Files (`:Tsz`)

Run `:Tsz <file1> [file2] ...` to download files using `tsz`:

```vim
:Tsz README.md
:Tsz file1.txt file2.txt document.pdf
```

Or use the key mapping:
```vim
<leader>td README.md
```

### 2.3 Configuration

The plugin can be configured with the following options:

- `width`: Integer for the floating window width percentage (default: 80)
- `trz_cmd`: String for the upload command (default: "trz | tee /tmp/trz.log")
- `tsz_cmd`: String for the download command (default: "tsz")  
- `temp_log`: String for the temporary log file path (default: "/tmp/trz.log")

Example configuration:
```lua
require('trzsz').setup({
  width = 90,
  trz_cmd = "trz | tee /tmp/my-trz.log",
  tsz_cmd = "tsz --parallel 4",
  temp_log = "/tmp/my-trz.log"
})
```

## 3. Requirements

- [trzsz](https://github.com/trzsz/trzsz) installed and available in your PATH
- Neovim 0.7.0 or higher

## 4. License

MIT License - see [LICENSE](./LICENSE) file for details.
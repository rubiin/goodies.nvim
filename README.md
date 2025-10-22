<!-- LTeX: enabled=false -->
# goodies.nvim
<!-- LTeX: enabled=true -->
<!-- TODO uncomment shields when available in dotfyle.com
<a href="https://dotfyle.com/plugins/rubiin/goodies.nvim">
<img alt="badge" src="https://dotfyle.com/plugins/rubiin/goodies.nvim/shield"/></a>
-->



> **Tiny, tasty, and too useful to leave in your config.**
> A small collection of Lua utilities and commands for Neovim — not big enough for their own plugin, but too handy to ignore.

---

## ✨ Overview

This plugin bundles several lightweight but practical functions that improve everyday Neovim usage.
Each function is **self-contained**, designed to be mapped to a keybinding, and focuses on **quality-of-life** enhancements — things that make editing faster, cleaner, or more delightful.

Originally written by [**Rubin Bhandari**](https://github.com/rubiin).

---

## 🧠 Why?

Your Neovim config can easily get cluttered with one-off helpers, commands, or scripts.
`goodies.nvim` is the middle ground — a comfy home for those neat ideas that *don’t quite deserve* their own repository.

---

## ⚙️ Features

### 🧾 Comment Utilities

* **`M.comment_hr()`**
  Inserts a horizontal “commented” line that matches the file’s comment syntax and indentation.
  Great for visually separating sections in your code or notes.

### 🚀 Code Execution

* **`M.code_runner()`**
  Detects the filetype and runs it using the appropriate command (e.g. `python %`, `gcc %`, `node %`, etc.).
  Prompts you to choose between multiple run modes (e.g., `default`, `debug`, `competitive`).

* **`M.run_file(ht)`**
  Quick command to compile or execute the current file in a terminal split (horizontal or vertical).
  Example: runs `cargo run` for Rust, `python %` for Python, or `make` for C/C++.

### 🌐 URL Helpers

* **`M.open_url()`**
  Opens the URL under the cursor in your system’s default browser.
  Works with common formats like `https://example.com`.

* **`M.open_in_browser(url)`**
  Utility function to open a specific URL using `xdg-open`, `explorer`, `open`, or `wslview`.

* **`M.open_at_regex_101()`**
  Detects and extracts regex patterns in supported languages and opens them in **[regex101.com](https://regex101.com/)** prefilled for quick testing.

### 🧑‍💻 Author Metadata

* **`M.add_author_details()`**
  Inserts a standard comment header at the top of the file, including:

  * Author name
  * Email
  * GitHub
  * Twitter
  * Date (auto-generated)

  Example:

  ```lua
  require("goodies").add_author_details()
  ```

  Produces:

  ```lua
  -- Author: Rubin Bhandari <roobin.bhandari@gmail.com>
  -- Date: 2024-05-23
  -- GitHub: https://github.com/rubiin
  -- Twitter: https://twitter.com/RubinCodes
  ```

---

### Misc
* **`M.word_count()`**
Utility function to count the number of words in the current buffer or visual selection.


## 🔑 Suggested Keymaps

Add something like this to your `init.lua` or `keymaps.lua`:

```lua
local goodies = require("goodies")

vim.keymap.set("n", "<leader>ch", goodies.comment_hr, { desc = "Insert comment HR" })
vim.keymap.set("n", "<leader>ru", goodies.code_runner, { desc = "Run current file" })
vim.keymap.set("n", "gx", goodies.open_url, { desc = "Open URL under cursor" })
vim.keymap.set("n", "<leader>yy",goodies.add_author_details, { desc = "Add author details" })
```

---

## 🧩 Installation

With **lazy.nvim**:

```lua
{
  "rubiin/goodies.nvim",
  opts = {
	author = {
		name = "John Doe",
		email = "john.doe@example.com",
		github = "johndoe",
		twitter = "DoeTweets",
	}
  }
}
```


---

## 🧃 Supported Filetypes (for Code Runner)

* `c`, `cpp`, `cs`, `go`, `java`, `js`, `ts`, `py`, `rs`, `php`, `r`, `jl`, `rb`, `pl`, `html`

Each filetype can have multiple run modes like `default`, `debug`, or `competitive`.

---

## 💡 Notes

* All commands are written in **pure Lua**, no dependencies.
* Every function is safe to keymap directly.
* Designed to stay fast and clean — no global state, no side effects.

---

## 🧑‍💻 Author

**Rubin Bhandari**

* 💌 [roobin.bhandari@gmail.com](mailto:roobin.bhandari@gmail.com)
* 🐙 [GitHub: @rubiin](https://github.com/rubiin)
* 🐦 [Twitter: @RubinCodes](https://twitter.com/RubinCodes)

---

## 🪄 License

MIT © Rubin Bhandari

-- %s Author: Rubin Bhandari <roobin.bhandari@gmail.com>
-- %s Date: 2024-05-23
-- %s GitHub: https://github.com/rubiin
-- %s Twitter: https://twitter.com/RubinCodes

-- These are several commands that are too small to be created as standalone plugins,
-- but too large to be included directly in the main configuration file, where they
-- might clutter the actual configuration. Each function is self-contained, apart from
-- the helper functions included here, and should be assigned to a keymap for easy access.

local M = {}
local fn, cmd = vim.fn, vim.cmd

-- Checks if a list contains a value.
---@param list table
---@param val any
---@return boolean
local function list_contains(list, val)
	for i = 1, #list do
		if list[i] == val then return true end
	end
	return false
end

local function get_comment_str()
	if vim.bo.commentstring == "" then
		vim.notify("No commentstring for " .. vim.bo.ft, vim.log.levels.WARN, { title = "Comment" })
		return
	end
	return vim.bo.commentstring
end

-- appends a horizontal line, with the language's comment syntax,
-- correctly indented and padded
function M.comment_hr()
	local comment_str = get_comment_str()
	if not comment_str then return end
	local startLn = vim.api.nvim_win_get_cursor(0)[1]

	-- determine indent
	local ln = startLn
	local line, indent
	repeat
		line = vim.api.nvim_buf_get_lines(0, ln - 1, ln, true)[1]
		indent = line:match("^%s*")
		ln = ln - 1
	until line ~= "" or ln == 0

	local indent_length = vim.bo.expandtab and #indent or #indent * vim.bo.tabstop
	local com_str_length = #(comment_str:format(""))
	local text_width = vim.o.textwidth > 0 and vim.o.textwidth or 80
	local hr_length = text_width - (indent_length + com_str_length)

	-- construct hr
	local hr_char = comment_str:find("%-") and "-" or "─"
	local hr = hr_char:rep(hr_length)
	local hr_with_omment = comment_str:format(hr)

	-- filetype-specific padding
	local formatter_want_padding = { "python", "css", "scss" }
	if not vim.tbl_contains(formatter_want_padding, vim.bo.ft) then
		hr_with_omment = hr_with_omment:gsub(" ", hr_char)
	end
	local fullLine = indent .. hr_with_omment

	-- append lines & move
	vim.api.nvim_buf_set_lines(0, startLn, startLn, true, { fullLine, "" })
	vim.api.nvim_win_set_cursor(0, { startLn + 1, #indent })
end

function M.simple_substitute(cmd)
	cmd = cmd:gsub("%%", vim.fn.expand("%"))
	cmd = cmd:gsub("$fileBase", vim.fn.expand("%:r"))
	cmd = cmd:gsub("$filePath", vim.fn.expand("%:p"))
	cmd = cmd:gsub("$file", vim.fn.expand("%"))
	cmd = cmd:gsub("$dir", vim.fn.expand("%:p:h"))
	cmd = cmd:gsub("#", vim.fn.expand("#"))
	cmd = cmd:gsub("$altFile", vim.fn.expand("#"))

	return cmd
end

function M.code_runner()
	local file_extension = vim.fn.expand("%:e")
	local selected_cmd = ""
	local term_cmd = "vsplit term://"
	local supported_filetypes = {
		html = {
			default = "%",
		},
		c = {
			default = "gcc % -o $fileBase && $fileBase",
			debug = "gcc -g % -o $fileBase && $fileBase",
		},
		cs = {
			default = "dotnet run",
		},
		cpp = {
			default = "g++ % -o  $fileBase && $fileBase",
			debug = "g++ -g % -o  $fileBase",
			-- competitive = "g++ -std=c++17 -Wall -DAL -O2 % -o $fileBase && $fileBase<input.txt",
			competitive = "g++ -std=c++17 -Wall -DAL -O2 % -o $fileBase && $fileBase",
		},
		py = {
			default = "python %",
		},
		go = {
			default = "go run %",
		},
		java = {
			default = "java %",
		},
		js = {
			default = "node %",
			debug = "node --inspect %",
		},
		ts = {
			default = "tsc % && node $fileBase",
		},
		rs = {
			default = "rustc % && $fileBase",
		},
		php = {
			default = "php %",
		},
		r = {
			default = "Rscript %",
		},
		jl = {
			default = "julia %",
		},
		rb = {
			default = "ruby %",
		},
		pl = {
			default = "perl %",
		},
	}

	if supported_filetypes[file_extension] then
		local choices = vim.tbl_keys(supported_filetypes[file_extension])

		if #choices == 0 then
			vim.notify(
				"It doesn't contain any command",
				vim.log.levels.WARN,
				{ title = "Code Runner" }
			)
		elseif #choices == 1 then
			selected_cmd = supported_filetypes[file_extension][choices[1]]
			vim.cmd(term_cmd .. substitute(selected_cmd))
		else
			vim.ui.select(choices, { prompt = "Choose a command: " }, function(choice)
				selected_cmd = supported_filetypes[file_extension][choice]
				if selected_cmd then vim.cmd(term_cmd .. substitute(selected_cmd)) end
			end)
		end
	else
		vim.notify(
			"The filetype isn't included in the list",
			vim.log.levels.WARN,
			{ title = "Code Runner" }
		)
	end
end

--> Run the current file according to filetype
---@param ht? number for height or "v" for vertical
function M.run_file(ht)
	local fts = {
		rust = "cargo run",
		python = "python %",
		javascript = "npm start",
		c = "make",
		cpp = "make",
		java = "java %",
	}

	local cmd = fts[vim.bo.ft]
	vim.cmd(
		cmd and ("w | " .. (ht or "") .. "sp | term " .. cmd) or "echo 'No command for this filetype'"
	)
end

-- Opens the given url in the default browser.
---@param url string: The url to open.
function M.open_in_browser(url)
	local executables = { "xdg-open", "explorer", "open", "wslview" }
	local open_cmd = ""

	for _, value in ipairs(executables) do
		if fn.executable(value) == 1 then
			open_cmd = value
			break
		end
	end

	if open_cmd == "" then
		vim.notify("No browser found to open the URL", vim.log.levels.ERROR, "Utils")
		return
	end

	local ret = fn.jobstart({ open_cmd, url }, { detach = true })
	if ret <= 0 then
		vim.notify(
			string.format("Failed to open '%s'\nwith command: '%s' (ret: '%d')", url, open_cmd, ret),
			vim.log.levels.ERROR,
			"Utils"
		)
	end
end

-- Open URL under cursor, supports the following formats:
-- - http://google.com
-- - https://google.com
-- - https://www.google.com
-- - http://www.google.com
function M.open_url()
	-- Get the text under the cursor
	local url = fn.expand("<cWORD>")
	-- Check if it resembles a URL
	local matched_url = url:match("^https?://[%w_-]+%.%w+")

	if matched_url then
		vim.notify("🌐 Opening URL: " .. matched_url)
		M.open_in_browser(matched_url)
	else
		vim.notify("💁 Woops, no URL found under the cursor")
	end
end

--- Open the next regex at https://regex101.com/
function M.open_at_regex_101()
	local lang = vim.bo.filetype
	local text, pattern, replace, flags

	local supported_filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"python",
	}

	if not list_contains(supported_filetypes, lang) then
		vim.notify("Unsupported filetype.", vim.log.levels.ERROR, "Utils")
	end

	if list_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, lang) then
		cmd.TSTextobjectSelect("@regex.outer")
		normal('"zy')
		cmd.TSTextobjectSelect("@regex.inner") -- reselect for easier pasting
		text = vim.fn.getreg("z")
		pattern = text:match("/(.*)/")
		flags = text:match("/.*/(%l*)") or "gm"
		replace = vim.api.nvim_get_current_line():match('replace ?%(/.*/.*, ?"(.-)"')
	elseif lang == "python" then
		normal('"zyi"vi"') -- yank & reselect inside quotes
		pattern = fn.getreg("z")
		local flagInLine = vim.api.nvim_get_current_line():match("re%.([MIDSUA])")
		flags = flagInLine and "g" .. flagInLine:gsub("D", "S"):lower() or "g"
	end

	-- `+` is the only character regex101 does not escape on its own. But for it
	-- to work, `\` needs to be escaped as well (SIC)
	pattern = pattern:gsub("%+", "%%2B"):gsub("\\", "%%5C")

	-- DOCS https://github.com/firasdib/Regex101/wiki/FAQ#how-to-prefill-the-fields-on-the-interface-via-url
	local url = ("https://regex101.com/?regex=%s&flags=%s&flavor=%s%s"):format(
		pattern,
		flags,
		lang,
		(replace and "&subst=" .. replace or "")
	)
	M.open_in_browser(url)
end


local M = {}

function M.cowboy()
  ---@type table?
  local id
  local ok = true
  for _, key in ipairs({ "h", "j", "k", "l", "+", "-" }) do
    local count = 0
    local timer = assert(vim.loop.new_timer())
    local map = key
    vim.keymap.set("n", key, function()
      if vim.v.count > 0 then
        count = 0
      end
      if count >= 10 then
        ok, id = pcall(vim.notify, "Hold it Cowboy!", vim.log.levels.WARN, {
          icon = "🤠",
          replace = id,
          keep = function()
            return count >= 10
          end,
        })
        if not ok then
          id = nil
          return map
        end
      else
        count = count + 1
        timer:start(2000, 0, function()
          count = 0
        end)
        return map
      end
    end, { expr = true, silent = true })
  end
end


return M

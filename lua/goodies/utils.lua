-- %s Author: Rubin Bhandari <roobin.bhandari@gmail.com>
-- %s Date: 2024-05-23
-- %s GitHub: https://github.com/rubiin
-- %s Twitter: https://twitter.com/RubinCodes

-- These are several commands that are too small to be created as standalone plugins,
-- but too large to be included directly in the main configuration file, where they
-- might clutter the actual configuration. Each function is self-contained, apart from
-- the helper functions included here, and should be assigned to a keymap for easy access.

local M = {}

local fn = vim.fn
local api = vim.api
local cmd = vim.cmd
local uv = vim.uv or vim.loop

local config = require("goodies.config")

-- Count words in a given list of lines
local function count_words(lines)
	local count = 0
	for _, line in ipairs(lines) do
		for _ in string.gmatch(line, "%S+") do
			count = count + 1
		end
	end
	return count
end

-- Counts the words in a buffer
---@return number
function M.word_count()
	local mode = fn.mode()
	local lines

	if mode == "v" or mode == "V" or mode == "\22" then
		-- Visual mode: get selected lines
		local start_pos = fn.getpos("'<")
		local end_pos = fn.getpos("'>")
		local start_line = start_pos[2] - 1 -- Lua index starts at 0
		local end_line = end_pos[2]
		lines = api.nvim_buf_get_lines(0, start_line, end_line, false)
	else
		-- Normal mode: use the whole buffer
		lines = api.nvim_buf_get_lines(0, 0, -1, false)
	end

	return count_words(lines)
end

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
	local startLn = api.nvim_win_get_cursor(0)[1]

	-- determine indent
	local ln = startLn
	local line, indent
	repeat
		line = api.nvim_buf_get_lines(0, ln - 1, ln, true)[1]
		indent = line:match("^%s*")
		ln = ln - 1
	until line ~= "" or ln == 0

	local bo = vim.bo
	local indent_length = bo.expandtab and #indent or #indent * bo.tabstop
	local com_str_length = #(comment_str:format(""))
	local text_width = vim.o.textwidth > 0 and vim.o.textwidth or 80
	local hr_length = text_width - (indent_length + com_str_length)

	-- construct hr
	local hr_char = comment_str:find("%-") and "-" or "─"
	local hr = hr_char:rep(hr_length)
	local hr_with_omment = comment_str:format(hr)

	-- filetype-specific padding
	local formatter_want_padding = { "python", "css", "scss" }
	if not vim.tbl_contains(formatter_want_padding, bo.filetype) then
		hr_with_omment = hr_with_omment:gsub(" ", hr_char)
	end
	local fullLine = indent .. hr_with_omment

	-- append lines & move
	api.nvim_buf_set_lines(0, startLn, startLn, true, { fullLine, "" })
	api.nvim_win_set_cursor(0, { startLn + 1, #indent })
end

function M.simple_substitute(command)
	command = command:gsub("%%", fn.expand("%"))
	command = command:gsub("$fileBase", fn.expand("%:r"))
	command = command:gsub("$filePath", fn.expand("%:p"))
	command = command:gsub("$file", fn.expand("%"))
	command = command:gsub("$dir", fn.expand("%:p:h"))
	command = command:gsub("#", fn.expand("#"))
	command = command:gsub("$altFile", fn.expand("#"))

	return command
end

function M.code_runner()
	local file_extension = fn.expand("%:e")
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
			cmd(term_cmd .. M.simple_substitute(selected_cmd))
		else
			vim.ui.select(choices, { prompt = "Choose a command: " }, function(choice)
				selected_cmd = supported_filetypes[file_extension][choice]
				if selected_cmd then cmd(term_cmd .. M.simple_substitute(selected_cmd)) end
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
		text = fn.getreg("z")
		pattern = text:match("/(.*)/")
		flags = text:match("/.*/(%l*)") or "gm"
		replace = api.nvim_get_current_line():match('replace ?%(/.*/.*, ?"(.-)"%')
	elseif lang == "python" then
		normal('"zyi"vi"') -- yank & reselect inside quotes
		pattern = fn.getreg("z")
		local flagInLine = api.nvim_get_current_line():match("re%.([MIDSUA])")
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

function M.cowboy()
	---@type table?
	local id
	local ok = true
	for _, key in ipairs { "h", "j", "k", "l", "+", "-" } do
		local count = 0
		local timer = assert(uv.new_timer())
		local map = key
		vim.keymap.set("n", key, function()
			if vim.v.count > 0 then count = 0 end
			if count >= 10 then
				ok, id = pcall(vim.notify, "Hold it Cowboy!", vim.log.levels.WARN, {
					icon = "🤠",
					replace = id,
					keep = function() return count >= 10 end,
				})
				if not ok then
					id = nil
					return map
				end
			else
				count = count + 1
				timer:start(2000, 0, function() count = 0 end)
				return map
			end
		end, { expr = true, silent = true })
	end
end

-- Adds author details to files
function M.add_author_details()
	-- Define author details

	local details = config.config.author

	local author = {
		name = details.name or "",
		email = details.email or "",
		github = details.github or "",
		twitter = details.twitter or "",
	}

	local comment = get_comment_str() or ""

	-- replace %s in comment string with empty
	comment = string.format(comment, "")

	-- Format the comment with author details
	-- Get current buffer
	local comment_details = string.format(
		"%s Author: %s <%s>\n%s Date: %s\n%s GitHub: https://github.com/%s\n%s Twitter: https://twitter.com/%s\n",
		comment,
		author.name,
		author.email,
		comment,
		os.date("%Y-%m-%d"), -- Add the date here using os.date() function with appropriate format
		comment,
		author.github,
		comment,
		author.twitter
	)

	local bufnr = api.nvim_get_current_buf()
	-- Get existing buffer lines
	local existing_lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Split the replacement string into lines
	local replacement_lines = {}
	for line in comment_details:gmatch("[^\r\n]+") do
		replacement_lines[#replacement_lines + 1] = line
	end

	-- Insert the new lines at the beginning of the buffer
	api.nvim_buf_set_lines(bufnr, 0, 0, false, replacement_lines)

	-- Append the existing lines after the new lines
	api.nvim_buf_set_lines(bufnr, #replacement_lines, -1, false, existing_lines)

	vim.notify("✅ Added author details")
end

-- Automatically exit insert mode after a period of inactivity
function M.auto_normal()
	local ms = config.config.auto_normal.timeout or 3000 -- timeout in ms
	local timer = uv.new_timer()

	local function schedule_stop()
		timer:stop()
		timer:start(
			ms,
			0,
			vim.schedule_wrap(function()
				if api.nvim_get_mode().mode == "i" then cmd("stopinsert") end
			end)
		)
	end

	-- Run on every key press
	local ns = api.nvim_create_namespace("auto_normal")
	vim.on_key(schedule_stop, ns)
end

local LANGS = {
	python = "py",
}

local SHELLS = {
	sh = { "#! /usr/bin/env bash" },
	py = { "#! /usr/bin/env python3" },
	scala = { "#! /usr/bin/env scala" },
	tcl = { "#! /usr/bin/env tclsh" },
	lua = {
		"#! /bin/sh",
		"_=[[",
		'exec lua "$0" "$@"',
		"]]",
	},
}

-- Extracted logic into a separate function
function M.insert_hashbang()
	local extension = fn.expand("%:e")

	if extension == "" then extension = LANGS[vim.bo.filetype] or vim.bo.filetype end

	local hb = SHELLS[extension]
	if hb then
		hb[#hb + 1] = ""
		api.nvim_buf_set_lines(0, 0, 0, false, hb)

		api.nvim_create_autocmd("BufWritePost", {
			command = "silent !chmod u+x %",
			buffer = 0,
			once = true,
		})
	else
		vim.notify("No hashbang found for ." .. extension, vim.log.levels.WARN)
	end
end

function M.parse_env_file(filepath)
	-- Check if file exists
	local file = io.open(filepath, "r")
	if not file then return {} end

	local env = {}

	-- Read file line by line
	for line in file:lines() do
		-- Skip empty lines and comments
		if line:match("^%s*[^#]") then
			-- Remove leading/trailing whitespace
			line = line:match("^%s*(.-)%s*$")

			-- Remove optional "export" keyword
			line = line:gsub("^export%s+", "")

			-- Find the first equals sign
			local pos = line:find("=")

			if pos then
				local key = line:sub(1, pos - 1):match("^%s*(.-)%s*$")
				local value = line:sub(pos + 1):match("^%s*(.-)%s*$")

				-- Remove quotes if they exist
				if value:match('^".*"$') or value:match("^'.*'$") then value = value:sub(2, -2) end

				-- Store in environment table
				env[key] = value
			end
		end
	end

	file:close()
	return env
end

--- Insert `s` at end of current line without moving cursor. minimal repro of put_at_end plugin
--- @param s string the string to append
function M.append_to_eol(s)
	local bufnr = api.nvim_get_current_buf()
	local row = api.nvim_win_get_cursor(0)[1] -- 1‑based line number
	local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
	if not line then return end
	-- don't do anything if already ends with s
	if line:sub(-#s) == s then return end
	-- compute new line text
	local new_line = line .. s
	-- set line
	api.nvim_buf_set_lines(bufnr, row - 1, row, false, { new_line })
	-- Restore cursor position (same column)
	-- column = current column
	local col = api.nvim_win_get_cursor(0)[2]
	api.nvim_win_set_cursor(0, { row, col })
end

return M

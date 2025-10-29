local M = {}

-- Helpers
local function upper_first(str)
	return str:sub(1, 1):upper() .. str:sub(2)
end

local function lower_first(str)
	return str:sub(1, 1):lower() .. str:sub(2)
end

-- Convert snake_case → camelCase
local function snake_to_camel(str)
	return str:gsub("_%a", function(s) return s:sub(2, 2):upper() end)
end

-- Convert snake_case → PascalCase
local function snake_to_pascal(str)
	return upper_first(snake_to_camel(str))
end

-- Convert camelCase or PascalCase → snake_case
local function camel_to_snake(str)
	return str:gsub("(%u)", "_%1"):lower():gsub("^_", "")
end

-- Detect current case type
local function detect_case(str)
	if str:find("_") then
		return "snake"
	elseif str:sub(1, 1):match("%u") then
		return "pascal"
	else
		return "camel"
	end
end

-- Cycle case
function M.cycle_case(str)
	local case = detect_case(str)
	if case == "snake" then
		return snake_to_camel(str)
	elseif case == "camel" then
		return upper_first(str)
	else  -- pascal
		return camel_to_snake(str)
	end
end

-- Toggle current selection or word under cursor
function M.toggle_selection()
	local mode = vim.fn.mode()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos, end_pos

	if mode == "v" or mode == "V" or mode == "\22" then
		start_pos = vim.fn.getpos("'<")
		end_pos = vim.fn.getpos("'>")
	else
		-- Word under cursor
		local line = vim.fn.getline(".")
		local col = vim.fn.col(".")
		local s, e = line:find("%w+", col)
		if not s then return end
		start_pos = { 0, vim.fn.line("."), s, 0 }
		end_pos = { 0, vim.fn.line("."), e, 0 }
	end

	-- Get lines
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_pos[2] - 1, end_pos[2], false)

	if #lines == 1 then
		local line = lines[1]
		local s, e = start_pos[3] - 1, end_pos[3]
		local selected = line:sub(s + 1, e)
		local toggled = M.cycle_case(selected)
		lines[1] = line:sub(1, s) .. toggled .. line:sub(e + 1)
	else
		for i = 1, #lines do
			lines[i] = M.cycle_case(lines[i])
		end
	end

	vim.api.nvim_buf_set_lines(bufnr, start_pos[2] - 1, end_pos[2], false, lines)
end

return M

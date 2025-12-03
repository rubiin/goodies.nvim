local M = {}

local fn = vim.fn
local api = vim.api
local uv = vim.uv or vim.loop

local file_big_cache = {}

--- check if the buffer is big
---@param buffer any
---@param max_size? number
---@return boolean
M.is_file_big = function(buffer, max_size)
	if file_big_cache[buffer] ~= nil then return file_big_cache[buffer] end

	local max_bytes = max_size or (100 * 1024)
	local ok, stats = pcall(uv.fs_stat, api.nvim_buf_get_name(buffer))
	local big = ok and stats and stats.size > max_bytes
	file_big_cache[buffer] = big
	return big
end

-- Check if buffer is empty.
---@return boolean
function M.buffer_not_empty() return fn.empty(fn.expand("%:t")) ~= 1 end

--- Checks whether the buffer is valid.
-- Checks if buffer is valid and listed.
---@param buf_id buffer id to be checked.
---@return boolean
function M.is_valid_buffer(buf_id) return api.nvim_buf_is_valid(buf_id) and vim.bo[buf_id].buflisted end

--- Checks whether the buffer is a regular file buffer.
-- It also checks if buffer is valid and listed.
---@param buf_id buffer id to be checked.
---@return boolean
function M.is_file_buffer(buf_id)
	return M.is_valid_buffer(buf_id) and vim.bo[buf_id].buftype ~= "terminal"
end

-- Checks whether the buffer is regular file buffer.
--- It also checks if buffer is valid and listed.
function M.get_active_buffers()
	local bufs = api.nvim_list_bufs()
	local active_buffers = {}
	local count = 0
	for _, buf_id in ipairs(bufs) do
		if M.is_file_buffer(buf_id) then
			count = count + 1
			active_buffers[count] = buf_id
		end
	end
	return active_buffers
end

return M

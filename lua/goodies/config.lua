local M = {}
--------------------------------------------------------------------------------

---@class Goodies.config
local defaultConfig = {
	author = {
		email = "",
		github = "",
		twitter = "",
		name = "",
	},
	auto_normal = {
		timeout = 3000,
	},
}

M.config = defaultConfig

--------------------------------------------------------------------------------

---@param userConfig? Goodies.config
M.setup = function(userConfig)
	M.config = vim.tbl_deep_extend("force", defaultConfig, userConfig or {})
end

--------------------------------------------------------------------------------
return M

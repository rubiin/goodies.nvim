local M = {}
--------------------------------------------------------------------------------

---@param userConfig? Goodies.config
M.setup = function(userConfig) require("goodies.config").setup(userConfig) end

-- Lazy-load utils for better startup performance
setmetatable(M, {
	__index = function(t, k)
		local utils = require("goodies.utils")
		if utils[k] then
			rawset(t, k, utils[k])
			return utils[k]
		end
	end,
})

--------------------------------------------------------------------------------
return M

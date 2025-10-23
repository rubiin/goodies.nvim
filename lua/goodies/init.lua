local M = {}
--------------------------------------------------------------------------------

---@param userConfig? Goodies.config
M.setup = function(userConfig) require("goodies.config").setup(userConfig) end

local utils = require("goodies.utils")

M.add_author_details = utils.add_author_details
M.cowboy = utils.cowboy
M.open_at_regex_101 = utils.open_at_regex_101
M.open_in_browser = utils.open_in_browser
M.open_url = utils.open_url
M.comment_hr = utils.comment_hr
M.code_runner = utils.code_runner
M.run_file = utils.run_file
M.word_count = utils.word_count

--------------------------------------------------------------------------------
return M

vim.api.nvim_create_user_command(
	"WordCount",
	function()
		vim.notify(
			"Word count: " .. require("goodies").word_count(),
			vim.log.levels.INFO,
			{ title = "Word Count" }
		)
	end,
	{}
)

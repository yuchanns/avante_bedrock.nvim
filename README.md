## Avante.nvim Bedrock Provider

Just an idea, not yet working properly. The issue is that when using `bedrock` in `plenary.nvim`, part of the data arrives through `on_stdout` and the last small portion arrives through `callback`.

We are not able to mark the end of the response data with `("avante.llm").on_complete` function in `callback` as it will rise an error `nvim_buf_get_name must not be called in a lua loop callback`.

```lua
{
    "yetone/avante.nvim",
    dependencies = {
        { "yuchanns/avante_bedrock.nvim", build = "make" },
        --- rest of configs
    },
    config = function()
        require("avante_bedrock").setup()
        require("avante").setup({
            provider = "bedrock",
            vendors = {
                bedrock = require("avante_bedrock").vendor(),
            },
        })
    end,
}

```

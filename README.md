## Avante.nvim Bedrock Provider

Just an idea, not yet working properly. The issue is that when using `bedrock` in `plenary.nvim`, part of the data arrives through `on_stdout` and the last small portion arrives through `callback`.

We are not able to mark the end of the response data with `("avante.llm").on_complete` function in `callback` as it will rise an error `nvim_buf_get_name must not be called in a lua loop callback`.

### Requirements

- Rust toolchain

### Configuration

```lua
{
    "yetone/avante.nvim",
    dependencies = {
        { "yuchanns/avante_bedrock.nvim", build = "make" },
        --- rest of configs
    },
    config = function()
        require("avante_bedrock").setup({
            -- default config
            base_uri = "https://bedrock-runtime.us-east-1.amazonaws.com", -- The base URI for the Bedrock service.
            model = "anthropic.claude-3-5-sonnet-20240620-v1:0", -- The model identifier used for the service.
            access_key_id = os.getenv("AWS_ACCESS_KEY_ID") or "", -- Your AWS access key ID for authentication.
            secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY") or "", -- Your AWS secret access key for authentication.
            ---@alias Region "us-east-1" | "us-east-2" | "ap-southeast-1"
            region = "us-east-1", -- The AWS region where the service is hosted.
            max_tokens = 4096,
            temperature = 0.6,
            top_p = 1,
            antropic_version = "bedrock-2023-05-31",
        })
        require("avante").setup({
            provider = "bedrock",
            vendors = {
                bedrock = require("avante_bedrock").vendor(),
            },
        })
    end,
}

```

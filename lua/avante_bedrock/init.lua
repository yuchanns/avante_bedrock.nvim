local M = {}

---@class avante_bedrock.Config
---@field base_uri string The base URI for the Bedrock service.
---@field model string The model identifier used for the service.
---@field access_key_id string Your AWS access key ID for authentication.
---@field secret_access_key string Your AWS secret access key for authentication.
---@field region string The AWS region where the service is hosted.
---@field max_tokens number The maximum number of tokens to generate.
---@field temperature number The temperature to use for sampling.
---@field top_p number The top-p value to use for sampling.
---@field antropic_version string The version of the Anthropic service to use.
local defaults = {
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
}

M.did_setup = false
M.did_load = false

---@type avante_bedrock.Config
M.options = {}

function M.vendor()
	return {
		endpoint = ("%s/model/%s/invoke-with-response-stream"):format(M.options.base_uri, M.options.model),
		model = M.options.model,
		api_key_name = "AWS_SECRET_ACCESS_KEY",
		parse_curl_args = function(opts, code_opts)
			if not M.did_load then
				require("reqsign_aws_lib").load()
				M.did_load = true
			end
			local reqsign_aws = require("reqsign_aws")
			local claude = require("avante.providers").claude
			local messages = {}
			for _, m in ipairs(claude.parse_message(code_opts)) do
				local message = {
					role = m.role,
					content = {},
				}
				for _, content in ipairs(m.content) do
					table.insert(message.content, {
						type = "text",
						text = content.text,
					})
				end
				table.insert(messages, message)
			end
			local body = {
				anthropic_version = M.options.antropic_version,
				max_tokens = M.options.max_tokens,
				messages = messages,
				temperature = M.options.temperature,
				top_p = M.options.top_p,
			}
			local headers = reqsign_aws.sign({
				access_key_id = M.options.access_key_id,
				secret_access_key = M.options.secret_access_key,
				region = M.options.region,
				headers = {
					["Content-Type"] = "application/json",
				},
				body = vim.json.encode(body),
				service = "bedrock",
				method = "POST",
				uri = opts.endpoint,
			})
			return {
				url = opts.endpoint,
				headers = headers,
				body = body,
			}
		end,
		parse_stream_data = function(line, opts)
			if not line then
				return
			end
			local claude = require("avante.providers").claude
			for data_match in line:gmatch("event(%b{})") do
				local data = vim.json.decode(data_match)
				local data_stream = vim.base64.decode(data.bytes)
				local json = vim.json.decode(data_stream)
				claude.parse_response(data_stream, json.type, opts)
			end
		end,
	}
end

---@param opts? avante_bedrock.Config
function M.setup(opts)
	if M.did_setup then
		return
	end
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})

	M.did_setup = true
end

return M

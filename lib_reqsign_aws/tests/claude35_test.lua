local reqsign_aws = require("reqsign_aws")
local curl = require("curl")

local uri =
	"https://bedrock-runtime.us-east-1.amazonaws.com/model/anthropic.claude-3-5-sonnet-20240620-v1:0/invoke-with-response-stream"
local json_body =
	[[{"anthropic_version":"bedrock-2023-05-31","max_tokens":4096,"messages":[{"content":"How to sign a bedrock http request without SDK\n","role":"user"}],"temperature":0.6,"top_p":1}]]

local headers = reqsign_aws.sign({
	access_key_id = os.getenv("AWS_ACCESS_KEY_ID"),
	secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY"),
	region = "us-east-1",
	headers = {
		["Content-Type"] = "application/json",
	},
	body = json_body,
	service = "bedrock",
	method = "POST",
	uri = uri,
})

local _, status_code = curl.post(json_body, uri, headers, function(line)
	local data_match = line:match("event(%b{})")
	if not data_match then
		return
	end
	print(data_match)
end)

assert(status_code == 200, "Request failed with status code: " .. tonumber(status_code))

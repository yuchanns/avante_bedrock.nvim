local reqsign_aws = nil

local M = {}

function M.setup()
	reqsign_aws = require("reqsign_aws")
end

function M.available()
	return reqsign_aws ~= nil
end

function M.sign(opts)
	if not reqsign_aws then
		return nil
	end
	return reqsign_aws.sign(opts)
end

return M

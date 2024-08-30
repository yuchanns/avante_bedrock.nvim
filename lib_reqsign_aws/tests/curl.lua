local ffi = require("ffi")
local curl = ffi.load("curl")

ffi.cdef([[
    typedef void CURL;
    typedef int CURLcode;
    typedef size_t (*curl_write_callback)(char *ptr, size_t size, size_t nmemb, void *userdata);

    CURL *curl_easy_init();
    CURLcode curl_easy_setopt(CURL *curl, int option, ...);
    CURLcode curl_easy_perform(CURL *curl);
    void curl_easy_cleanup(CURL *curl);
    struct curl_slist *curl_slist_append(struct curl_slist *list, const char *string);
    void curl_slist_free_all(struct curl_slist *list);
    CURLcode curl_easy_getinfo(CURL *curl, int info, ...);

    enum {
        CURLOPT_URL = 10002,
        CURLOPT_WRITEFUNCTION = 20011,
        CURLOPT_WRITEDATA = 10001,
        CURLOPT_HTTPHEADER = 10023,
        CURLOPT_POSTFIELDS = 10015,
        CURLINFO_RESPONSE_CODE = 0x200002,
    };
]])

local function post_request(json_body, uri, headers, callback)
	local response_body = {}

	local function write_callback(ptr, size, nmemb, userdata)
		local data = ffi.string(ptr, size * nmemb)
		table.insert(response_body, data)
		callback(data)
		return size * nmemb
	end

	local cb = ffi.cast("curl_write_callback", write_callback)

	local curl_handle = curl.curl_easy_init()
	if curl_handle == nil then
		error("Failed to initialize curl")
	end

	-- Set URL
	curl.curl_easy_setopt(curl_handle, ffi.C.CURLOPT_URL, uri)

	-- Set headers
	local curl_headers = ffi.new("struct curl_slist*")
	for k, v in pairs(headers) do
		curl_headers = curl.curl_slist_append(curl_headers, k .. ": " .. v)
	end
	curl.curl_easy_setopt(curl_handle, ffi.C.CURLOPT_HTTPHEADER, curl_headers)

	-- Set JSON body
	curl.curl_easy_setopt(curl_handle, ffi.C.CURLOPT_POSTFIELDS, json_body)

	-- Set write callback
	curl.curl_easy_setopt(curl_handle, ffi.C.CURLOPT_WRITEFUNCTION, cb)

	-- Perform the request
	local res = curl.curl_easy_perform(curl_handle)

	if res ~= 0 then
		error("curl_easy_perform() failed: " .. res)
	end

	-- Get HTTP status code
	local http_code = ffi.new("long[1]")
	curl.curl_easy_getinfo(curl_handle, ffi.C.CURLINFO_RESPONSE_CODE, http_code)

	-- Clean up
	curl.curl_easy_cleanup(curl_handle)
	curl.curl_slist_free_all(curl_headers)

	return table.concat(response_body), http_code[0]
end

return {
	post = post_request,
}

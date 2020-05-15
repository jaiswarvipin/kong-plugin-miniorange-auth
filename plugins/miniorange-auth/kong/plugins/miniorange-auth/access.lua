--[[
	Purpose 	: Validating the any api request using this plugin we are calling "Request Authorization".
				  If Request token is valid then sending the request to the upstream system or 
				  terminiating the request and sending the validation response to the requestor
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
	Date			Change Done by			Change Description
	**********************************************************************************************************
	12-May-2020		Jaiswar Vipin Kumar R.	Created
	**********************************************************************************************************
--]]

-- Getting kong Response Object
local kong_response = kong.response
--Getting JSON refrence
local JSON = require "kong.plugins.miniorange-auth.json"
-- Getting JSON Lib Refereance
local cjson = require "cjson"
-- Getting Socket lib Refereance
local url = require "socket.url"
-- Getting the String Formatter Lib reference
local string_format = string.format

-- Getting the Request Header method reference
local get_headers = ngx.req.get_headers
-- Getting the Request URL query string method reference
local get_uri_args = ngx.req.get_uri_args
-- Getting the request read body method reference
local read_body = ngx.req.read_body
-- Getting the reqeust body data method reference
local get_body = ngx.req.get_body_data 
-- Getting the request method (POST, GET, OPTIONS etc..) method reference
local get_method = ngx.req.get_method
-- Getting the URL match method reference
local ngx_re_match = ngx.re.match
-- Getting the find lib method reference
local ngx_re_find = ngx.re.find

-- local variable declaration
local HTTP 			= "http"
local HTTPS 		= "https"
local HTTP_PORT 	= 80
local HTTPS_PORT 	= 443
local _M = {}

--[[
	**********************************************************************************************************
	Purpose		: Parsing the request URL foe getting the HTTP/HTTPS and port
	Input		: pStrHostURL :: Requestor URL
	Response	: Array :: contains reqeust SCHEME and PORT
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
--]]
local function getParseURL(pStrHostURL)
	-- Getting PARSED URL colelction
	local strParsedURLArr = url.parse(pStrHostURL)
	-- If port found from the parsed URL then do needful
	if not strParsedURLArr.port then
		-- Checking parsed URL schema and based on teh set the PORT number
		if strParsedURLArr.scheme == HTTP then
			-- Setting the HTTP port 80
			strParsedURLArr.port = HTTP_PORT
		-- Checking parsed URL schema and based on teh set the PORT number
		elseif strParsedURLArr.scheme == HTTPS then
			-- Setting the HTTPS port 443
			strParsedURLArr.port = HTTPS_PORT
		end
	end
	
	-- Checking the prased URL path, if not found then
	if not strParsedURLArr.path then
		-- Setting the root path 
		strParsedURLArr.path = "/"
	end
	
	-- Return the parse URL array
	return strParsedURLArr
end


--[[
	**********************************************************************************************************
	Purpose		: Execute the access file default method
	Input		: pStrDatabaseRef :: Database reference
	Response	: Based on the token validation returning response or stop the execution
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
--]]
function _M.execute(pStrDatabaseRef)
	-- Checking the current configuration for current request
	-- If reqeust is set to test and current method is OPTIONS then do no excute the request
	if not pStrDatabaseRef.run_on_preflight and get_method() == "OPTIONS" then
		-- Stop executing the plugin logic and send request to execute the upstream-url
		return
	end

	-- Defining the local variables for logging purpose
	local strPluginName = "[miniorange-auth] "
	local strOKResponseObj, strErrorResponseObj
	-- Get the Parsed URL collection
	local strParsedURLArr = getParseURL(pStrDatabaseRef.url)
	-- Get the HOST from Parsed URL collection
	local strHost = strParsedURLArr.host
	-- Get the PORT from Parsed URL collection
	local strPort = tonumber(strParsedURLArr.port)
	-- Get the Paylod of the current request
	local arrPayloadObj = _M.compose_payload(strParsedURLArr)
	
	-- Get the socket TCP lib reference
	local sock = ngx.socket.tcp()
	-- Setting the connection time out for current request
	sock:settimeout(pStrDatabaseRef.timeout)
		
	-- Get the response from the configured reqeust auth upstream url and port and connect
	strOKResponseObj, strErrorResponseObj = sock:connect(strHost, strPort)
	
	-- If no response then stop log it and do not execute the further plugin logic 
	if not strOKResponseObj then
		-- Loggin
		ngx.log(ngx.ERR, strPluginName .. "failed to connect to " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		-- Return empty response and stop the further execution and send error
		return
	end

	-- If current reqeust schema is HTTP(s) then
	if strParsedURLArr.scheme == HTTPS then
		-- Checking reqeust upstream url (server) support the SSL
		local _, strErrorResponseObj = sock:sslhandshake(true, strHost, false)
		-- If not SSL support then
		if strErrorResponseObj then
			-- Loggin
			ngx.log(ngx.ERR, strPluginName .. "failed to do SSL handshake with " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		end
	end

	-- Sending the request to the authencation upstream URL with payload
	strOKResponseObj, strErrorResponseObj = sock:send(arrPayloadObj)
	if not strOKResponseObj then
		-- Loggin
		ngx.log(ngx.ERR, strPluginName .. "failed to send data to " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
	end
	
	-- Checking the Response from from current sock
	local line, strErrorResponseObj = sock:receive("*l")
	-- if received the error
	if strErrorResponseObj then 
		-- Loggin
		ngx.log(ngx.ERR, strPluginName .. "failed to read response status from " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		-- Return empty response and stop the further execution and send error
		return
	end

	-- Getting the status code from received response, as response is string format
	local intStatusCode = tonumber(string.match(line, "%s(%d%d%d)%s"))
	-- Defining the header
	local strHeadersArr = {}

	-- Running the infinte loop, till geting the complete response from upstream server
	repeat
		-- Getting the status code from received response, as response is string format
		line, strErrorResponseObj = sock:receive("*l")
		-- If error found in any chunk then do needful
		if strErrorResponseObj then
			-- Loggin
			ngx.log(ngx.ERR, strPluginName .. "failed to read header " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
			-- Return empty response and stop the further execution and send error
			return
		end
		
		-- Extracting the header received from the auth upstream URL
		local pair = ngx_re_match(line, "(.*):\\s*(.*)", "jo")
		-- If header oinf then od needful
		if pair then
			-- Set the header array
			strHeadersArr[string.lower(pair[1])] = pair[2]
		end
	-- Repeat untill received the chunk as response
	until ngx_re_find(line, "^\\s*$", "jo")

	-- Get the response body and error
	local body, strErrorResponseObj = sock:receive(tonumber(strHeadersArr['content-length']))
	
	-- if e3rror received then do needful
	if strErrorResponseObj then
		-- Loggin
		ngx.log(ngx.ERR, strPluginName .. "failed to read body " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		-- Return empty response and stop the further execution and send errors
		return
	end
	
	-- If still not received the resoponse so checking for connection timeout
	strOKResponseObj, strErrorResponseObj = sock:setkeepalive(pStrDatabaseRef.keepalive)
	-- If Response is not postive then do needful
	if not strOKResponseObj then
		-- Loggin
		ngx.log(ngx.ERR, strPluginName .. "failed to keepalive to " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		-- Return empty response and stop the further execution and send errors
		return
	end

	-- if received response code grater then 299 then od needful
	if intStatusCode > 299 then
		-- if received any error response then logg that error
		if strErrorResponseObj then 
			-- Loggin
			ngx.log(ngx.ERR, strPluginName .. "failed to read response from " .. strHost .. ":" .. tostring(strPort) .. ": ", strErrorResponseObj)
		end
		
		-- Decoded received response in the JOSON format
		local strResponseBody	= JSON:decode(body)
		
		-- if recived response if negative then do needful
		if strResponseBody.status == nill or strResponseBody.status ~= 'SUCCESS' then 
			-- Setting the error message received from the auth upstream server
			local strErrorMessage	= 'Aunauthrized access - '..strResponseBody.message
			local intErrorCode		= 403
			
			-- Set the response header
			kong_response.set_status(intErrorCode)
			-- Set the response header
			kong_response.set_header('x-miniorange-auth', strErrorMessage)
			-- Response with message and stop the all execution
			return kong_response.exit(intErrorCode, [[{"message":strErrorMessage}]], {
																						["Content-Type"] = "application/json",
																						["WWW-Authenticate"] = "Basic"
																					}
										)
		end
		
		-- Return the reveived response with status code
		return kong_response.send(intStatusCode, strResponseBody)
	end
end


--[[
	**********************************************************************************************************
	Purpose		: Execute the payload from the request
	Input		: pStrParsedURLArr :: Parsed URL collection
	Response	: Return the reqeust playload
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
--]]
function _M.compose_payload(pStrParsedURLArr)
	-- Get the header collection of current reqeust method
    local strHeadersArr = get_headers()
	-- Get the query string collection from URL argument method
    local strURLArgsArr = get_uri_args()
	-- Set the next iterator refrerence
    local next = next
    
	-- Reading the reqeust body method reference
    read_body()
	-- Get the reqeust
    local body_data = get_body()
	
	-- Setting the header with current reqeust url
    strHeadersArr["target_uri"] 	= ngx.var.request_uri
	-- Setting the header with current request method
    strHeadersArr["target_method"] 	= ngx.var.request_method

	-- Defining the loal variable
    local strURL
	
	-- If query string found tehn do needful
    if pStrParsedURLArr.query then
		-- Setting the URL
		strURL = pStrParsedURLArr.path .. "?" .. pStrParsedURLArr.query
	else
		-- If not query string variable found then do needful
      strURL = pStrParsedURLArr.path
    end
    
	-- Setting the Header and body data JSON encoded format
    local strRowJSONHeaders = JSON:encode(strHeadersArr)
    local strRowJSONBodyData = JSON:encode(body_data)

	-- Setting the local variable
    local strRowJSONURLArgs
	
	-- Iteratig the argument and encode it 
    if next(strURLArgsArr) then 
		-- Set the encoded URL argument
		strRowJSONURLArgs = JSON:encode(strURLArgsArr) 
    else
		-- Empty Lua table gets encoded into an empty array whereas a non-empty one is encoded to JSON object.
		-- Set an empty object for the consistency.
		strRowJSONURLArgs = "{}"
    end
	
	-- Creating the playload body
    local strPayloadBody = [[{"headers":]] .. strRowJSONHeaders .. [[,"uri_args":]] .. strRowJSONURLArgs.. [[,"body_data":]] .. strRowJSONBodyData .. [[}]]
    
	-- Formatting the payload and creating header
    local payload_headers = string_format(
      "POST %s HTTP/1.1\r\nHost: %s\r\nConnection: Keep-Alive\r\nContent-Type: application/json\r\nContent-Length: %s\r\n",
      strURL, pStrParsedURLArr.host, #strPayloadBody)
  
	-- Return the payload
    return string_format("%s\r\n%s", payload_headers, strPayloadBody)
end

--Return the access methods reference
return _M
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


-- Getting kong lib refereance
local kong = kong

-- Import the base kong plugin
local BasePlugin = require "kong.plugins.base_plugin"
-- Extend our plugin from the access plugin
local MiniOrangeAccessObj 	= require "kong.plugins.miniorange-auth.access"
-- Extend our plugin from the base plugin
local MiniorangeAuthHandler = BasePlugin:extend()

-- Setting this very early to avoid logging any service-tokens
MiniorangeAuthHandler.PRIORITY = 5

--[[
	**********************************************************************************************************
	Purpose		: creates a new instance of the plugin
	Input		: None
	Response	: None
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
--]]
function MiniorangeAuthHandler:new()
	--Creating Refrence
	MiniorangeAuthHandler.super.new(self, "miniorange-auth")
end

--[[
	**********************************************************************************************************
	Purpose		: Performing the request validation of request
	Input		: conf :: Database Refrence
	Response	: API Response
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
--]]
function MiniorangeAuthHandler:access(conf)
  --Get Access module refrence
  MiniorangeAuthHandler.super.access(self)
  --Calling the access module and execute the complete log and do response
  MiniOrangeAccessObj.execute(conf)
end

-- return the plugin class
return MiniorangeAuthHandlers
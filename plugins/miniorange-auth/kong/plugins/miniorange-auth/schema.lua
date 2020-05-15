--[[
	Purpose 	: Create the database schema for "Request Authorization" plugin
	Created By	: Jaiswar Vipin Kumar R.
	**********************************************************************************************************
	Date			Change Done by			Change Description
	**********************************************************************************************************
	12-May-2020		Jaiswar Vipin Kumar	R.	Created
	**********************************************************************************************************
--]]

--Return the schema Refrence
return {
	-- Customer ID is optional
	no_consumer = true,
	--Filed of the plugin
	fields = {
		-- Request token validation upstream URL
		url = {required = true, type = "string"},
		-- Expacted Response in Array (Table) or String
		response = { required = true, default = "table", type = "string", enum = {"table", "string"}},
		-- Reqeust Timeout, Default will be 5 sec
		timeout = { default = 5000, type = "number" },
		-- Reqeust Connection Timeout, Default will be 5 sec
		keepalive = { default = 5000, type = "number" }
  }
}
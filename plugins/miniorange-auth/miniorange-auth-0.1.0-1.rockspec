package = "miniorange-auth"
version = "0.1.0-1"


supported_platforms = {"linux", "macosx"}
source = {
  url = "http://github.com/beatsbears/kong-plugin-blog",
  tag = "0.1.0"
}

description = {
  summary = "Miniorange is the plugin help to authenticate the each api request with mini-orange.",
  homepage = "http://github.com/beatsbears/kong-plugin-blog",
  license = "MIT"
}

dependencies = {
}

local pluginName = "miniorange-auth"
build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".header_filter"] = "kong/plugins/"..pluginName.."/header_filter.lua",
  }
}
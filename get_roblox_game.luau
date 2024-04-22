local roblox = require("@lune/roblox")
local net = require("@lune/net")
local fs = require("@lune/fs")
local process = require("@lune/process")

-- Check if a place ID is provided as a command-line argument
local args = process.args
if #args < 3 then
	print("Usage: lune script.ln <place_id> <game_name> <development_type>")
	return
end

-- File Configuration
local placeId = args[1]
local currentGameName = args[2]
local env = args[3]

local game_file = currentGameName .. " [" .. env .. "].rbxlx"
fs.writeDir("assets")

-- Function to fetch the place file content using the Roblox API
local function fetchPlaceFileByPlaceId(placeId)
	local cookie = roblox.getAuthCookie()

	if not cookie then
		print("Failed to get Roblox auth cookie.")
		return nil
	end

	local apiUrl = "https://assetdelivery.roblox.com/v2/assetId/" .. tostring(placeId)
	local headers = {
		Cookie = cookie,
	}

	local response = net.request({
		url = apiUrl,
		headers = headers,
	})

	print(response)

	print(response.statusCode)

	if response.statusCode == 200 then
		return response.body
	else
		print("Failed to fetch place file. Status code: " .. tostring(response.statusCode))
		return nil
	end
end

-- Fetch place file
local placeFile = fetchPlaceFileByPlaceId(placeId)
if placeFile then
	-- Print the content of the place file for inspection

	-- Decode the JSON string into a Lua table
	local placeFileTable = net.jsonDecode(placeFile)

	-- Ensure the expected structure is present
	if placeFileTable and type(placeFileTable) == "table" and placeFileTable.locations then
		local location = placeFileTable.locations[1].location
		print("Download link to place:", location)
		local gameBinary = net.request(location).body

		print(tostring(typeof(gameBinary)))
		fs.writeFile(game_file, gameBinary)
	end

	--[[ local file = fs.readFile(game_file)
	local game = roblox.deserializePlace(file)
	local SERVICES = { "Workspace", "ReplicatedStorage", "ServerStorage", "Lighting" }

	-- Iterate through each service and save it as an .rbxm file
	for _, serviceName in pairs(SERVICES) do
		local service = game:GetService(serviceName)
		if service then
			local fileContent = roblox.serializeModel({ service })
			fs.writeFile("assets/" .. serviceName .. ".rbxm", fileContent)
		else
			print("Service '" .. serviceName .. "' not found in the asset place file.")
		end
	end
	-- Save the DataModel (game) back to the file that we read it from
	file = roblox.serializePlace(game)
	fs.writeFile(game_file, file) ]]
else
	print("Failed to fetch place file.")
end

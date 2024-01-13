local roblox = require("@lune/roblox")
local net = require("@lune/net")
local fs = require("@lune/fs")
local process = require("@lune/process")

-- Check if a place ID is provided as a command-line argument
local args = process.args
if #args > 1 then
	print("Usage: lune script.ln <place_id>")
	return
end

local placeId = args[1]
print(placeId)

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
print("Place File Content:", placeFile)
if placeFile then
	-- Print the content of the place file for inspection
	print("Place File Content:", placeFile)

	-- Decode the JSON string into a Lua table
	local placeFileTable = net.jsonDecode(placeFile)

	-- Ensure the expected structure is present
	if placeFileTable and type(placeFileTable) == "table" and placeFileTable.locations then
		local location = placeFileTable.locations[1].location
		print("Download link to place:", location)
		local gameBinary = net.request(location).body

		print(tostring(typeof(gameBinary)))

		local fileName = "build_output.rbxlx"

		-- Save the binary content to a temporary rbxlx file
		local file = fs.writeFile(fileName, gameBinary)
	end
else
	print("Failed to fetch place file.")
end

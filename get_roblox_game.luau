--[[
-- Author: BenryBytes
-- Usage: Below it is able to fetch scripts and buildings
-- You could disable script fetching and/or commit or stash your changes before pulling beforehand
-- Another alternative would be to seperate script fetching, replicated storage fetching, and/or other things
--
-- Heads up: If authentication does not work, logout and log back in to the account and test the script
-- Confirm if your account has access via checking the cookies on the browser and here through a print statement, and remember to not expose it
--]]
--

local roblox = require("@lune/roblox")
local net = require("@lune/net")
local fs = require("@lune/fs")
local process = require("@lune/process")

-- Check if a place ID is provided as a command-line argument
local args = process.args
if #args < 3 then
	print("Usage: lune script.ln <place_id> <iteration_name> <development_type>")
	return
end

-- File Configuration
local placeId = args[1]
local currentGameName = args[2]
local iteration_name = args[3]

local game_file = currentGameName .. " [" .. iteration_name .. "].rbxlx"
fs.writeDir("assets")

-- Function to fetch the place file content using the Roblox API
local function fetchPlaceFileByPlaceId(placeId)
	local cookie = roblox.getAuthCookie()

	if not cookie then
		print("Failed to get Roblox auth cookie.")
		return nil
	end
	local apiUrl = "https://assetdelivery.roblox.com/v2/assetId/" .. placeId
	local headers = {
		Accept = "application/json",
		Cookie = cookie,
	}

	local response = net.request({
		url = apiUrl,
		headers = headers,
	})

	print(response)

	-- local decodedJson = json
	--    local downloadPlaceFileUrl = decodedJson.locations[0].location
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
		local gameBinary = net.request(location).body

		fs.writeFile(game_file, gameBinary)
	end

	local file = fs.readFile(game_file)
	local game = roblox.deserializePlace(file)
	local SERVICES =
		{ "Workspace", "ReplicatedStorage", "ServerStorage", "Lighting", "StarterPlayer", "ServerScriptService" }

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
	local script_types = { ["LocalScript"] = "client", ["Script"] = "server", ["ModuleScript"] = "" }

	local function handleGiveScripts(serviceToFetchScripts, initialPath: string)
		-- Here we load a file just like in the first example

		-- Make sure a directory exists to save our models in
		fs.writeDir("src/" .. initialPath)

		-- Then we save all of our instances in Workspace as model files, in our new directory
		-- Note that a model file can actually contain several instances at once, so we pass a table here
		local function getScripts(folder, currentDir)
			for _, child in pairs(folder:GetChildren()) do
				local checkIfScript: boolean = (
					child:IsA("Script")
					or child:IsA("ModuleScript")
					or child:IsA("LocalScript")
				)
				if not checkIfScript then
					getScripts(child, tostring(currentDir .. "/" .. child.Name))
				elseif checkIfScript then
					fs.writeDir(currentDir)
					local script_content = child.Source
					local tempLocation = currentDir .. "/"

					local script_type: string = script_types[child.ClassName]

					if script_type == "" then
						fs.writeFile(tempLocation .. child.Name .. ".luau", script_content)
					else
						fs.writeFile(tempLocation .. child.Name .. "." .. script_type .. ".luau", script_content)
					end
				end
			end
		end

		getScripts(serviceToFetchScripts, "src/" .. initialPath)
	end

	local starterPlayer = game:GetService("StarterPlayer")
	local starterCharacterScripts = starterPlayer:FindFirstChild("StarterCharacterScripts")
	local starterPlayerScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
	local server_scripts_service = game:GetService("ServerScriptService")

	print(starterCharacterScripts)
	print(starterPlayerScripts)

	handleGiveScripts(starterCharacterScripts, "starter_character")
	handleGiveScripts(starterPlayerScripts, "starter_player")
	handleGiveScripts(server_scripts_service, "server_scripts_service")

	-- Save the DataModel (game) back to the file that we read it from
	file = roblox.serializePlace(game)
	fs.writeFile(game_file, file)
	fs.removeFile(game_file)
else
	print("Failed to fetch place file.")
end

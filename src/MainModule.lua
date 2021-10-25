--!nocheck

--[[ TODO (in order)
	Instance.new
	Script Sandbox
	Workspace, Hopperbin and Tool
	ContextActionService
	Camera Properties
	Sound Properties
	Script Sandbox (the most important)
	Mobile support
--]]

--> For scripts that use a Tool, just replace the Tool mouse to LocalPlayer:GetMouse()

--> Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

--> Immutable
local Clock = os.clock
local Uppercase = string.upper
local Substring = string.sub
local Stepped = RunService.Stepped
local Modifiers = Enum.ModifierKey:GetEnumItems()
local Inputs = {"GetKeysPressed", "GetMouseButtonsPressed", "GetGamepadState", 
	"GetDeviceAcceleration", "GetDeviceGravity", "GetDeviceRotation"}

--> Mutable
local Times = 0
local Storage = {}

--> Functions
local function Correct(String)
	return Uppercase(Substring(String, 1, 1)) .. Substring(String, 2)
end

local function CreateUserdata(Class, Metatable)
	local Userdata = newproxy(true)

	for Index, Value in pairs(Metatable) do
		getmetatable(Userdata)[Index] = Value
	end

	if Metatable.__newindex == nil then
		if Class.Name ~= nil then
			getmetatable(Userdata).__newindex = function(_, Index, Value)
				if Class[Index] ~= nil then
					if not pcall(function()
							Class[Index] = Value
						end) then
						error("can't set value")
					end
				else
					error(Index .. " is not a valid member of " .. Class.ClassName .. " \"" .. Class.Name .. "\"")
				end
			end
		else
			getmetatable(Userdata).__newindex = function(_, Index)
				error(Index .. " cannot be assigned to " .. Class)
			end
		end
	end

	getmetatable(Userdata).__metatable = nil
	getmetatable(Userdata).__tostring = function()
		return Class.Name or Class
	end

	return Userdata
end


local function CreateSignal(Id, Number, Name, Service)
	Storage[Id][2][Number][Name] = {{}, false}
	local Signal = Storage[Id][2][Number][Name]

	function Signal:Connect(Function, ...)
		if Service.VREnabled ~= nil then
			--> It's funny that I replicate all the errors
			if Name == "DeviceRotationChanged" and not Service.GyroscopeEnabled then
				warn("Trying to listen to rotation events on a device without a gyroscope.")
				return
			elseif (Name == "DeviceGravityChanged" or Name == "DeviceAccelerationChanged") and not Service.AccelerometerEnabled then
				warn("Trying to listen to rotation events on a device without a accelerometer.")
				return
			end
		end

		local Length = #Signal[1] + 1
		Signal[1][Length] = {}
		Signal[1][Length][1] = Function
		Signal[1][Length][2] = ... or nil

		return CreateUserdata("Connection", {
			__index = function(self, Index)
				Index = Correct(Index)

				if Index == "Connected" then
					if Signal[1][Length] ~= nil then
						return true
					end

					return false
				elseif Index == "Disconnect" then
					return function()
						Signal[1][Length] = nil
					end
				end
			end
		})
	end

	function Signal:Wait()
		Signal[2] = true
		local Time = Clock()

		while Signal[2] do
			task.wait()
		end

		return Clock() - Time
	end

	return CreateUserdata("Signal " .. Name, {
		__index = function(self, Index)
			local CIndex = Correct(Index)

			if Signal[CIndex] ~= nil then
				return Signal[CIndex]
			else
				error(Index .. " is not a valid member of RBXScriptSignal")
			end
		end
	})
end

local function CreateInstance(Name, Class, Properties)
	local Instance = Instance.new(Class)
	Instance.Name = Name
	Properties = Properties or {}

	for Index, Value in pairs(Properties) do
		Instance[Index] = Value
	end

	return Instance
end

function FireSignal(Signal, ...)
	for _, Connection in ipairs(Signal[1]) do
		task.spawn(Connection[1], Connection[2] or ...)
	end

	Signal[2] = false
end

--> Remotes
local GSRemotes = CreateInstance("GS Remotes", "Folder")
local GSFunction = CreateInstance("GS Function", "RemoteFunction")
local GSEvent = CreateInstance("GS Event", "RemoteEvent")
GSEvent.Parent = GSRemotes
GSFunction.Parent = GSRemotes
GSRemotes.Parent = ReplicatedStorage

--> Events
Players.PlayerRemoving:Connect(function(Player)
	--> Collect garbage
	if Storage[Player.UserId] then
		for _, Script in ipairs(Storage[Player.UserId][1]) do
			if Script.Disabled ~= nil then
				Script.Disabled = true
				Script:Destroy()
			end
		end

		Storage[Player.UserId] = nil
	end
end)

--> Public Function
return function(Player)
	--> Used to know how long it takes to convert
	local Time = Clock()

	--> Errors
	if RunService:IsClient() then
		error("Can't be used on client environment")
	elseif Player == nil then
		error("Argument 1 missing or nil")
	elseif type(Player) ~= "userdata" or Player.ClassName ~= "Player" then
		error("Argument 1 is not a player")
	end

	Times += 1
	local Times = Times

	--> Script environment
	local Environment = getfenv(2)

	--> Stores the player for optimizations
	Storage[Player.UserId] = {}
	local Storage = Storage[Player.UserId]
	Storage[1] = {}
	Storage[1][#Storage[1] + 1] = Environment.script
	Storage[2] = {}
	Storage[2][Times] = {}

	--> Able to execute in client
	local PlayerGui = Player:FindFirstChildOfClass("PlayerGui")

	if not PlayerGui:FindFirstChild("GS Shield") then
		local Client = script.Client:Clone()
		local Shield = CreateInstance("GS Shield", "ScreenGui", {
			Enabled = false,
			ResetOnSpawn = false
		})

		Client.Parent = Shield
		Shield.Parent = PlayerGui
		Client.Disabled = false
	end

	--> Replacement Services
	local Services = {
		{ --> Mouse
			"Idle", "Move", "KeyUp", "KeyDown",
			"Button1Up", "Button2Up", "Button1Down",
			"Button2Down", "WheelForward", "WheelBackward"
		},
		{ --> UserInputService
			"TouchPan", "TouchTap", "TouchEnded", "TouchMoved",
			"TouchSwipe", "TouchPinch", "InputBegan", "InputEnded",
			"JumpRequest", "TouchRotate", "InputChanged", "TouchStarted",
			"WindowFocused", "PointerAction", "TouchLongPress", "TextBoxFocused",
			"TouchTapInWorld", "GamepadConnected", "UserCFrameChanged", "GamepadDisconnected",
			"WindowFocusReleased", "LastInputTypeChanged", "TextBoxFocusReleased", "DeviceGravityChanged",
			"DeviceRotationChanged", "DeviceAccelerationChanged",
		},
		{ --> ContextActionService (the hardest one)
			Actions = {},
			LocalToolEquipped = CreateSignal(Player.UserId, Times, "LocalToolEquipped", {}),
			LocalToolUnequipped = CreateSignal(Player.UserId, Times, "LocalToolUnequipped", {}),

			BindAction = function(self, ActionName, FunctionToBind, CreateTouchButton, ...)
				self.Actions[ActionName] = {}
				local Action = self.Actions[ActionName]
				Action.FunctionToBind = FunctionToBind
				Action.CreateTouchButton = CreateTouchButton
				Action.StackOrder = #self.Actions
				Action.PriorityLevel = 2
				Action.InputTypes = ...
				Action.Description = ""
				Action.Title = ""
				Action.Image = ""
			end,

			BindActionAtPriority = function(self, ActionName, FunctionToBind, CreateTouchButton, PriorityLevel, ...)
				self.Actions[ActionName] = {}
				local Action = self.Actions[ActionName]
				Action.FunctionToBind = FunctionToBind
				Action.CreateTouchButton = CreateTouchButton
				Action.StackOrder = #self.Actions
				Action.PriorityLevel = PriorityLevel
				Action.InputTypes = ...
				Action.Description = ""
				Action.Title = ""
				Action.Image = ""
			end,

			GetAllBoundActionInfo = function(self, ActionName)
				local Informations = {}

				for _, Action in pairs(self.Actions) do
					Informations[Action] = {
						stackOrder = Action.StackOrder,
						priorityLevel = Action.PriorityLevel,
						createTouchButton = Action.CreateTouchButton,
						inputTypes = Action.InputTypes,
						description = Action.Description,
						title = Action.Title,
						image = Action.Image,
					}
				end

				return Informations
			end,

			GetBoundActionInfo = function(self, ActionName)
				local Action = self.Actions[ActionName]

				return {
					stackOrder = Action.StackOrder,
					priorityLevel = Action.PriorityLevel,
					createTouchButton = Action.CreateTouchButton,
					inputTypes = Action.InputTypes,
					description = Action.Description,
					title = Action.Title,
					image = Action.Image,
				}
			end,

			GetCurrentLocalToolIcon = function()
				return Player.Character:FindFirstChildOfClass("Tool").TextureId
			end,

			SetDescription = function(self, ActionName, Description)
				self.Actions[ActionName].Description = Description
			end,

			SetImage = function(self, ActionName, Image)
				self.Actions[ActionName].Image = Image
			end,

			SetTitle = function(self, ActionName, Title)
				self.Actions[ActionName].Title = Title
			end,

			UnbindAction = function(self, ActionName)
				table.remove(self.Actions, ActionName)

				for Index, Action in pairs(self.Actions) do
					Action.StackOrder = Index
				end
			end,

			UnbindAllActions = function(self, ActionName)
				self.Actions = {}
			end,
		}
	}

	--> Nice way to reduce
	for I = 1, 2 do
		for Index, Signal in ipairs(Services[I]) do
			Services[I][Index] = nil
			--> If I == 2 then Services[2] else {}
			--> I kinda hate Lua ternary operator
			Services[I][Signal] = CreateSignal(Player.UserId, Times, Signal, I == 2 and Services[2] or {})
		end
	end

	local PlayerScripts = {ClassName = "PlayerScripts", Parent = Player, Archivable = true}

	--> Receive client event or properties
	GSEvent.OnServerEvent:Connect(function(_, Type, ...)
		local Arguments = {...}

		if Type == 1 then --> Error
			error(Arguments[2])
		elseif Type == 2 then --> PlayerScripts property
			PlayerScripts[Arguments[1]] = Arguments[2]
		elseif Type == 3 then --> Fires the event or receive new properties for the service
			if Arguments[2] then
				FireSignal(Storage[2][Times][Arguments[2]], Arguments[3])
			else
				for Name, Value in pairs(Arguments[3]) do
					Services[Arguments[1]][Name] = Value
				end
			end
		end
	end)

	--> I don't want to talk about this
	local function GetService(ClassName)
		if ClassName == "Players" then
			return CreateUserdata(Players, {
				__index = function(self, Index)
					if Correct(Index) == "LocalPlayer" then
						return CreateUserdata(Player, {
							__index = function(self, Index)
								if Index == "PlayerScripts" then
									return CreateUserdata(PlayerScripts, {
										__index = function(self, Index)
											if PlayerScripts[Index] ~= nil then
												if PlayerScripts[Index].Name ~= nil then
													return CreateUserdata(PlayerScripts[Index], {
														__index = function(self, _Index)
															if PlayerScripts[Index][_Index] ~= nil then
																return PlayerScripts[Index][_Index]
															else
																error(_Index .. " is not a valid member of LocalScript \"" .. PlayerScripts[Index].Name .. "\"")
															end
														end,

														__newindex = function(self, _Index, Value)
															if PlayerScripts[Index][_Index] ~= nil then
																GSEvent:FireClient(Player, PlayerScripts[Index].Name, Value)
																PlayerScripts[Index][_Index] = Value
															else
																error(_Index .. " is not a valid member of LocalScript \"" .. PlayerScripts[Index].Name .. "\"")
															end
														end
													})
												else
													return PlayerScripts[Index]
												end
											elseif pcall(type, workspace[Index]) then
												return function(self, Name)
													if PlayerScripts[Name] ~= nil then
														return CreateUserdata(PlayerScripts[Name], {
															__index = function(self, Index)
																if PlayerScripts[Name][Index] ~= nil then
																	return PlayerScripts[Name][Index]
																else
																	error(Index .. " is not a valid member of LocalScript \"" .. PlayerScripts[Name].Name .. "\"")
																end
															end,

															__newindex = function(self, Index, Value)
																if PlayerScripts[Name][Index] ~= nil then
																	GSEvent:FireClient(Player, PlayerScripts[Name].Name, Value)
																	PlayerScripts[Name][Index] = Value
																else
																	error(Index .. " is not a valid member of LocalScript \"" .. PlayerScripts[Name].Name .. "\"")
																end
															end
														})
													end
												end
											else
												error(Index .. " is not a valid member of PlayerScripts \"" .. PlayerScripts.Name .. "\"")
											end
										end,

										__newindex = function(self, Index, Value)
											if PlayerScripts[Index] ~= nil then
												GSEvent:FireClient(Player, Index, Value)
												PlayerScripts[Index] = Value
											else
												error(Index .. " is not a valid member of PlayerScripts \"" .. PlayerScripts.Name .. "\"")
											end
										end
									})
								elseif Player[Index] ~= nil then
									if type(Player[Index]) == "function" then
										return function(self, ...)
											if Correct(Index) == "GetMouse" then
												return CreateUserdata(Services[1], {
													__index = function(self, Index)
														local CIndex = Correct(Index)

														if Services[1][CIndex] ~= nil then
															return Services[1][CIndex]
														else
															error(Index .. " is not a valid member of PlayerMouse \"" .. Services[1].Name .. "\"")
														end
													end,

													__newindex = function(self, Index, Value)
														if Index == "Icon" or Correct(Index) == "TargetFilter" then
															GSEvent:FireClient(Player, Index, Value)
															Services[1][Index] = Value
														elseif Services[1][Index] ~= nil then
															Services[1][Index] = Value
														else
															error(Index .. " is not a valid member of PlayerMouse \"" .. Services[1].Name .. "\"")
														end
													end
												})
											else
												return Player[Index](Player, ...)
											end
										end
									else
										return Player[Index]
									end
								else
									return --> Need to avoid errors or you can't check nil values (like .Character)
								end
							end
						})
					elseif Players[Index] ~= nil then
						if type(Players[Index]) == "function" then
							return function(self, ...)
								return Players[Index](Players, ...)
							end
						else
							return Players[Index]
						end
					else
						error(Index .. " is not a valid member of Players \"" .. Players.Name .. "\"")
					end
				end
			})
		elseif ClassName == "UserInputService" then
			return CreateUserdata(UserInputService, {
				__index = function(self, Index)
					local CIndex = Correct(Index)

					if Services[2][CIndex] ~= nil then
						return Services[2][CIndex]
					elseif UserInputService[Index] ~= nil then
						if pcall(type, workspace[CIndex]) then
							return function(self, ...)
								return UserInputService[CIndex](UserInputService, ...)
							end
						elseif type(UserInputService[CIndex]) == "function" then
							if Inputs[CIndex] ~= nil then
								return function(self, ...)
									local InputObject = GSFunction:InvokeClient(Player, CIndex, ...)
									local FakeInputObject = {}

									for _, InputObject in ipairs(InputObject) do
										FakeInputObject[#FakeInputObject + 1] = CreateUserdata(InputObject.Name, {
											__index = function(self, Index)
												local CIndex = Correct(Index)

												if CIndex == "IsModifierKeyDown" then
													return function(self, ModifierKey)
														if ModifierKey then
															local IsModifier = false

															for _, Enum in ipairs(Modifiers) do
																if ModifierKey == Enum then
																	IsModifier = true
																	break
																end
															end

															return IsModifier
														else
															error("Argument 1 missing or nil")
														end
													end
												elseif InputObject[CIndex] ~= nil then
													return InputObject[CIndex]
												else
													error(Index .. " is not a valid member of InputObject \"" .. InputObject.Name .. "\"")
												end
											end,

											__newindex = function(self, Index, Value)
												if InputObject[Index] ~= nil then
													InputObject[Index] = Value
												else
													error(Index .. " is not a valid member of InputObject \"" .. InputObject.Name .. "\"")
												end
											end
										})
									end

									if Index == "GetKeysPressed" or Index == "GetMouseButtonsPressed" or Index == "GetGamepadState" then
										return FakeInputObject[1]
									end

									return FakeInputObject
								end
							else
								return function(self, ...)
									return GSFunction:InvokeClient(Player, CIndex, ...)
								end
							end
						else
							return UserInputService[Index]
						end
					else
						error(Index .. " is not a valid member of UserInputService \"" .. UserInputService.Name .. "\"")
					end
				end
			})
		elseif ClassName == "ContextActionService" then
			--> This service isn't done
			return CreateUserdata(ContextActionService, {
				__index = function(self, Index)
					local CIndex = Correct(Index)

					if Services[3][CIndex] ~= nil then
						return Services[3][CIndex]
					elseif ContextActionService[Index] ~= nil then
						if pcall(type, workspace[CIndex]) then
							return function(self, ...)
								return ContextActionService[CIndex](ContextActionService, ...)
							end
						elseif type(ContextActionService[CIndex]) == "function" then
							return function(self, ...)
								print(...)
								return GSFunction:InvokeClient(Player, CIndex, ...)
							end
						else
							return ContextActionService[Index]
						end
					else
						error(Index .. " is not a valid member of ContextActionService \"" .. ContextActionService.Name .. "\"")
					end
				end
			})
		elseif ClassName == "RunService" then
			return CreateUserdata(RunService, {
				__index = function(self, Index)
					if Correct(Index) == "RenderStepped" then
						return Stepped
					elseif RunService[Index] ~= nil then
						if type(RunService[Index]) == "function" then
							return function(self, ...)
								return RunService[Index](RunService, ...)
							end
						else
							return RunService[Index]
						end
					else
						error(Index .. " is not a valid member of Run Service \"" .. RunService.Name .. "\"")
					end
				end
			})
		end
	end

	Environment.game = CreateUserdata(game, {
		__index = function(self, Index)
			if game[Index] ~= nil then
				if type(game[Index]) == "function" then
					local Index = Correct(Index)

					if Index == "GetService" or Index == "Service" then
						return function(self, Service)
							return GetService(Service) or game:GetService(Service)
						end
					elseif Index == "FindService" then
						return function(self, Service)
							return GetService(Service) or game:FindService(Service)
						end
					else
						return function(self, ...)
							return game[Index](game, ...)
						end
					end
				else
					local CIndex = Correct(Index)

					if pcall(function() game:GetService(CIndex) end) then
						return GetService(CIndex) or game:GetService(CIndex)
					else
						return game[Index]
					end
				end
			else
				error(Index .. " is not a valid member of DataModel \"" .. game.Name .. "\"")
			end
		end
	})

	Environment.LoadLibrary = CreateUserdata("RbxLibrary", {
		__call = function(self, Index) 
			if script.LoadLibrary[Index] ~= nil then
				return require(script.LoadLibrary[Index])
			else
				error(Index .. " is not a valid member of RbxLibrary \"LoadLibrary\"")
			end
		end,

		__index = function(self, Index)
			warn("attempt to index function with '" .. Index .. "'")
		end,

		__newindex = function(self, Index)
			warn("attempt to index function with '" .. Index .. "'")
		end
	})

	--> We will don't need loadstring
	Environment.loadstring = function(...)
		error("loadstring() doenst exists")
	end

	--> Environment.defer = task.defer
	Environment.wait = task.wait
	Environment.delay = task.delay
	Environment.spawn = task.spawn
	Environment.Game = Environment.game
	while not PlayerScripts.Name do
		task.wait()
	end

	return Clock() - Time
end

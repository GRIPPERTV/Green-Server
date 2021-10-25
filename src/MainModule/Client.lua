--!nocheck
--> This script is disabled by default

--> Functions
local function WaitForChild(Parent, Child)
	while not Parent:FindFirstChild(Child) do
		task.wait()
	end

	return Parent[Child]
end

--> Immutable
local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerScripts = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
local GSRemotes = game:GetService("ReplicatedStorage")["GS Remotes"]
local GSEvent = WaitForChild(GSRemotes, "GS Event")
local Inputs = {"GetKeysPressed", "GetMouseButtonsPressed", "GetGamepadState", 
	"GetDeviceAcceleration", "GetDeviceGravity", "GetDeviceRotation"}
local UserInputs = {"TouchPan", "TouchTap", "TouchEnded", "TouchMoved", "TouchSwipe", "TouchPinch",
	"InputBegan", "InputEnded", "JumpRequest", "TouchRotate", "InputChanged", "TouchStarted", "WindowFocused",
	"PointerAction", "TouchLongPress", "TextBoxFocused", "TouchTapInWorld", "GamepadConnected", "UserCFrameChanged",
	"GamepadDisconnected", "WindowFocusReleased", "LastInputTypeChanged", "TextBoxFocusReleased"}

--> Replacement Services
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

--> Wait for all instances appear in PlayerScripts
WaitForChild(PlayerScripts, "BubbleChat")

GSEvent.OnClientEvent:Connect(function(Index, Value)
	if Mouse[Index] ~= nil then
		Mouse[Index] = Value
	elseif PlayerScripts[Index] ~= nil then
		if pcall(function()
				PlayerScripts[Index] = Value
			end) then
			GSEvent:FireServer(2, Index, PlayerScripts[Index])
		else
			GSEvent:FireServer(1, "can't set value")
		end
	else
		GSEvent:FireServer(1, Index .. " is not a valid member of PlayerScripts \"" .. PlayerScripts.Name .. "\"")
	end
end)

--> This just get the LocalScript, not Modules
for Index, LocalScript in ipairs(PlayerScripts:GetChildren()) do
	if LocalScript:IsA("LocalScript") then
		GSEvent:FireServer(2, LocalScript.Name, {
			ClassName = "LocalScript",
			Name = LocalScript.Name,
			Parent = LocalScript.Parent,
			Archivable = LocalScript.Archivable,
			Disabled = LocalScript.Disabled
		})
	end
end

WaitForChild(GSRemotes, "GS Function").OnClientInvoke = function(Index, ...)
	if Inputs[Index] ~= nil then
		local InputObject = UserInputService[Index](UserInputService, ...)
		local FakeInputObject = {}

		if Index == "GetKeysPressed" or Index == "GetMouseButtonsPressed" or Index == "GetGamepadState" then
			for Index, InputObject in ipairs(InputObject) do
				FakeInputObject[#FakeInputObject + 1] = {
					Name = InputObject.Name,
					Delta = InputObject.Delta,
					KeyCode = InputObject.KeyCode,
					Position = InputObject.Position,
					UserInputState = InputObject.UserInputState,
					UserInputType = InputObject.UserInputType
				}
			end
		else
			FakeInputObject[1] = {
				Name = InputObject.Name,
				Delta = InputObject.Delta,
				KeyCode = InputObject.KeyCode,
				Position = InputObject.Position,
				UserInputState = InputObject.UserInputState,
				UserInputType = InputObject.UserInputType
			}
		end

		return FakeInputObject
	else
		return UserInputService[Index](UserInputService, ...)
	end
end

for _, Signal in ipairs({"Idle", "KeyUp", "KeyDown", "Button1Up", "Button2Up",
	"Button1Down", "Button2Down", "WheelForward", "WheelBackward"}) do
	Mouse[Signal]:Connect(function(...)
		GSEvent:FireServer(3, 1, Signal, ...)
	end)
end

if UserInputService.GyroscopeEnabled then
	UserInputs[#UserInputs + 1] = "DeviceGravityChanged"
end

if UserInputService.AccelerometerEnabled then
	UserInputs[#UserInputs + 1] = "DeviceRotationChanged"
	UserInputs[#UserInputs + 1] = "DeviceAccelerationChanged"
end

for _, Signal in ipairs(UserInputs) do
	UserInputService[Signal]:Connect(function(...)
		GSEvent:FireServer(3, 2, Signal, ...)
	end)
end

for _, Signal in ipairs({"LocalToolEquipped", "LocalToolUnequipped"}) do
	ContextActionService[Signal]:Connect(function(...)
		GSEvent:FireServer(3, 3, Signal, ...)
	end)
end

UserInputService.Changed:Connect(function(Property)
	if Property == "ModalEnabled" or Property == "MouseBehavior" or Property == "MouseIconEnabled" then
		GSEvent:FireServer(3, 2, false, {[Property] = UserInputService[Property]})
	end
end)

Mouse.Changed:Connect(function(Property)
	GSEvent:FireServer(3, 1, false, {[Property] = Mouse[Property]})
end)

Mouse.Move:Connect(function(...)
	GSEvent:FireServer(3, 1, "Move", ...)
	GSEvent:FireServer(3, 1, false, {
		X = Mouse.X,
		Y = Mouse.Y,
		Hit = Mouse.Hit,
		Origin = Mouse.Origin,
		Target = Mouse.Target,
		UnitRay = Mouse.UnitRay
	})
end)

GSEvent:FireServer(3, 1, false, {
	X = Mouse.X,
	Y = Mouse.Y,
	Hit = Mouse.Hit,
	Name = Mouse.Name,
	Icon = Mouse.Icon,
	Origin = Mouse.Origin,
	Target = Mouse.Target,
	UnitRay = Mouse.UnitRay,
	ViewSizeX = Mouse.ViewSizeX,
	ViewSizeY = Mouse.ViewSizeY,
	TargetFilter = Mouse.TargetFilter,
	TargetSurface = Mouse.TargetSurface
})

GSEvent:FireServer(3, 2, false, {
	VREnabled = UserInputService.VREnabled,
	TouchEnabled = UserInputService.TouchEnabled,
	ModalEnabled = UserInputService.ModalEnabled,
	MouseEnabled = UserInputService.MouseEnabled,
	MouseBehavior = UserInputService.MouseBehavior,
	GamepadEnabled = UserInputService.GamepadEnabled,
	KeyboardEnabled = UserInputService.KeyboardEnabled,
	GyroscopeEnabled = UserInputService.GyroscopeEnabled,
	AccelerometerEnabled = UserInputService.AccelerometerEnabled,
	OnScreenKeyboardSize = UserInputService.OnScreenKeyboardSize,
	OnScreenKeyboardVisible = UserInputService.OnScreenKeyboardVisible,
	OnScreenKeyboardPosition = UserInputService.OnScreenKeyboardPosition
})

GSEvent:FireServer(2, "Name", PlayerScripts.Name)

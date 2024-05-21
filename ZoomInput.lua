local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Player = game:GetService("Players").LocalPlayer
local mouse = Player:GetMouse()
local VirtualCamPoint = script.Parent:WaitForChild("CamDriver"):WaitForChild("VirtualCamPoint")
local cameraDriver = script.Parent.CamDriver
local CamModule = require(script.Parent.CamModule)
local updateCamEvent = cameraDriver:WaitForChild("UpdateLastState"):: BindableEvent
-- (Event created via script)

local camera = workspace.CurrentCamera
local scrollAmount = 8

function onMouseForwards()
	-- Zoom out
	if VirtualCamPoint.Position.Y < script:GetAttribute("MinZoomOut") then
		return
	end
	local mouseHit = mouse.Hit.Position
	local diff = (VirtualCamPoint.Position - mouseHit) / scrollAmount
	VirtualCamPoint.Position -= diff
	updateCamEvent:Fire(Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
end

function onMouseBackwards()
	-- Zoom in
	if VirtualCamPoint.Position.Y > script:GetAttribute("MinZoomIn") then
		return
	end
	local mouseHit = mouse.Hit.Position
	local diff = (VirtualCamPoint.Position - mouseHit) / scrollAmount
	VirtualCamPoint.Position += diff
	updateCamEvent:Fire(Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
end

local lastTouchScale = nil
local initialPoint = nil

local function resetDriver()
	task.spawn(function()
		CamModule.eventsEnabled = false
		cameraDriver:SetAttribute("LastCamState", Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
		cameraDriver:SetAttribute("Active", true)
		CamModule.eventsEnabled = true
	end)
end

local zoomSpeed = 87
local function zoomGesture(touchPositions, scale, velocity, state)
	if state == Enum.UserInputState.Begin then
		CamModule.eventsEnabled = false
		initialPoint = VirtualCamPoint.CFrame
	end
	if state == Enum.UserInputState.Change then
		CamModule.eventsEnabled = false
		cameraDriver:SetAttribute("Active", false)
		local difference = scale - lastTouchScale
		local direction = VirtualCamPoint.CFrame.lookVector
		VirtualCamPoint.CFrame = VirtualCamPoint.CFrame + VirtualCamPoint.CFrame.LookVector * zoomSpeed * difference
		camera.CFrame = VirtualCamPoint.CFrame
		cameraDriver:SetAttribute("LastCamState", Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
	elseif state == Enum.UserInputState.End then
		resetDriver()
	end
	lastTouchScale = scale
	cameraDriver:SetAttribute("LastCamState", Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
	resetDriver()
end

local count = 0

local function touchCountChange()
	if count == 2 then
		initialPoint = VirtualCamPoint.CFrame
		CamModule.eventsEnabled = false
		cameraDriver:SetAttribute("Active", false)
		cameraDriver:SetAttribute("LastCamState", Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
	end
end

local function touchInput()
	count += 1
	touchCountChange()
end

local function touchEnd()
	count -= 1
	touchCountChange()
	cameraDriver:SetAttribute("LastCamState", Vector2.new(VirtualCamPoint.Position.X, VirtualCamPoint.Position.Z))
end

Input.TouchPinch:Connect(zoomGesture)
Input.TouchStarted:Connect(touchInput)
Input.TouchEnded:Connect(touchEnd)
mouse.WheelForward:Connect(onMouseForwards)
mouse.WheelBackward:Connect(onMouseBackwards)

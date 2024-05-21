--[[
    Flow:
    1. Listen for "CameraActive" changes.
    2. Update camera position on each render step if isCameraActive is true.
    3. Process drag events to update VirtualCamPoint.
    4. Update final X and Z positions on drag end.
    5. Set up input signals.
--]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Input = game:GetService("UserInputService")
local camModule = require(script.Parent.CamModule)

local camera = workspace.CurrentCamera
local VirtualCamPoint = script:WaitForChild("VirtualCamPoint")
local KineticMovement = script.Parent.KineticMovement

if not Input.TouchEnabled then
	script:SetAttribute("LastCamState", Vector2.new(180, 180))
	-- patch for desktop.
end

local UpdateLastState = Instance.new("BindableEvent")
UpdateLastState.Name = "UpdateLastState"
UpdateLastState.Parent = script

local movementEndedEvent = nil
if KineticMovement.Enabled then
	movementEndedEvent = KineticMovement:WaitForChild("MovementEnded")
end

local lastXCamState = nil
local lastZCamState = nil

local player = game:GetService("Players").LocalPlayer
local speed = script:GetAttribute("CameraSpeed")

local function onCameraType(reaction)
	local tickSignal: RBXScriptConnection
	local function cameraReady()
		if camera then
			camera.CameraType = Enum.CameraType.Scriptable
			return true
		end
	end
	tickSignal = RunService.RenderStepped:Connect(function()
		if cameraReady() then
			tickSignal:Disconnect()
			reaction()
		end
	end)
end

local touchEnabled = false

local function runActionPhase()
	script:SetAttribute("CameraReady", true) -- Report that camera init is done.
	RunService.RenderStepped:Connect(function()
		if script:GetAttribute("Active") == true then
			camera.CFrame = CFrame.new(VirtualCamPoint.CFrame.Position) * CFrame.Angles(math.rad(VirtualCamPoint.Orientation.X), 0, 0)
		end
	end)
	speed = script:GetAttribute("CameraSpeed")

	local scalingFactorX = -speed
	local scalingFactorZ = -speed

	if UserInputService.TouchEnabled then
		speed = 0.5
		touchEnabled = true
	end
	
	local function setSpeed(speed)
		script:SetAttribute("CameraSpeed", speed)
	end
	local function onDragEvent(initial: Vector2, current: Vector2)
		local camY = math.floor(VirtualCamPoint.Position.Y)
		if camY > 85 and camY < 100 then
			setSpeed(0.6)
		elseif camY > 115 then
			setSpeed(1)
		else
			setSpeed(0.46)
		end
		
		speed = script:GetAttribute("CameraSpeed")
		local distanceX = (initial.X - current.X) * -speed
		local distanceZ = (initial.Y - current.Y) * -speed
		
		local newX = (lastXCamState or 0) - distanceX / 2
		local newZ = (lastZCamState or 0) - distanceZ / 2
		local camState = script:GetAttribute("LastCamState")
		if not lastXCamState then
			newX = VirtualCamPoint.CFrame.Position.X
			newZ = VirtualCamPoint.CFrame.Position.Z
			
			-- Last cam state.
			if not (camState == Vector2.zero) then
				lastXCamState = camState.X
				lastZCamState = camState.Y
			else
				-- No last cam state.
				lastXCamState = VirtualCamPoint.Position.X
				lastZCamState = VirtualCamPoint.Position.Z
			end
		end

		local positionCFrame = CFrame.new(Vector3.new(newX, VirtualCamPoint.CFrame.Position.Y, newZ))
		local rotationCFrame = CFrame.Angles(math.rad(VirtualCamPoint.Orientation.X), 0, 0)
		local touches = camModule.touchCount
		if touches >= 2 then
			return
		end
		if not script:GetAttribute("Active") then
			return
		end
		VirtualCamPoint.CFrame = positionCFrame * rotationCFrame
	end

	local function onDragEnded()
		lastXCamState = VirtualCamPoint.CFrame.Position.X
		lastZCamState = VirtualCamPoint.CFrame.Position.Z
		script:SetAttribute("LastCamState", Vector2.new(lastXCamState, lastZCamState))
	end

	camModule.DragMove.Event:Connect(onDragEvent)
	if KineticMovement.Enabled then
		movementEndedEvent.Event:Connect(onDragEnded)
	else
		camModule.DragEnded.Event:Connect(onDragEnded)
	end
	camModule:handleUserInputs()
end

local function onUpdateLastState(new: Vector2)
	if new then		
		lastXCamState = new.X
		lastZCamState = new.Y
	end
end

UpdateLastState.Event:Connect(onUpdateLastState)
onCameraType(runActionPhase)

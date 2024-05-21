local module = {
	initialPosition = nil,
	eventsEnabled = true,
	touchCount = 0
}

local UserInputService = game:GetService("UserInputService")
local dragMoveSignal = Instance.new("BindableEvent")
local dragEndedEventSignal = Instance.new("BindableEvent")
local dragStartedSignal = Instance.new("BindableEvent")

local CamDriver = script.Parent.CamDriver

module.DragMove = dragMoveSignal
module.DragEnded = dragEndedEventSignal
module.DragStarted = dragStartedSignal

function module:handleUserInputs()
	local heldState = false
	local inputBeginThrottle = false
	local beginThrottleDelay = 0.2
	
	local function onInputBegin(input: InputObject)
		if not module.eventsEnabled then
			return
		end
		if not CamDriver:GetAttribute("Active") then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or Enum.UserInputType.Touch then
			if not inputBeginThrottle then
				inputBeginThrottle = true
				heldState = true
				module.initialPosition = Vector2.new(input.Position.X, input.Position.Y)
				task.wait(beginThrottleDelay)
				dragStartedSignal:Fire()
				inputBeginThrottle = false
			end
		end
	end

	local throttleDelay = 0.16
	local function onInputChange(input: InputObject)
		if not module.eventsEnabled then
			return
		end
		if not CamDriver:GetAttribute("Active") then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch and heldState == true then
			-- If input is held down, fire event with initial pos & current to move cam.
			if module.initialPosition then
				dragMoveSignal:Fire(module.initialPosition, Vector2.new(input.Position.X, input.Position.Y))
			end
			task.wait(throttleDelay)
		end
	end

	local function onInputEnd(input: InputObject)
		if not module.eventsEnabled then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			heldState = false
			module.initialPosition = nil
			dragEndedEventSignal:Fire()
		end
	end
	
	local function touchStart()
		module.touchCount += 1
	end
	
	local function touchEnd()
		module.touchCount -= 1
	end
	
	UserInputService.TouchStarted:Connect(touchStart)
	UserInputService.TouchEnded:Connect(touchEnd)
	
	UserInputService.InputBegan:Connect(onInputBegin)
	UserInputService.InputChanged:Connect(onInputChange)
	UserInputService.InputEnded:Connect(onInputEnd)
end

function module.setActive(state)
	if not state then
		CamDriver:SetAttribute("LastCamState", Vector2.new(CamDriver.VirtualCamPoint.Position.X, CamDriver.VirtualCamPoint.Position.Z))
		task.wait()
		CamDriver.Enabled = false
	else
		CamDriver.Enabled = true
	end
end

return module

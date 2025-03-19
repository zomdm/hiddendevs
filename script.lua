--[[
	Dragging Objects Script
	Use W, A, S, D, Q, E to rotate; Z to attach.
	You can attach a part only to parts from the AttParts folder.
]]
-- Services --
local runService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Variables --
local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local mouse = player:GetMouse()
-- Function to set the network owner. When it is set to the player, the system will lag much less.
local setNetworkOwner = game.ReplicatedStorage.SetNetworkOwner
-- Folder containing the parts to which the target part can be attached
local attParts = game.Workspace.AttParts

local maxDistance = 30
local minDistance = 2
local rotSpeed = 100 -- Degrees per second
local basicWalkSpeed = 16

local dragging = false
local rotating = false
-- Instances related to the dragged part
local distance = 0
local target
local con
local hitPart
local highlight
local ori
local vis
local gui
local att0
-- The part will rotate along the X, Y, and Z axes by a certain number of degrees per 1/rotSpeed seconds when the corresponding button is pressed.
local angles = 
	{
		[Enum.KeyCode.W] = CFrame.Angles(math.rad(1), 0, 0),
		[Enum.KeyCode.S] = CFrame.Angles(math.rad(-1), 0, 0),
		[Enum.KeyCode.A] = CFrame.Angles(0, math.rad(1), 0),
		[Enum.KeyCode.D] = CFrame.Angles(0, math.rad(-1), 0),
		[Enum.KeyCode.E] = CFrame.Angles(0, 0, math.rad(1)),
		[Enum.KeyCode.Q] = CFrame.Angles(0, 0, math.rad(-1))
	}
local touched = {}

-- Functions --
-- Weld two parts, they'll stay in the same relative position/orientation to each other.
local function Weld(p0, p1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
	return weld
end
-- Function to stop dragging the target part.
local function stopDragging()
	setNetworkOwner:FireServer(target)
	-- Delete the parts created by the target part, if they exist, and disconnect the connection.
	if con then 
		con:Disconnect() 
	end
	mouse.TargetFilter = nil
	if hitPart then 
		hitPart:Destroy() 
	end
	if att0 then 
		att0:Destroy() 
	end
	ori = nil
	distance = 0
	if vis then
		vis:Destroy()
	end
	if gui then
		gui:Destroy()
	end
	if highlight then
		highlight:Destroy()
	end
	-- Set the "Draggable" attribute to true so that any player can move the part.
	target:SetAttribute("Draggable", true)
	target = nil
end

mouse.Button1Down:Connect(function() -- Start or stop dragging.
	local tar = mouse.Target
	local hit = mouse.Hit

	if dragging then
		-- Delete the parts created by the target part, if they exist, and disconnect the connection.
		stopDragging()
	else
		if not tar or not tar:GetAttribute("Draggable") or (tar:GetAttribute("Dragging") and tar:GetAttribute("Dragging")) then -- If the part can't be dragged, exit the function
			return 
		end

		distance = (tar.Position - char.HumanoidRootPart.Position).Magnitude
		if distance > maxDistance then 
			return 
		end
		target = tar
		target:SetAttribute("Draggable", true)
		setNetworkOwner:FireServer(tar)
		distance = math.floor(distance)
		target.Anchored = false
		ori = CFrame.Angles(tar.CFrame:ToOrientation())
		-- Part towards which the target will move.
		hitPart = Instance.new("Part")
		hitPart.Size = Vector3.new(0.1,0.1,0.1)
		hitPart.Transparency = 1
		hitPart.CanCollide = false
		hitPart.CanQuery = false
		hitPart.CanTouch = false
		hitPart.Anchored = true
		hitPart.CFrame = CFrame.new(char.Head.Position + (mouse.Hit.Position - char.Head.Position).Unit * distance) * ori
		hitPart.Parent = workspace

		-- Create attachments for the dragged object and hitPart.
		att0 = Instance.new("Attachment")
		att0.CFrame = tar.CFrame:Inverse() * hit
		att0.Parent = tar

		local att1 = Instance.new("Attachment")
		att1.CFrame = CFrame.new(0, 0, 0)
		att1.Parent = hitPart

		-- Align position and orientation: the part will move towards alignPos and rotate towards alignOrientation.
		local alignPos = Instance.new("AlignPosition")
		alignPos.Attachment0 = att0
		alignPos.Attachment1 = att1
		alignPos.Responsiveness = 20
		alignPos.MaxForce = 30000
		alignPos.Parent = hitPart
		mouse.TargetFilter = tar

		local alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Attachment1 = att1 	
		alignOrientation.Attachment0 = att0
		alignOrientation.CFrame = CFrame.new(0, 0, 0)
		alignOrientation.Parent = hitPart

		-- Visualization
		-- Create particles at the initial hit CFrame.
		local particles = game.ReplicatedStorage.ParticleEmitter:Clone()
		particles.Parent = att0
		-- Create a GUI that displays the instructions on how to use the system.
		gui = game.ReplicatedStorage.DragGui:Clone()
		gui.Parent = playerGui
		-- Create a dot at the initial hit CFrame.
		vis = Instance.new("Part")
		vis.Size = Vector3.new(0.3, 0.3, 0.3)
		vis.CanCollide = false
		vis.CanTouch = false
		vis.CanQuery = false
		vis.CFrame = hit
		vis.Color = Color3.new(0, 0, 1)
		vis.Massless = true
		vis.Shape = Enum.PartType.Ball
		vis.Parent = tar
		Weld(vis, tar)
		-- Highlight the part if it can be welded.
		highlight = Instance.new("Highlight")
		highlight.Parent = target
		highlight.Adornee = target
		highlight.FillColor = Color3.new(0.2, 0, 1)
		-- At every render step, update the goal CFrame to which the target part will move.
		con = runService.RenderStepped:Connect(function()
			-- If it touches any allowed part, highlight the target part.
			if next(touched) ~= nil then
				highlight.Enabled = true
			else
				highlight.Enabled = false
			end
			-- The CFrame the part will move to equals the mouse position at a distance of {distance} studs with orientation {ori}.
			hitPart.CFrame = CFrame.new(char.Head.Position + (mouse.Hit.Position - char.Head.Position).Unit * distance) * ori
		end)
	end
	dragging = not dragging
end)

UIS.InputBegan:Connect(function(input, processed) -- Rotating objects.
	if processed then
		return
	end
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) and dragging and angles[input.KeyCode] then  -- If the player is pressing left Shift while dragging the part and presses one of the rotation buttons.
		while dragging and rotating and UIS:IsKeyDown(input.KeyCode) do
			hum.WalkSpeed = 0 -- Set the player's WalkSpeed to zero.
			ori *= angles[input.KeyCode] -- Rotate the part by the angle corresponding to the key.
			task.wait(1 / rotSpeed) -- Repeat every 1/rotSpeed seconds.
		end	
		task.wait() -- Allow the player to move when they stop rotating.
		if not rotating or not dragging then
			hum.WalkSpeed = basicWalkSpeed
		end
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then -- The player starts rotating.
		rotating = true
	end
	if input.KeyCode == Enum.KeyCode.Z and dragging and touched[target] then -- Anchor the part if the player presses Z while rotating.
		target.Anchored = true
		stopDragging()
		dragging = false
	end
end)

for _, attPart in attParts:GetChildren() do
	attPart.Touched:Connect(function(p) -- Increment the count of draggable parts touching parts from the AttParts folder.
		if not p:GetAttribute("Draggable") then
			return
		end
		if not touched[p] then -- It hasn't touched the part before.
			touched[p] = 0
		end
		touched[p] += 1
	end)

	attPart.TouchEnded:Connect(function(p) -- Decrement the count of draggable parts touching parts from the AttParts folder.
		if not p:GetAttribute("Draggable") then
			return
		end
		touched[p] -= 1
		if touched[p] == 0 then -- If no parts from the AttParts folder are touching the part, remove it from the {touched} dictionary.
			touched[p] = nil
		end
	end)
end

UIS.InputEnded:Connect(function(input) -- Stop rotating.
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if rotating then
			hum.WalkSpeed = basicWalkSpeed
		end
		rotating = false
	end
end)
-- Increase or decrease the distance from the object.
mouse.WheelForward:Connect(function()
	if dragging then -- Increase the distance, but do not exceed the maximum value.
		distance = math.min(maxDistance, distance + 1)
	end
end)

mouse.WheelBackward:Connect(function()
	if dragging then -- Decrease the distance, but do not go below the minimum value.
		distance = math.max(minDistance, distance - 1)
	end
end)

--[[
	Dragging objects script
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
local setNetworkOwner = game.ReplicatedStorage.SetNetworkOwner
local getNetworkOwner = game.ReplicatedStorage.GetNetworkOwner

local maxDistance = 30
local minDistance = 2
local rotSpeed = 100 -- Degrees per second
local basicWalkSpeed = 16

local dragging = false
local rotating = false
local distance = 0
local target
local con
local hitPart
local ori
local vis
local gui
local att0

local angles = 
{
	[Enum.KeyCode.W] = CFrame.Angles(math.rad(1), 0, 0),
	[Enum.KeyCode.S] = CFrame.Angles(math.rad(-1), 0, 0),
	[Enum.KeyCode.A] = CFrame.Angles(0, math.rad(1), 0),
	[Enum.KeyCode.D] = CFrame.Angles(0, math.rad(-1), 0),
	[Enum.KeyCode.E] = CFrame.Angles(0, 0, math.rad(1)),
	[Enum.KeyCode.Q] = CFrame.Angles(0, 0, math.rad(-1))
}

-- Functions --

local function Weld(p0, p1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Name = "hitWeld"
	weld.Parent = p0
	return weld
end

mouse.Button1Down:Connect(function() -- Start / stop dragging
	local tar = mouse.Target
	local hit = mouse.Hit
	
	if dragging then
		-- Delete all created objects
		setNetworkOwner:FireServer(target)
		if con then 
			con:Disconnect() 
		end
		mouse.TargetFilter = nil
		if hitPart then 
			hitPart:Destroy() 
		end
		target = nil
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
	else
		if not tar or tar.Anchored or not tar:GetAttribute("Draggable") then 
			return 
		end
		setNetworkOwner:FireServer(tar)
		
		target = tar
		distance = (tar.Position - char.HumanoidRootPart.Position).Magnitude
		if distance > maxDistance then 
			return 
		end
		distance = math.floor(distance)
		ori = CFrame.Angles(tar.CFrame:ToOrientation())
		-- Part that the target will move towards
		hitPart = Instance.new("Part")
		hitPart.Size = Vector3.new(0.1,0.1,0.1)
		hitPart.Transparency = 1
		hitPart.CanCollide = false
		hitPart.CanQuery = false
		hitPart.CanTouch = false
		hitPart.Anchored = true
		hitPart.CFrame = CFrame.new(char.Head.Position + (mouse.Hit.Position - char.Head.Position).Unit * distance) * ori
		hitPart.Parent = workspace
		
		-- Create attachment for the dragged object and hitPart
		att0 = Instance.new("Attachment")
		att0.CFrame = tar.CFrame:Inverse() * hit
		att0.Parent = tar
		
		local att1 = Instance.new("Attachment")
		att1.CFrame = CFrame.new(0, 0, 0)
		att1.Parent = hitPart
		
		-- Align position and orientation
		local alignPos = Instance.new("AlignPosition")
		alignPos.Attachment0 = att0
		alignPos.Attachment1 = att1
		alignPos.Responsiveness = 20
		alignPos.MaxForce = 30000
		alignPos.Parent = hitPart
		mouse.TargetFilter = tar

		local alighOrientation = Instance.new("AlignOrientation")
		alighOrientation.Attachment1 = att1 	
		alighOrientation.Attachment0 = att0
		alighOrientation.CFrame = CFrame.new(0, 0, 0)
		alighOrientation.Parent = hitPart
		
		-- Visualisation
		local particles = Instance.new("ParticleEmitter")
		particles.LightEmission = 0.4
		particles.LightInfluence = 1
		particles.Orientation = Enum.ParticleOrientation.FacingCamera
		particles.TimeScale = 0.3
		particles.ZOffset = -1
		particles.Size = NumberSequence.new(
		{
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(1, 0)
		}
		)
		particles.Transparency = NumberSequence.new(
		{
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0.4)
		}
		)
		particles.Lifetime = NumberRange.new(0.1, 0.1)
		particles.Rotation = NumberRange.new(45, 180)
		particles.Speed = NumberRange.new(0.1, 0.1)
		particles.SpreadAngle = Vector2.new(180, 360)
		particles.Color = ColorSequence.new(
		{
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 1))
		}
		)
		particles.Texture = "rbxassetid://6706375454"
		particles.Rate = 70
		particles.Enabled = true
		particles.Parent = att0
		
		gui = Instance.new("ScreenGui")
		gui.Name = "DragGui"
		
		local text1 = Instance.new("TextLabel")
		text1.Text = "LShift + WASD to rotate"
		text1.BackgroundTransparency = 1
		text1.TextScaled = true
		text1.Size = UDim2.new(0.1, 0, 0.1, 0)
		text1.Position = UDim2.new(0.9, 0, 0.9, 0)
		text1.TextColor3 = Color3.new()
		text1.Parent = gui
		
		local text2 = text1:Clone()
		text2.Text = "Left click to stop dragging"
		text2.Position =  UDim2.new(0.9, 0, 0.8, 0)
		text2.Parent = gui
		gui.Parent = playerGui
		
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
		local weld = Weld(vis, tar)
		
		con = runService.RenderStepped:Connect(function()
			hitPart.CFrame = CFrame.new(char.Head.Position + (mouse.Hit.Position - char.Head.Position).Unit * distance) * ori
		end)
	end
	dragging = not dragging
end)

UIS.InputBegan:Connect(function(input) -- Rotating objects
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) and dragging and angles[input.KeyCode] then 
		while dragging and rotating and UIS:IsKeyDown(input.KeyCode) do
			hum.WalkSpeed = 0
			ori *= angles[input.KeyCode]
			task.wait(1 / rotSpeed)
		end
		task.wait()
		hum.WalkSpeed = basicWalkSpeed
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		rotating = true
	end
end)

UIS.InputEnded:Connect(function(input) -- Stop rotating
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if rotating then
			hum.WalkSpeed = basicWalkSpeed
		end
		rotating = false
	end
end)
-- Decreasing / increasing the distance from the object
mouse.WheelForward:Connect(function()
	if dragging then
		distance = math.min(maxDistance, distance + 1)
	end
end)

mouse.WheelBackward:Connect(function()
	if dragging then
		distance = math.max(minDistance, distance - 1)
	end
end)

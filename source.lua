--// File: NebulaUI.lua
--// A single-module animated UI library for Roblox (Luau)
--// Features: tabs, sections, button, toggle, slider, dropdown, textbox, label, checkbox, frames, key system, blur, themeable
--// API (Rayfield-like):
--// local ui = NebulaUI.CreateWindow({Name = "My Hub", Theme = "DarkGlass", Blur = true, KeySystem = {Required = true, Keys = {"ABC-123"}, SaveKey = false}})
--// local Tab1 = ui:CreateTab({Name = "Main", Icon = "rbxassetid://0"})
--// local Section = Tab1:CreateSection("Controls")
--// Section:Button({Text="Click Me", Callback=function() end})
--// Section:Toggle({Text="God Mode", Default=false, Callback=function(state) end})
--// Section:Slider({Text="WalkSpeed", Min=8, Max=32, Default=16, Step=1, Callback=function(v) end})
--// Section:Dropdown({Text="Team", Options={"Red","Blue","Green"}, Default="Red", Callback=function(option) end})
--// Section:TextBox({Text="Enter name", Placeholder="Player", ClearOnFocus=false, Callback=function(text) end})
--// Section:Label({Text="Status: Ready"})
--// Section:CheckBox({Text="Enable Particles", Default=false, Callback=function(state) end})
--// ui:Notify("Saved!", 2)
--// ui:SetKeySystem({Required=true, Keys={"NEW-KEY"}}) -- update at runtime

local NebulaUI = {}
NebulaUI.__index = NebulaUI

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Util
local function new(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			inst[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

local function tween(obj, info, goals)
	local t = TweenService:Create(obj, info, goals)
	t:Play()
	return t
end

local function springTransparency(guiObject)
	-- cute pop-in effect
	guiObject.Visible = true
	guiObject.BackgroundTransparency = 1
	tween(guiObject, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.15})
end

local function addBlur()
	local blur = Lighting:FindFirstChild("NebulaBlur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Size = 0
		blur.Name = "NebulaBlur"
		blur.Parent = Lighting
	end
	tween(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = 18})
	return blur
end

local function removeBlur()
	local blur = Lighting:FindFirstChild("NebulaBlur")
	if blur then
		tween(blur, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = 0}).Completed:Connect(function()
			blur:Destroy()
		end)
	end
end

--// Theme
local Themes = {
	DarkGlass = {
		Base = Color3.fromRGB(10, 10, 12),
		Accent = Color3.fromRGB(120, 180, 255),
		Text = Color3.fromRGB(235, 239, 255),
		Subtle = Color3.fromRGB(120, 120, 130),
		Success = Color3.fromRGB(80, 220, 160),
		Danger = Color3.fromRGB(255, 95, 95),
		Stroke = Color3.fromRGB(255, 255, 255),
		Transparency = 0.15,
		StrokeTransparency = 0.85,
	}
}

--// Mini Signal
local function Signal()
	local bind = Instance.new("BindableEvent")
	return {
		Fire = function(_, ...)
			bind:Fire(...)
		end,
		Connect = function(_, fn)
			return bind.Event:Connect(fn)
		end
	}
end

--// Dragging helper
local function makeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging = false
	local dragStart, startPos
	local conn1, conn2, conn3

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			conn2 = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn2 then conn2:Disconnect() end
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			conn1 = RunService.RenderStepped:Connect(function()
				if dragging then update(input) else conn1:Disconnect() end
			end)
		end
	end)
end

--// Core constructors
function NebulaUI.CreateWindow(cfg)
	cfg = cfg or {}
	local theme = Themes[cfg.Theme or "DarkGlass"]

	local screen = new("ScreenGui", {
		Name = "NebulaUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		new("Folder", {Name = "_Mount"})
	})
	screen.Parent = PlayerGui

	if cfg.Blur then addBlur() end

	-- Root window
	local Window = new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0, 0),
		Size = UDim2.fromOffset(680, 420),
		Position = UDim2.fromOffset(60, 60),
		BackgroundColor3 = theme.Base,
		BackgroundTransparency = theme.Transparency,
	}, {
		new("UICorner", {CornerRadius = UDim.new(0, 16)}),
		new("UIStroke", {Color = theme.Stroke, Transparency = theme.StrokeTransparency, Thickness = 1}),
		new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(160,160,180)) , Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.94), NumberSequenceKeypoint.new(1,1)})}),
		new("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,44), BackgroundTransparency=1}),
		new("Frame", {Name="Nav", Size=UDim2.new(0, 180, 1, -44), Position = UDim2.fromOffset(0,44), BackgroundTransparency=1}),
		new("Frame", {Name="Content", Size=UDim2.new(1,-180,1,-44), Position = UDim2.new(0,180,0,44), BackgroundTransparency=1})
	})
	Window.Parent = screen._Mount

	local Title = new("TextLabel", {
		Parent = Window.TopBar,
		Text = tostring(cfg.Name or "Nebula UI"),
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = theme.Text,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(400, 28),
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local Close = new("TextButton", {
		Parent = Window.TopBar,
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = theme.Subtle,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -36, 0, 8)
	})

	local Min = new("TextButton", {
		Parent = Window.TopBar,
		Text = "–",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = theme.Subtle,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -72, 0, 8)
	})

	makeDraggable(Window, Window.TopBar)

	local NavList = new("UIListLayout", {
		Parent = Window.Nav,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	local ContentPages = new("Folder", {Parent = Window.Content, Name = "Pages"})

	-- Animations for appear
	springTransparency(Window)

	-- Close/Min behavior
	Close.MouseButton1Click:Connect(function()
		removeBlur()
		screen:Destroy()
	end)
	Min.MouseButton1Click:Connect(function()
		local goal = Window.Position.Y.Offset < 0 and UDim2.fromOffset(60, 60) or UDim2.fromOffset(60, -Window.AbsoluteSize.Y-16)
		tween(Window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = goal})
	end)

	-- Key System
	local keyCfg = cfg.KeySystem or {Required=false}
	local function showKeyPrompt()
		local overlay = new("Frame", {
			Parent = screen,
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.35,
			Size = UDim2.fromScale(1,1),
			ZIndex = 9999,
			Visible = true,
			Name = "KeyOverlay"
		}, {
			new("TextLabel", {Name="CardTitle", Text="Enter Key", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=theme.Text, BackgroundTransparency=1, Size=UDim2.fromOffset(240, 24), Position=UDim2.fromScale(0.5,0.5)}),
		})

		local card = new("Frame", {
			Parent = overlay,
			Size = UDim2.fromOffset(320, 180),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = theme.Base,
			BackgroundTransparency = theme.Transparency,
			Name = "KeyCard",
			ZIndex = 10000
		}, {
			new("UICorner", {CornerRadius = UDim.new(0, 12)}),
			new("UIStroke", {Transparency = theme.StrokeTransparency, Color = theme.Stroke}),
		})

		local keyBox = new("TextBox", {
			Parent = card,
			PlaceholderText = "Paste key here",
			Text = "",
			ClearTextOnFocus = false,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextColor3 = theme.Text,
			BackgroundColor3 = theme.Base,
			BackgroundTransparency = 0.2,
			Size = UDim2.new(1, -32, 0, 36),
			Position = UDim2.fromOffset(16, 24)
		}, {
			new("UICorner", {CornerRadius = UDim.new(0, 8)}),
			new("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)}),
		})

		local submit = new("TextButton", {
			Parent = card,
			Text = "Unlock",
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = theme.Text,
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.15,
			Size = UDim2.fromOffset(120, 36),
			Position = UDim2.new(1, -136, 1, -52)
		}, {
			new("UICorner", {CornerRadius = UDim.new(0, 8)})
		})

		local status = new("TextLabel", {
			Parent = card,
			Text = "",
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextColor3 = theme.Subtle,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 0, 20),
			Position = UDim2.new(0, 16, 1, -24),
			TextXAlignment = Enum.TextXAlignment.Left
		})

		springTransparency(card)

		local function tryUnlock()
			local input = keyBox.Text
			for _, k in ipairs(keyCfg.Keys or {}) do
				if input == k then
					status.Text = "Unlocked ✅"
					tween(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 1}).Completed:Connect(function()
						overlay:Destroy()
					end)
					return true
				end
			end
			status.Text = "Invalid key"
			return false
		end

		submit.MouseButton1Click:Connect(tryUnlock)
		keyBox.FocusLost:Connect(function(enter)
			if enter then tryUnlock() end
		end)
	end

	if keyCfg.Required then showKeyPrompt() end

	-- Public window object
	local api = setmetatable({
		ScreenGui = screen,
		Window = Window,
		Theme = theme,
		_OnTabSwitched = Signal(),
		_Tabs = {},
		Notify = function(self, text, duration)
			duration = duration or 2
			local toast = new("TextLabel", {
				Parent = self.Window,
				Text = tostring(text),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextColor3 = theme.Text,
				BackgroundColor3 = theme.Base,
				BackgroundTransparency = theme.Transparency,
				AnchorPoint = Vector2.new(1,1),
				Position = UDim2.new(1,-12,1,-12),
				Size = UDim2.fromOffset(260, 32),
				ZIndex = 100
			}, {
				new("UICorner", {CornerRadius = UDim.new(0, 8)}),
				new("UIStroke", {Transparency = theme.StrokeTransparency})
			})
			springTransparency(toast)
			local t = tween(toast, TweenInfo.new(0.25), {Position = UDim2.new(1,-12,1,-52)})
			t.Completed:Wait()
			task.delay(duration, function()
				tween(toast, TweenInfo.new(0.2), {TextTransparency = 1, BackgroundTransparency = 1}).Completed:Connect(function()
					toast:Destroy()
				end)
			end)
		end,
		SetKeySystem = function(self, newCfg)
			keyCfg = newCfg or keyCfg
		end
	}, NebulaUI)

	-- Tabs
	function api:CreateTab(tabCfg)
		tabCfg = tabCfg or {}
		local btn = new("TextButton", {
			Parent = Window.Nav,
			Size = UDim2.new(1, -12, 0, 40),
			Position = UDim2.fromOffset(8, 0),
			Text = "  " .. (tabCfg.Name or "Tab"),
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			TextSize = 15,
			TextColor3 = theme.Text,
			BackgroundColor3 = theme.Base,
			BackgroundTransparency = 0.25
		}, {
			new("UICorner", {CornerRadius = UDim.new(0, 10)}),
			new("UIStroke", {Transparency = theme.StrokeTransparency})
		})

		local page = new("ScrollingFrame", {
			Parent = ContentPages,
			Active = true,
			Visible = false,
			CanvasSize = UDim2.new(0,0,0,0),
			ScrollBarThickness = 4,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1,1)
		}, {
			new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}),
			new("UIPadding", {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingBottom=UDim.new(0,10)})
		})

		local TabAPI = {
			Button = function(self, cfg)
				cfg = cfg or {}
				local b = new("TextButton", {
					Parent = page,
					Text = cfg.Text or "Button",
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = theme.Text,
					Size = UDim2.new(1, -8, 0, 36),
					BackgroundColor3 = theme.Accent,
					BackgroundTransparency = 0.15
				}, {
					new("UICorner", {CornerRadius = UDim.new(0, 10)})
				})
				springTransparency(b)
				b.MouseButton1Click:Connect(function()
					local t1 = tween(b, TweenInfo.new(0.08), {BackgroundTransparency = 0.35})
					t1.Completed:Wait()
					tween(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.15})
					if cfg.Callback then cfg.Callback() end
				end)
				return b
			end,
			Toggle = function(self, cfg)
				cfg = cfg or {}
				local state = cfg.Default or false
				local holder = new("Frame", {Parent=page, Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1})
				local bg = new("TextButton", {Parent=holder, Size=UDim2.new(1,0,1,0), Text="", BackgroundColor3=theme.Base, BackgroundTransparency=0.3}, {new("UICorner", {CornerRadius=UDim.new(0,10)}), new("UIStroke", {Transparency=theme.StrokeTransparency})})
				local label = new("TextLabel", {Parent=bg, BackgroundTransparency=1, Size=UDim2.new(1,-56,1,0), Position=UDim2.fromOffset(12,0), Text=cfg.Text or "Toggle", TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text})
				local knob = new("Frame", {Parent=bg, Size=UDim2.fromOffset(36, 20), Position=UDim2.new(1,-48,0.5,-10), BackgroundColor3=theme.Base, BackgroundTransparency=0.2}, {new("UICorner", {CornerRadius=UDim.new(1,0)}), new("UIStroke", {Transparency=theme.StrokeTransparency})})
				local dot = new("Frame", {Parent=knob, Size=UDim2.fromOffset(16,16), Position=UDim2.fromOffset(state and 18 or 2,2), BackgroundColor3=state and theme.Success or theme.Subtle, BackgroundTransparency=0.1}, {new("UICorner", {CornerRadius=UDim.new(1,0)})})
				local function setState(s)
					state = s
					tween(dot, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Position = UDim2.fromOffset(s and 18 or 2, 2), BackgroundColor3 = s and theme.Success or theme.Subtle})
					if cfg.Callback then cfg.Callback(state) end
				end
				bg.MouseButton1Click:Connect(function() setState(not state) end)
				return {Set = setState, Get = function() return state end}
			end,
			CheckBox = function(self, cfg)
				cfg = cfg or {}
				local state = cfg.Default or false
				local row = new("Frame", {Parent=page, Size=UDim2.new(1,-8,0,34), BackgroundTransparency=1})
				local box = new("TextButton", {Parent=row, Size=UDim2.fromOffset(22,22), Position=UDim2.fromOffset(8,6), Text="", BackgroundColor3=theme.Base, BackgroundTransparency=0.2}, {new("UICorner", {CornerRadius=UDim.new(0,6)}), new("UIStroke", {Transparency=theme.StrokeTransparency})})
				local tick = new("TextLabel", {Parent=box, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text = state and "✓" or "", TextColor3=theme.Success, Font=Enum.Font.GothamBold, TextSize=18})
				local label = new("TextLabel", {Parent=row, Size=UDim2.new(1,-40,1,0), Position=UDim2.fromOffset(36,0), BackgroundTransparency=1, Text=cfg.Text or "Checkbox", TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text})
				local function setState(s)
					state = s
					tick.Text = s and "✓" or ""
					if cfg.Callback then cfg.Callback(state) end
				end
				box.MouseButton1Click:Connect(function() setState(not state) end)
				return {Set = setState, Get = function() return state end}
			end,
			Label = function(self, cfg)
				local l = new("TextLabel", {Parent=page, Text=(cfg and cfg.Text) or "Label", Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Subtle, BackgroundTransparency=1, Size=UDim2.new(1,-8,0,24)})
				return l
			end,
			TextBox = function(self, cfg)
				cfg = cfg or {}
				local box = new("TextBox", {Parent=page, Text="", PlaceholderText=cfg.Placeholder or "", ClearTextOnFocus = cfg.ClearOnFocus == nil and true or cfg.ClearOnFocus, Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text, BackgroundColor3=theme.Base, BackgroundTransparency=0.2, Size=UDim2.new(1,-8,0,36)}, {new("UICorner", {CornerRadius=UDim.new(0,8)}), new("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})})
				springTransparency(box)
				box.FocusLost:Connect(function(enter)
					if (enter or cfg.SubmitOnLoseFocus) and cfg.Callback then
						cfg.Callback(box.Text)
					end
				end)
				return box
			end,
			Slider = function(self, cfg)
				cfg = cfg or {}
				local min, max, step = cfg.Min or 0, cfg.Max or 100, math.max(cfg.Step or 1, 0.001)
				local value = math.clamp(cfg.Default or min, min, max)
				local holder = new("Frame", {Parent=page, Size=UDim2.new(1,-8,0,44), BackgroundTransparency=1})
				local label = new("TextLabel", {Parent=holder, BackgroundTransparency=1, Size=UDim2.new(1,0,0,18), Text=(cfg.Text or "Slider") .. string.format("  (%s)", tostring(value)), TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text})
				local track = new("Frame", {Parent=holder, Size=UDim2.new(1,0,0,10), Position=UDim2.fromOffset(0,26), BackgroundColor3=theme.Base, BackgroundTransparency=0.3}, {new("UICorner", {CornerRadius=UDim.new(1,0)}), new("UIStroke", {Transparency=theme.StrokeTransparency})})
				local fill = new("Frame", {Parent=track, Size=UDim2.fromScale((value-min)/(max-min), 1), BackgroundColor3=theme.Accent, BackgroundTransparency=0.2}, {new("UICorner", {CornerRadius=UDim.new(1,0)})})
				local thumb = new("Frame", {Parent=track, Size=UDim2.fromOffset(16,16), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale((value-min)/(max-min),0.5), BackgroundColor3=theme.Accent, BackgroundTransparency=0.1}, {new("UICorner", {CornerRadius=UDim.new(1,0)}), new("UIStroke", {Transparency=0.4, Color=theme.Stroke})})

				local dragging = false
				local function setValue(v)
					v = math.clamp(math.round(v/step)*step, min, max)
					value = v
					local alpha = (v-min)/(max-min)
					tween(fill, TweenInfo.new(0.12), {Size = UDim2.fromScale(alpha, 1)})
					tween(thumb, TweenInfo.new(0.12), {Position = UDim2.fromScale(alpha, 0.5)})
					label.Text = (cfg.Text or "Slider") .. string.format("  (%s)", tostring(v))
					if cfg.Callback then cfg.Callback(v) end
				end

				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local rel = (input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X
						setValue(min + rel * (max - min))
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local rel = (input.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X
						setValue(min + rel * (max - min))
					end
				end)
				setValue(value)
				return {Set = setValue, Get = function() return value end}
			end,
			Dropdown = function(self, cfg)
				cfg = cfg or {}
				local current = cfg.Default or (cfg.Options and cfg.Options[1]) or ""
				local holder = new("Frame", {Parent=page, Size=UDim2.new(1,-8,0,36), BackgroundTransparency=1})
				local head = new("TextButton", {Parent=holder, Text="", Size=UDim2.new(1,0,1,0), BackgroundColor3=theme.Base, BackgroundTransparency=0.2}, {new("UICorner", {CornerRadius = UDim.new(0,8)}), new("UIStroke", {Transparency=theme.StrokeTransparency})})
				local label = new("TextLabel", {Parent=head, BackgroundTransparency=1, Size=UDim2.new(1,-36,1,0), Position=UDim2.fromOffset(12,0), Text=(cfg.Text or "Dropdown") .. ": " .. tostring(current), TextXAlignment=Enum.TextXAlignment.Left, Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text})
				local caret = new("TextLabel", {Parent=head, BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-10,0.5,0), Size=UDim2.fromOffset(16,16), Text="▾", TextColor3=theme.Subtle, Font=Enum.Font.GothamBold, TextSize=16})
				local list = new("Frame", {Parent=holder, Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,1,6), BackgroundColor3=theme.Base, BackgroundTransparency=0.1, Visible=false}, {new("UICorner", {CornerRadius=UDim.new(0,8)}), new("UIStroke", {Transparency=theme.StrokeTransparency}), new("UIListLayout", {Padding=UDim.new(0,4)}), new("UIPadding", {PaddingTop=UDim.new(0,6), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), PaddingBottom=UDim.new(0,6)})})

				local opened = false
				local function setOpen(o)
					opened = o
					list.Visible = true
					local targetH = o and math.min(#(cfg.Options or {}), 6)*32 + 16 or 0
					tween(list, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1,0,0, targetH)}).Completed:Connect(function()
						if not opened then list.Visible = false end
					end)
					caret.Text = o and "▴" or "▾"
				end

				head.MouseButton1Click:Connect(function() setOpen(not opened) end)

				local function setValue(v)
					current = v
					label.Text = (cfg.Text or "Dropdown") .. ": " .. tostring(v)
					if cfg.Callback then cfg.Callback(v) end
					setOpen(false)
				end

				for _, opt in ipairs(cfg.Options or {}) do
					local o = new("TextButton", {Parent=list, Text=tostring(opt), Font=Enum.Font.Gotham, TextSize=14, TextColor3=theme.Text, BackgroundTransparency=1, Size=UDim2.new(1,0,0,28)})
					o.MouseButton1Click:Connect(function() setValue(opt) end)
					o.MouseEnter:Connect(function() tween(o, TweenInfo.new(0.08), {TextTransparency = 0}) end)
					o.MouseLeave:Connect(function() tween(o, TweenInfo.new(0.12), {TextTransparency = 0.2}) end)
				end
				return {Set = setValue, Get = function() return current end, Open = function() setOpen(true) end, Close = function() setOpen(false) end}
			end,
			CreateSection = function(self, title)
				local container = new("Frame", {Parent=page, Size=UDim2.new(1,-8,0,8), BackgroundTransparency=1})
				local caption = new("TextLabel", {Parent=container, BackgroundTransparency=1, Text=title or "Section", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=theme.Text, Size=UDim2.new(1,0,0,24), TextXAlignment=Enum.TextXAlignment.Left})
				new("UIPadding", {Parent=container, PaddingTop=UDim.new(0,2)})
				container.Size = UDim2.new(1,-8,0, caption.AbsoluteSize.Y + 8)
				local proxy = {}
				setmetatable(proxy, {__index = function(_, k) return TabAPI[k] end})
				return proxy
			end,
		}

		-- Tab switching
		btn.MouseButton1Click:Connect(function()
			for _, t in ipairs(self._Tabs) do
				t.Page.Visible = false
				tween(t.Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.35})
			end
			page.Visible = true
			tween(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.15})
			self._OnTabSwitched:Fire(tabCfg.Name)
		end)

		page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
			page.CanvasSize = UDim2.new(0,0,0, page.UIListLayout.AbsoluteContentSize.Y + 20)
		end)

		table.insert(self._Tabs, {Name = tabCfg.Name, Button = btn, Page = page})
		if #self._Tabs == 1 then btn:Activate() end
		return setmetatable({CreateSection = TabAPI.CreateSection, Button = TabAPI.Button, Toggle = TabAPI.Toggle, Slider = TabAPI.Slider, Dropdown = TabAPI.Dropdown, TextBox = TabAPI.TextBox, Label = TabAPI.Label, CheckBox = TabAPI.CheckBox}, {__index = TabAPI})
	end

	return api
end

return NebulaUI


--// ---------------------------------------------
--// File: Example.client.lua (LocalScript usage)
--// Put NebulaUI.lua as a ModuleScript (e.g., ReplicatedStorage.NebulaUI), then require it from a LocalScript
--// ---------------------------------------------
--[[
local NebulaUI = require(game:GetService("ReplicatedStorage"):WaitForChild("NebulaUI"))

local ui = NebulaUI.CreateWindow({
    Name = "Nebula – Advanced UI",
    Theme = "DarkGlass",
    Blur = true,
    KeySystem = {Required = true, Keys = {"ABC-123", "LETMEIN"}}
})

local Tab1 = ui:CreateTab({Name = "Main", Icon = "rbxassetid://0"})
local Controls = Tab1:CreateSection("Controls")
Controls:Label({Text = "Welcome to Nebula"})
Controls:Button({Text = "Notify Me", Callback = function()
    ui:Notify("Hey there!", 2)
end})

local t = Controls:Toggle({Text = "Particles", Default = false, Callback = function(on)
    print("Particles:", on)
end})

local s = Controls:Slider({Text = "WalkSpeed", Min = 8, Max = 32, Default = 16, Step = 1, Callback = function(v)
    LocalPlayer.Character.Humanoid.WalkSpeed = v
end})

local dd = Controls:Dropdown({Text = "Team", Options = {"Red","Blue","Green"}, Default = "Red", Callback = function(opt)
    print("Team:", opt)
end})

Controls:TextBox({Placeholder = "Type here", ClearOnFocus = false, Callback = function(text)
    print("Text:", text)
end})

local Tab2 = ui:CreateTab({Name = "Settings", Icon = "rbxassetid://0"})
local S = Tab2:CreateSection("Preferences")
S:CheckBox({Text = "Enable Music", Default = true, Callback = function(on)
    print("Music:", on)
end})
]]

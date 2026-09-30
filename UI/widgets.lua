local _, Addon = ...
local AceGUI = Addon:GetLibrary("AceGUI")
local Theme = Addon:GetModule("Theme")
local Widgets = Addon:GetModule("Widgets")

-- ============================================================================
-- AceGUI-backed widgets
-- ============================================================================
-- These back the detail panels (ability info, settings rows). They're mounted
-- inside a plain host frame created by the modules themselves, rather than an
-- AceGUI Frame/Window, so the outer chrome stays fully custom-skinned.

--[[
  Adds a basic AceGUI Button to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    width = number,
    height = number,
    onClick = function,
    onEnter = function,
    onLeave = function
  }
]]
function Widgets:Button(options)
  local button = AceGUI:Create("Button")
  button:SetText(options.text)
  button:SetFullWidth(options.fullWidth)
  if options.width then button:SetWidth(options.width) end
  if options.height then button:SetHeight(options.height) end
  button:SetCallback("OnClick", options.onClick)
  button:SetCallback("OnEnter", options.onEnter)
  button:SetCallback("OnLeave", options.onLeave)
  options.parent:AddChild(button)
  return button
end

--[[
  Adds a basic AceGUI CheckBox to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    tooltip = string,
    get = function() -> boolean,
    set = function(value)
  }
]]
function Widgets:CheckBox(options)
  local checkBox = AceGUI:Create("CheckBox")
  checkBox:SetValue(options.get())
  checkBox:SetLabel(options.label)

  checkBox:SetCallback("OnValueChanged", function(_, _, value)
    options.set(value)
  end)

  if options.tooltip then
    checkBox:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.checkbg, "ANCHOR_TOP")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    checkBox:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(checkBox)
  return checkBox
end

--[[
  Adds a basic AceGUI Slider to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    tooltip = string,
    min = number, max = number, step = number,
    isPercent = boolean,
    get = function() -> number,
    set = function(value)
  }
]]
function Widgets:Slider(options)
  local slider = AceGUI:Create("Slider")
  slider:SetLabel(options.label)
  slider:SetSliderValues(options.min, options.max, options.step or 0.01)
  slider:SetIsPercent(options.isPercent)
  slider:SetValue(options.get())
  slider:SetFullWidth(options.fullWidth)

  slider:SetCallback("OnValueChanged", function(_, _, value)
    options.set(value)
  end)

  if options.tooltip then
    slider:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.frame, "ANCHOR_TOP")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    slider:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(slider)
  return slider
end

--[[
  Adds a basic AceGUI EditBox to a parent widget and returns it.

  options = {
    parent = widget,
    label = string,
    tooltip = string,
    fullWidth = boolean,
    get = function() -> string,
    set = function(value)
  }
]]
function Widgets:EditBox(options)
  local editBox = AceGUI:Create("EditBox")
  editBox:SetLabel(options.label)
  editBox:SetText(options.get())
  editBox:SetFullWidth(options.fullWidth)

  editBox:SetCallback("OnEnterPressed", function(_, _, value)
    options.set(value)
  end)

  if options.tooltip then
    editBox:SetCallback("OnEnter", function(this)
      GameTooltip:SetOwner(this.frame, "ANCHOR_TOP")
      GameTooltip:SetText(options.label, 1.0, 0.82, 0)
      GameTooltip:AddLine(options.tooltip, 1, 1, 1, true)
      GameTooltip:Show()
    end)

    editBox:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  options.parent:AddChild(editBox)
  return editBox
end

-- Adds an AceGUI Heading to a parent widget and returns it.
function Widgets:Heading(parent, text)
  local heading = AceGUI:Create("Heading")
  heading:SetText(text)
  heading:SetFullWidth(true)
  parent:AddChild(heading)
  return heading
end

--[[
  Adds a basic AceGUI Label to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    color = table
  }
]]
function Widgets:Label(options)
  local label = AceGUI:Create("Label")
  label:SetText(options.text)
  label:SetFullWidth(options.fullWidth)

  if options.color then
    label:SetColor(options.color.r, options.color.g, options.color.b)
  end

  if options.font then
    if options.fontHeight then
      -- flags must be a string: a nil third argument makes SetFont throw here.
      label:SetFont(options.font, options.fontHeight, options.fontFlags or "")
    else
      label:SetFontObject(options.font)
    end
  end

  if options.image then
    label:SetImage(options.image.path, unpack(options.image.texCoord))
    if options.image.width and options.image.height then
      label:SetImageSize(options.image.width, options.image.height)
    end
  end

  options.parent:AddChild(label)
  return label
end

-- Helper function to create an empty, full width Label widget.
function Widgets:Spacer(parent)
  return self:Label({
    parent = parent,
    text = " ",
    fullWidth = true
  })
end

--[[
  Adds an AceGUI InlineGroup to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    fullWidth = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:InlineGroup(options)
  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetTitle(options.title)
  if options.relativeWidth then
    inlineGroup:SetRelativeWidth(options.relativeWidth)
  else
    inlineGroup:SetFullWidth(options.fullWidth)
  end
  inlineGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(inlineGroup)
  return inlineGroup
end

--[[
  Adds an AceGUI SimpleGroup to a parent widget and returns it.

  options = {
    parent = widget,
    fullWidth = boolean,
    fullHeight = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:SimpleGroup(options)
  local simpleGroup = AceGUI:Create("SimpleGroup")
  simpleGroup:SetFullWidth(options.fullWidth)
  simpleGroup:SetFullHeight(options.fullHeight)
  simpleGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(simpleGroup)
  return simpleGroup
end

--[[
  Mounts a scrollable AceGUI "Flow" container inside `hostFrame` (a plain,
  already-positioned native Frame) and returns it: call :AddChild() /
  :ReleaseChildren() on the result like any AceGUI container.

  The scrolling itself is a native UIPanelScrollFrameTemplate (the same one
  the ability/family lists use, which is known to scroll correctly here)
  rather than AceGUI's own ScrollFrame widget. AceGUI's version depends on
  being sized through AceGUI, and when it's dropped into a native frame it
  never works out that its content is taller than the view — so the scroll
  bar never appeared and long panels couldn't be scrolled.
]]
function Widgets:MountScrollHost(hostFrame)
  local scrollFrame = CreateFrame("ScrollFrame", nil, hostFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 0, 0)
  scrollFrame:SetPoint("BOTTOMRIGHT", -22, 0) -- room for the scroll bar

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(1, 1)
  scrollFrame:SetScrollChild(scrollChild)

  local group = AceGUI:Create("SimpleGroup")
  group:SetLayout("Flow")
  group.frame:SetParent(scrollChild)
  group.frame:ClearAllPoints()
  group.frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
  group.frame:Show()

  -- Whenever the group finishes laying out, size the scroll child to match
  -- so the scroll range (and bar) reflect the real content height.
  local layoutFinished = group.LayoutFinished
  group.LayoutFinished = function(self, width, height)
    if layoutFinished then layoutFinished(self, width, height) end
    scrollChild:SetHeight(math.max((height or 0) + 8, 1))
  end

  -- Start every rebuild at the top.
  local releaseChildren = group.ReleaseChildren
  group.ReleaseChildren = function(self, ...)
    releaseChildren(self, ...)
    scrollFrame:SetVerticalScroll(0)
  end

  -- Pet Codex jumps back to the top with SetScroll(0) (an AceGUI ScrollFrame
  -- method), so keep that call working.
  group.SetScroll = function(_, value)
    if not value or value <= 0 then scrollFrame:SetVerticalScroll(0) end
  end

  -- Keep the content as wide as the view, and re-flow when it changes.
  scrollFrame:HookScript("OnSizeChanged", function(_, width)
    if width and width > 0 then
      scrollChild:SetWidth(width)
      group:SetWidth(width)
      group:DoLayout()
    end
  end)

  return group
end

-- ============================================================================
-- Native themed widgets (no AceGUI) — used for the shell chrome: sidebar,
-- header, panels. These are what give Huntmaster its own look instead of the
-- stock Ace3 frame/tree skin.
-- ============================================================================

-- Creates a flat-colored panel frame (used for the sidebar, header bar, and
-- content backdrop). `layer` colors: Theme.Color.panel / panelLight.
function Widgets:Panel(parent, color)
  local panel = CreateFrame("Frame", nil, parent)
  Theme:Fill(panel, color or Theme.Color.panel)
  return panel
end

--[[
  Creates a single sidebar navigation row.

  options = {
    parent = widget,
    text = string,
    onClick = function(self),
  }

  Returns the button. Call button:SetSelected(bool) to toggle its state.
]]
function Widgets:NavButton(options)
  local button = CreateFrame("Button", nil, options.parent)
  button:SetHeight(32)

  button.bg = Theme:Fill(button, Theme.Color.navIdle, "BACKGROUND")

  button.accent = button:CreateTexture(nil, "ARTWORK")
  button.accent:SetPoint("TOPLEFT")
  button.accent:SetPoint("BOTTOMLEFT")
  button.accent:SetWidth(2)
  button.accent:SetColorTexture(unpack(Theme.Color.accent))
  button.accent:Hide()

  button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.label:SetPoint("LEFT", 14, 0)
  button.label:SetText(options.text)
  button.label:SetTextColor(unpack(Theme.Color.text))

  function button:SetSelected(selected)
    self.selected = selected
    if selected then
      self.bg:SetColorTexture(unpack(Theme.Color.navSelected))
      self.accent:Show()
      self.label:SetTextColor(unpack(Theme.Color.accent))
    else
      self.bg:SetColorTexture(unpack(Theme.Color.navIdle))
      self.accent:Hide()
      self.label:SetTextColor(unpack(Theme.Color.text))
    end
  end

  button:SetScript("OnEnter", function(self)
    if not self.selected then self.bg:SetColorTexture(unpack(Theme.Color.navHover)) end
  end)
  button:SetScript("OnLeave", function(self)
    if not self.selected then self.bg:SetColorTexture(unpack(Theme.Color.navIdle)) end
  end)
  button:SetScript("OnClick", function(self) options.onClick(self) end)

  button:SetSelected(false)
  return button
end

--[[
  Creates a single row for a scrollable list (e.g. the Pet Codex ability
  list). Same selection behavior as NavButton but with an icon slot.

  options = {
    parent = widget,
    text = string,
    icon = fileID or path,
    onClick = function(self),
  }
]]
function Widgets:ListRow(options)
  local row = CreateFrame("Button", nil, options.parent)
  row:SetHeight(28)

  row.bg = Theme:Fill(row, Theme.Color.navIdle, "BACKGROUND")

  if options.icon then
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 8, 0)
    row.icon:SetTexture(options.icon)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.label:SetPoint("LEFT", options.icon and 30 or 10, 0)
  row.label:SetPoint("RIGHT", -8, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetText(options.text)
  row.label:SetTextColor(unpack(Theme.Color.text))

  function row:SetSelected(selected)
    self.selected = selected
    self.bg:SetColorTexture(unpack(selected and Theme.Color.navSelected or Theme.Color.navIdle))
    self.label:SetTextColor(unpack(selected and Theme.Color.accent or Theme.Color.text))
  end

  row:SetScript("OnEnter", function(self)
    if not self.selected then self.bg:SetColorTexture(unpack(Theme.Color.navHover)) end
  end)
  row:SetScript("OnLeave", function(self)
    if not self.selected then self.bg:SetColorTexture(unpack(Theme.Color.navIdle)) end
  end)
  if options.onClick then
    row:SetScript("OnClick", function(self) options.onClick(self) end)
  end

  return row
end

--[[
  Creates a simple bordered search/edit box.

  options = { parent = widget, width = number, placeholder = string, onTextChanged = function(text) }
]]
function Widgets:SearchBox(options)
  local box = CreateFrame("EditBox", nil, options.parent)
  box:SetHeight(24)
  if options.width then box:SetWidth(options.width) end
  box:SetAutoFocus(false)
  box:SetFontObject(GameFontHighlightSmall)
  box:SetTextInsets(8, 8, 0, 0)

  box.bg = box:CreateTexture(nil, "BACKGROUND")
  box.bg:SetAllPoints()
  box.bg:SetColorTexture(unpack(Theme.Color.panelLight))

  box.placeholder = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  box.placeholder:SetPoint("LEFT", 8, 0)
  box.placeholder:SetText(options.placeholder or "")
  box.placeholder:Show()

  box:SetScript("OnTextChanged", function(self)
    self.placeholder:SetShown(self:GetText() == "")
    if options.onTextChanged then options.onTextChanged(self:GetText()) end
  end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  return box
end

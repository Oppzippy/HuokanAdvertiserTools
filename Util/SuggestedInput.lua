local _, addon = ...
local SuggestedInput = {}
addon.SuggestedInput = SuggestedInput

SuggestedInput.widgets = {}

function SuggestedInput:Register(textWidget)
	local widget = addon.SuggestedInputWidget.Create(textWidget)
	self.widgets[#self.widgets+1] = widget
	return widget
end

local _, addon = ...

function addon.ForceWidgetToScreenBounds(statusTable)
	if not statusTable then return end

	local maxWidth = UIParent:GetWidth()
	local maxHeight = UIParent:GetHeight()

	-- wider than screen
	if statusTable.width > maxWidth then
		statusTable.width = maxWidth
	end
	-- taller than screen
	if statusTable.height > maxHeight then
		statusTable.height = maxHeight
	end
	if statusTable.left and statusTable.top then
		-- left of screen
		if statusTable.left < 0 then
			statusTable.left = 0
		end
		-- right of screen
		if statusTable.left > maxWidth - statusTable.width  then
			statusTable.left = maxWidth - statusTable.width
		end
		-- bottom of screen
		if statusTable.top < statusTable.height then
			statusTable.top = statusTable.height
		end
		-- top of screen
		if statusTable.top > maxHeight then
			statusTable.top = maxHeight
		end
	end
end

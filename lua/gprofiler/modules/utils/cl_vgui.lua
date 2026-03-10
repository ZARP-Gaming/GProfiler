local PANEL = {}

function PANEL:SortByColumn(ColumnID, Desc)
	table.sort(self.Sorted, function(a, b)
		if Desc then a, b = b, a end
		local aval = a:GetSortValue( ColumnID ) || a:GetColumnText( ColumnID )
		local bval = b:GetSortValue( ColumnID ) || b:GetColumnText( ColumnID )
		if isnumber(aval) and isnumber(bval) then return aval < bval end
		return tostring(aval) < tostring(bval)
	end)

	self:SetDirty(true)
	self:InvalidateLayout()

	self.SortedBy = ColumnID
	self.SortedDescending = Desc
end

derma.DefineControl("GP.ListView", "", PANEL, "DListView")

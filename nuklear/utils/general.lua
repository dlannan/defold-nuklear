

------------------------------------------------------------------------------------------------------------

table.keys = function(self)
	local keys = {}
	for k, v in pairs(self) do
		table.insert(keys, k)
	end
	return keys
end 


-- -------------------------------------------------------------------------

local colors = {
	white	= vmath.vector4(1, 1, 1, 1),
	blue 	= vmath.vector4(0, 0, 1, 1),
	green 	= vmath.vector4(0, 1, 0, 1),
	red 	= vmath.vector4(1, 0, 0, 1),
	yellow 	= vmath.vector4(1, 1, 0, 1),
}

-- -------------------------------------------------------------------------

local function drawLine( spos, epos, col )

	if(type(col) == "string") then col = colors[col] end
	msg.post("@render:", "draw_line", { start_point = spos, end_point = epos, color = col } )
end 

------------------------------------------------------------------------------------------------------------

local function knots( ms )
	return 1.944 * ms 
end 

------------------------------------------------------------------------------------------------------------

local function feet( m )
	return 3.28084 * m
end

------------------------------------------------------------------------------------------------------------

local function mile( meters )
	return meters * 0.001 * 0.621371
end 

------------------------------------------------------------------------------------------------------------

local function meters( mile )
	return mile * 1.60934 * 1000
end 

------------------------------------------------------------------------------------------------------------

local function msec( knots ) 
	return knots * 0.514444
end


------------------------------------------------------------------------------------------------------------

return {

	drawLine 	= drawLine,

	knots		= knots,
	feet		= feet, 
	mile 		= mile,
	meters 		= meters,
	msec 		= msec, 
}
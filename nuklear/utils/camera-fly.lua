
-- A camera controller so I can pan and move around the scene. 
-- Enable/Disable using keys

local camerafly = {}
--------------------------------------------------------------------------------

local function newcamera()
	
	local camerafly = {

		lookvec 	= vmath.vector3(),
		pos			= vmath.vector3(),
		movevec 	= vmath.vector3(),
		
		xangle 		= 0.0,
		yangle		= 0.0,
	}
	return camerafly
end 

--------------------------------------------------------------------------------
-- A simple handler, can be easily replaced
local function defaulthandler( self, delta )

	local pitch		= -self.xangle
	local yaw		= self.yangle

	xzLen = math.cos(yaw)
	self.lookvec.z = -xzLen * math.cos(pitch)
	self.lookvec.y = math.sin(yaw)
	self.lookvec.x = xzLen * math.sin(-pitch)
	
	-- do some default movement stuff
	self.movevec = vmath.vector3( self.lookvec.x * self.speed * delta,
	self.lookvec.y * self.speed * delta,
	self.lookvec.z * self.speed * delta)
		
	self.pos =  vmath.vector3(self.pos.x + self.movevec.x, 
	self.pos.y + self.movevec.y,
	self.pos.z + self.movevec.z)

	local xrot = vmath.quat_rotation_y(pitch)
	local yrot = vmath.quat_rotation_x(yaw)
	camerafly.rot = xrot * yrot 
	
	go.set_rotation( self.rot, self.cameraobj )		
	go.set_position( self.pos, self.cameraobj )
end

--------------------------------------------------------------------------------

camerafly.init = function( cameraobj, speed, handler )

	local newcam = newcamera()
	newcam.cameraobj = cameraobj 
	newcam.speed = speed or 0.0
	newcam.handler = handler or defaulthandler

	newcam.pos = go.get_position(cameraobj)
	newcam.rot = go.get_rotation(cameraobj)
	
	newcam.enabled = true 		-- enabled by default

	newcam.update = function( self, delta )

		if(newcam.enabled ~= true) then return end
		if(newcam.handler) then newcam.handler( newcam, delta ) end
	end
	
	return newcam
end 

--------------------------------------------------------------------------------



--------------------------------------------------------------------------------

return camerafly

--------------------------------------------------------------------------------
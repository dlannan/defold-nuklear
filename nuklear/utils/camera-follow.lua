
-- A camera controller so I can pan and move around the scene. 
-- Enable/Disable using keys
--------------------------------------------------------------------------------

local tf 		= require("utils.transforms")

-- Soft start and stop - all movements should be softened to make a nice movement
--   experience. Camera motion should also be dampened.

local move_dampen 	= 0.89
local look_dampen 	= 0.89

local camerafollow = {}

--------------------------------------------------------------------------------
local function newcamera()
	
	local camerafollow = {

		playerheight 	= 1.3, 
		cameraheight 	= 3.0,

		-- Where the look focus is in the distance
		lookdistance 	= 4.0,

		looklimityaw 	= math.pi * 0.5,
		looklimitpitch 	= math.pi * 0.5,

		lookvec 		= vmath.vector3(),
		pos				= vmath.vector3(),
		movevec 		= vmath.vector3(),

		xangle 			= 0.0,
		yangle			= 0.0,
	}
	return camerafollow
end 

--------------------------------------------------------------------------------

local function LookAt(sourcePoint, destPoint)

	local forwardVector = vmath.normalize(destPoint - sourcePoint)
	local dot = vmath.dot(vmath.vector3(0.0, 0.0, 1.0), forwardVector)

	if (math.abs(dot - (-1.0)) < 0.000001) then
	
		return vmath.quat(0.0, 1.0, 0.0, math.pi)
	end
	if (math.abs(dot - (1.0)) < 0.000001) then
	
		return vmath.quat()
	end

	local rotAngle = math.acos(dot)
	local rotAxis = vmath.cross(vmath.vector3(0.0,0.0,1.0), forwardVector)
	rotAxis = vmath.normalize(rotAxis)
	return vmath.quat_axis_angle(rotAxis, rotAngle)
end

--------------------------------------------------------------------------------
-- A simple handler, can be easily replaced
local function defaulthandler( self, delta )

	-- local pitch		= -camerafollow.xangle
	-- local yaw		= camerafollow.yangle

	-- if (yaw > math.pi) then yaw = -math.pi; camerafollow.yangle = -math.pi end 
	-- if (yaw < -math.pi) then yaw = math.pi; camerafollow.yangle = math.pi end 
	-- if (pitch > math.pi * 0.5) then pitch = math.pi * 0.5; camerafollow.xangle = math.pi * 0.5 end 
	-- if (pitch < -math.pi * 0.5) then pitch = -math.pi * 0.5; camerafollow.xangle = -math.pi * 0.5 end 

	self.prevtpos 	 = vmath.vector3(self.tpos)

	local ospos = self.target.mover.position()
	local osrot = self.target.mover._quat

	self.tpos 		 = vmath.vector3(ospos.x, ospos.y, ospos.z)
	self.trot 		 = osrot
	
	local sloppyrot  = vmath.slerp(delta * self.sloppiness, self.rot, self.trot)
	local rotmat 	 = vmath.matrix4_from_quat(sloppyrot)
	local mdir 	 	 = rotmat * vmath.vector4(0, self.cameraheight, self.distance, 0)
	local campos 	 = vmath.vector3(mdir.x, mdir.y, mdir.z)
	
	self.pos = self.tpos + campos
	self.rot = sloppyrot

	-- local osfwd      = self.target.mover.forward()
	-- self.trot 		 = tf.DirToQuat(vmath.vector3(osfwd.x, osfwd.y, osfwd.z))
	
	self.tspeed 	 = self.target.mover.speed()
	self.teuler		 = tf.ToEulerAngles(self.trot)
	self.tvelocity 	 = self.target.mover.velocity()

	self.throttle	 = math.floor(self.tspeed/self.target.mover.maxSpeed() * 10)
		
	go.set_rotation( self.rot, self.cameraobj )		
	go.set_position( self.pos, self.cameraobj )
	
	local objdata = {		
		speed		 = self.tspeed,
		climb 		 = self.tvelocity.y,
		heading		 = -math.deg(self.teuler.y),
		altitude	 = self.tpos.y,
		throttle 	 = self.throttle,
		fuelpercent  = 0,
		weight 		 = 0, 
		angles		 = { x = self.teuler.x, y = self.teuler.y, z = self.teuler.z },
	}

	msg.post("/gui", "object", objdata)
	self.prevpos = self.tpos
end

--------------------------------------------------------------------------------

camerafollow.init = function( cameraobj, target, distance, handler )

	local newcam = newcamera()
	
	newcam.cameraobj = cameraobj 
	newcam.target = target

	newcam.tpos = vmath.vector3()
	newcam.trot = vmath.vector3()

	newcam.distance 	= distance
	newcam.smooth 	= 0.98
	newcam.speed 		= 1.0
	newcam.flat 		= true 		-- define if the camera rolls
	newcam.sloppiness = 1.4

	newcam.pos = go.get_position(cameraobj)
	newcam.rot = go.get_rotation(cameraobj)
	newcam.prevpos = go.get_world_position(camerafollow.target)

	newcam.enabled = true 		-- enabled by default
	newcam.handler = handler or defaulthandler

	newcam.update = function( self, delta )

		if(newcam.enabled ~= true) then return end
		if(newcam.handler) then newcam.handler( newcam, delta ) end
	end
	
	return newcam
end 

--------------------------------------------------------------------------------

return camerafollow

--------------------------------------------------------------------------------
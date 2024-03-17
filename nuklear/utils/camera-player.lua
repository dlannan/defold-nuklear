
-- A camera controller so I can pan and move around the scene. 
-- Enable/Disable using keys
--------------------------------------------------------------------------------

local tf 		= require("utils.transforms")

-- Soft start and stop - all movements should be softened to make a nice movement
--   experience. Camera motion should also be dampened.

local move_dampen 	= 0.89
local look_dampen 	= 0.89

local cameraplayer = {}

--------------------------------------------------------------------------------

local function newcamera()
	
	local cameraplayer = {

		playerheight 	= 1.3, 
		cameraheight 	= 2.0,

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
	return cameraplayer
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

	-- local pitch		= -cameraplayer.xangle
	-- local yaw		= cameraplayer.yangle

	-- if (yaw > math.pi) then yaw = -math.pi; cameraplayer.yangle = -math.pi end 
	-- if (yaw < -math.pi) then yaw = math.pi; cameraplayer.yangle = math.pi end 
	-- if (pitch > math.pi * 0.5) then pitch = math.pi * 0.5; cameraplayer.xangle = math.pi * 0.5 end 
	-- if (pitch < -math.pi * 0.5) then pitch = -math.pi * 0.5; cameraplayer.xangle = -math.pi * 0.5 end 

	local ospos = self.target.mover.position()
	local osrot = self.target.mover._quat

	self.tpos 		 = vmath.vector3(ospos.x, ospos.y, ospos.z)
	self.trot 		 = osrot
	self.teuler		 = tf.ToEulerAngles(self.trot)
	
	--local mdir = self.target.mover.globalizeDirection( Vec3Set(0.02, 1, self.distance) )
	local mdir 	 	 = vmath.rotate(self.trot,  vmath.vector3(0.02, 1, self.distance))
	local campos 	 = vmath.vector3(mdir.x, mdir.y, mdir.z)

	self.pos = self.tpos + campos
	self.rot = self.trot

	go.set_rotation( self.rot, self.cameraobj )	
	go.set_position( self.pos, self.cameraobj )
	self.prevpos = self.tpos
end

--------------------------------------------------------------------------------

cameraplayer.init = function( cameraobj, target, distance, handler )

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

	local tvec = newcam.target.mover.position()
	newcam.prevpos = vmath.vector3(tvec.x, tvec.y, tvec.z)

	newcam.enabled = true 		-- enabled by default
	newcam.handler = handler or defaulthandler

	newcam.update = function( self, delta )

		if(newcam.enabled ~= true) then return end
		if(newcam.handler) then newcam.handler( newcam, delta ) end
	end
	return newcam
end 


--------------------------------------------------------------------------------

return cameraplayer

--------------------------------------------------------------------------------
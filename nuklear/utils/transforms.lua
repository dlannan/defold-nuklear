
-- -------------------------------------------------------------------------

local function lerp(t, a, b)
	return a + (b - a) * t
end

math.lerp = function( t, a, b)
	return lerp(t, a, b)
end 

-- -------------------------------------------------------------------------

local function sign(n)
	return n==0 and 0 or math.abs(n)/n
end

-- -------------------------------------------------------------------------

math.sign = function(n)
	return sign(n)
end

-- -------------------------------------------------------------------------

local function getPositionMatrix( pos ) 
	return vmath.matrix4_translation( pos )
end

-- -------------------------------------------------------------------------

local function getRotationMatrix( rot )
	return vmath.matrix4_from_quat(rot)
end

-- -------------------------------------------------------------------------

local function TransformVector(rotation, vec ) 
	return vmath.rotate(rotation, vec)
end

-- -------------------------------------------------------------------------

local function InvTransformVector( rotation, vec, relPos )
	local invrot = vmath.quat(-rotation.x, -rotation.y, -rotation.z, rotation.w)
	if(relPos) then vec = vec - relPos end
	return vmath.rotate(invrot, vec)
end

-- -------------------------------------------------------------------------

local function eulerAngles(v) 
	return vmath.vector3(math.atan2(v.z, v.x),  math.atan2(v.y, v.x), math.atan2(v.z, v.y) )
end

-- -------------------------------------------------------------------------

local function QuatToDir( q, fdir )
	local fwd = vmath.rotate( q, fdir or vmath.vector3(0, 0, 1) )
	local up = vmath.rotate( q, vmath.vector3(0, 1, 0) )
	return fwd, up
end

-- -------------------------------------------------------------------------

local function DirToQuat( dir , up )
	local v1 = up or vmath.vector3(0, 1, 0)
	local a = vmath.cross(v1, dir)
	local w = math.sqrt(vmath.length_sqr(v1) * vmath.length_sqr(dir)) + vmath.dot(v1, dir)
	return vmath.normalize(vmath.quat(a.x, a.y, a.z, w))
end
-- -------------------------------------------------------------------------

local function RotateEuler( vec ) 

	local heading = vec.y
	local roll = vec.z 
	local pitch = vec.x
	local rot = vmath.quat()

	--// Assuming the angles are in radians.
	local c1 = math.cos(heading)
	local s1 = math.sin(heading)
	local c2 = math.cos(roll)
	local s2 = math.sin(roll)
	local c3 = math.cos(pitch)
	local s3 = math.sin(pitch)
	rot.w = math.sqrt(1.0 + c1 * c2 + c1*c3 - s1 * s2 * s3 + c2*c3) * 0.5
	
	local w4 = (4.0 * rot.w)
	rot.x = (c2 * s3 + c1 * s3 + s1 * s2 * c3) / w4 
	rot.y = (s1 * c2 + s1 * c3 + c1 * s2 * s3) / w4 
	rot.z = (-s1 * s3 + c1 * s2 * c3 +s2) / w4 
	return rot
end

-- -------------------------------------------------------------------------
-- https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
local function ToQuaternion(yaw, pitch, roll) -- // yaw (Z), pitch (Y), roll (X)

	-- // Abbreviations for the various angular functions
	local cy = math.cos(yaw * 0.5)
	local sy = math.sin(yaw * 0.5)
	local cp = math.cos(pitch * 0.5)
	local sp = math.sin(pitch * 0.5)
	local cr = math.cos(roll * 0.5)
	local sr = math.sin(roll * 0.5)

	local q = vmath.quat()
	q.w = cr * cp * cy + sr * sp * sy
	q.x = sr * cp * cy - cr * sp * sy
	q.y = cr * sp * cy + sr * cp * sy
	q.z = cr * cp * sy - sr * sp * cy
	return q
end

-- -------------------------------------------------------------------------

local function ToEulerAngles(q) 
	
	local angles = vmath.vector3()
	-- // if the input quaternion is normalized, this is exactly one. Otherwise, this acts as a correction factor for the quaternion's not-normalizedness
	local unit = (q.x * q.x) + (q.y * q.y) + (q.z * q.z) + (q.w * q.w)
	
	-- // this will have a magnitude of 0.5 or greater if and only if this is a singularity case
	local test = q.x * q.w - q.y * q.z

	if (test > 0.4995 * unit) then --// singularity at north pole
	
		angles.x = math.pi * 0.5
		angles.y = 2 * math.atan2(q.y, q.x)
		angles.z = 0

	elseif (test < -0.4995 * unit) then -- // singularity at south pole

		angles.x = -math.pi * 0.5;
		angles.y = -2 * math.atan2(q.y, q.x)
		angles.z = 0

	else -- // no singularity - this is the majority of cases

		angles.x = math.asin(2 * (q.w * q.x - q.y * q.z))
		angles.y = math.atan2(2 * q.w * q.y + 2 * q.z * q.x, 1 - 2 * (q.x * q.x + q.y * q.y))
		angles.z = math.atan2(2 * q.w * q.z + 2 * q.x * q.y, 1 - 2 * (q.z * q.z + q.x * q.x))
	end

	return angles
end

-- -------------------------------------------------------------------------

local function OrthoNormalize( fwd, up )
	fwd = vmath.normalize(fwd)
	local fDot0 = vmath.dot(fwd, up)
	up = up - fwd * fDot0
	up = vmath.normalize(up)
	return fwd, up
end

-- -------------------------------------------------------------------------

local function QuatLookAt(sourcePoint, destPoint, up)

	local forward = -(destPoint - sourcePoint)
	local up = up or vmath.vector3(0, 1, 0)
	forward, up = OrthoNormalize(forward, up)
	local right = vmath.cross(up, forward)

	local ret = vmath.quat()
	local sum = 1.0 + right.x + up.y + forward.z
	if(math.abs(sum) < 0.00001) then return nil end
	ret.w = math.sqrt(sum) * 0.5
	local w4_recip = 1.0 / (4.0 * ret.w)
	ret.x = (up.z - forward.y) * w4_recip
	ret.y = (forward.x - right.z) * w4_recip
	ret.z = (right.y - up.x) * w4_recip
	
	return ret
end

-- -------------------------------------------------------------------------

local function orthogonalize(v, reff)

	local refmag = vmath.length(reff)
	if (refmag > 1.0E-6) then 
		reff = reff * (1.0 / refmag)
	end
	v = v - (reff * (vmath.dot(v, reff)))
	return v
end


------------------------------------------------------------------------------------------------------------
-- Uses modifications in the Render_Script!!!
local render_data = nil

local function getProjection()

	render_data = render_data or require("nuklear.utils.module-tables")

	-- Dont let initial setups be overwritten
	gProjection = render_data.get("projection").proj
	gView = render_data.get("projection").view
	local w, h = window.get_size()
	gViewport = { width = w, height = h, x = 0, y = 0 }	
end

-- -------------------------------------------------------------------------

local function WorldToScreen(pos, updateview)

	local proj = gProjection or getProjection()
	local view = gView or getProjection() 
	if(updateview) then getProjection() end  -- force a view position/direction update
	
	local m = gProjection * gView
	local pv = vmath.vector4( pos.x, pos.y, pos.z, 1 )
	pv = m * pv
	pv = pv * (1/pv.w)
	pv.x = pv.x * 0.5 * gViewport.width + 0.5 * gViewport.width
	pv.y = pv.y * -0.5 * gViewport.height + 0.5 * gViewport.height
	return vmath.vector3(pv.x, pv.y, 0)
end

-- -------------------------------------------------------------------------

return {
	TransformVector 	= TransformVector,
	InvTransformVector 	= InvTransformVector,
	eulerAngles 		= eulerAngles,
	RotateEuler 		= RotateEuler, 
	VecEulerQuat 		= VecEulerQuat, 
	EulerFromQuat 		= EulerFromQuat,
	QuatLookAt			= QuatLookAt,
	orthogonalize 		= orthogonalize,

	ToQuaternion		= ToQuaternion,
	ToEulerAngles		= ToEulerAngles,
	DirToQuat			= DirToQuat,
	QuatToDir			= QuatToDir,

	lerp 				= lerp,
	sign 				= sign,

	WorldToScreen		= WorldToScreen,
	getProjection		= getProjection, 
}

-- -------------------------------------------------------------------------

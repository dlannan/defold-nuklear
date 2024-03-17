-- https://github.com/davisdude/Timer
--[[
Copyright (c) 2016 Davis Claiborne
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
	the following conditions:
	The above copyright notice and this permission notice shall be included
	in all copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	]]
	--[[
	TODO:
	- Decide how to handle timers where signal is called again (currently signal is removed)
	- Allow loops (i.e. thread "A" signals "D" which, after its completion, signals "A" again).
	- Asynchronous code (i.e. 2 loops can call a thread independently).
	- Nonlinear code (i.e. skip over segments to a waitSignal in the same thread)
	- Expose 'signal' outside of func environment, that way signals can be executed without having to create a new timer.
	- Error checking for signalled functions
	]]
	local signals = {}

	local function resumeCoroutine( co, ... )
		local passed, err = coroutine.resume( co, ... )
		assert( passed, 'Timer error: ' .. tostring( err ) )
		return passed
	end

	local function wait( process, seconds )
		local co = coroutine.running()
		local wakeUpTime = process.time + seconds
		process.times[co] = wakeUpTime
		return coroutine.yield( co )
	end

	local function checkThreads( process )
		for co, wakeUpTime in pairs( process.times ) do
			if process.time > wakeUpTime then
				process.times[co] = nil
				resumeCoroutine( co )
			end
		end
	end

	local function waitSignal( name )
		local co = coroutine.running()
		if signals[name] then
			table.insert( signals[name], co )
		else
			signals[name] = { co }
		end
		return coroutine.yield( co )
	end

	local toResume = {} -- Prevent bugs caused by coroutines starting then pausing wrong thread
	local function signal( name )
		for i, co in ipairs( signals[name] ) do
			if coroutine.status( co ) == 'suspended' then
				table.insert( toResume, co )
			end
		end
		signals[name] = nil
	end

	-- Wrapper function
	local function newProcess( func )
		local process = {
			time = 0,
			times = {},
			update = function( self, dt )
				self.time = self.time + dt
				checkThreads( self )
				for _, co in ipairs( toResume ) do
					resumeCoroutine( co )
				end
				toResume = {}
			end,
		}

		setfenv( func,
		setmetatable( {
			waitSignal = waitSignal, 
			signal = signal, 
			wait = function( seconds )
				process.time = 0
				return wait( process, seconds )
			end,
		}, {
			__index = getfenv( 0 ),
		} )
	)
	local co = coroutine.create( func )
	resumeCoroutine( co )

	return process
end

return {
	new = newProcess,
	wait = wait,
}
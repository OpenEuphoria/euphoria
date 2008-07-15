--****
-- == Multi-tasking
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--
-- === Routines

--**
-- Suspends a task for a short period, allowing other tasks to run in the meantime.
--
-- Parameters
--		# [[:delaytime]]: an atom, the duration of the delay in seconds.
--
-- Comments:
-- This procedure is similar to ##sleep##(), but allows for other tasks to run by yielding on a regular basis.
--
-- See Also:
-- [[:sleep]]
export procedure task_delay(atom delaytime)
	atom t
	t = time()

	while time() - t < delaytime do
		machine_proc(M_SLEEP, 0.01)
		task_yield()
	end while
end procedure

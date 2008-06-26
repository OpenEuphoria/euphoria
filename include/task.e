--****
-- == Multi-tasking
--
-- === Routines

--**
global procedure task_delay(atom delaytime)
-- akin to sleep, but allows other tasks to run while sleeping
--causes a delay while allowing other tasks to run.
	atom t
	t = time()

	while time() - t < delaytime do
		machine_proc(M_SLEEP, 0.01)
		task_yield()
	end while
end procedure

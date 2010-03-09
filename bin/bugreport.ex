--
-- Display common information that should be included with a bug report
--

include std/os.e
include euphoria/info.e

procedure pi(sequence title, object value)
	if sequence(value) and length(value) > 0 then
		printf(1, "%s\n----------------------------\n", { title })
		if sequence(value[1]) then
			for i = 1 to length(value) do
				printf(1, "%d: %s\n", { i, value[i] })
			end for
		else
			printf(1, "%s\n", { value })
		end if
		printf(1, "\n", {})
	end if
end procedure

pi("Version", version_string())
pi("Operating System", sprintf("Platform: %s, Build: %s, %s:%d", uname()))
pi("Include Directories", include_paths(0))
pi("EUDIR", getenv("EUDIR"))
pi("PATH", getenv("PATH"))

-- (c) Copyright 2008 Rapid Deployment Software - See License.txt
--
-- **Page Contents**
--
-- <<LEVELTOC depth=2>>
--

ifdef SAFE then
	export include safe.e
	ifdef DOS32 then
		export include .\dos\safe.e
	end ifdef
else
	export include memory.e
	ifdef DOS32 then
		export include .\dos\memory.e
	end ifdef
end ifdef




--****
-- === Pipe Input/Output
--
-- ==== Notes
-- Due to a bug, Euphoria does not handle STDERR properly
-- STDERR cannot captured for Euphoria programs (other programs will work fully)
-- Pipes does not work on DOS, as it relies on multitasking being possible
-- The IO functions currently work with file handles, a future version might wrap them in streams
-- so that they can be used directly alongside other file/socket/other-streams with a
-- stream_select() function.

--Namespace
namespace pipe

--Includes
include std/dll.e
include std/machine.e
include std/error.e

ifdef DOS32 then
	include std/io.e

	constant FAIL = 0
	enum
		READ,
		WRITE,
		CLOSE,
		PIPE,
		KILL,
		ERRNO

elsifdef WIN32 then
	constant
		kernel32 = open_dll("kernel32.dll"),
		iCreatePipe = define_c_func(kernel32,"CreatePipe",{C_POINTER,C_POINTER,C_POINTER,C_INT},C_INT),
		iReadFile = define_c_func(kernel32,"ReadFile",{C_UINT,C_POINTER,C_UINT,C_POINTER,C_POINTER},C_INT),
		iWriteFile = define_c_func(kernel32,"WriteFile",{C_INT,C_POINTER,C_INT,C_POINTER,C_POINTER},C_INT),
		iCloseHandle = define_c_func(kernel32,"CloseHandle",{C_INT},C_INT),
		iTerminateProcess=define_c_func(kernel32,"TerminateProcess",{C_UINT,C_UINT},C_INT),
		iGetLastError = define_c_func(kernel32,"GetLastError",{},C_INT),
		iGetStdHandle = define_c_func(kernel32,"GetStdHandle",{C_INT},C_INT),
		iSetHandleInformation = define_c_func(kernel32,"SetHandleInformation",{C_UINT,C_UINT,C_UINT},C_INT),
		iCreateProcess = define_c_func(kernel32,"CreateProcessA",{C_POINTER,C_POINTER,C_POINTER,
			C_POINTER,C_UINT,C_UINT,C_POINTER,C_POINTER,C_POINTER,C_POINTER},C_UINT),
		iGetExitCodeProcess=define_c_func(kernel32,"GetExitCodeProcess",{C_UINT,C_POINTER},C_INT)
	
	constant
		STD_INPUT_HANDLE = -10,
		STD_OUTPUT_HANDLE = -11,
		STD_ERROR_HANDLE = -12,
		FILE_INVALID_HANDLE = -1,
		ERROR_BROKEN_PIPE = 109,
		SA_SIZE = 12,
		PIPE_WRITE_HANDLE = 1, PIPE_READ_HANDLE=2,
		HANDLE_FLAG_INHERIT=1,
		SUIdwFlags = 44, 
		SUIhStdInput = 56, 
		STARTUPINFO_SIZE = 68,
		STARTF_USESHOWWINDOW = 1,
		STARTF_USESTDHANDLES = 256,
		PROCESS_INFORMATION_SIZE = 16,
		FAIL = 0
	
elsedef
	--*NIX-specific constants
	constant
		STDLIB = open_dll({ "", "libc.so", "libc.dylib" }),
		PIPE   = define_c_func(STDLIB, "pipe",   {C_POINTER}, C_INT),
		READ   = define_c_func(STDLIB, "read",   {C_INT, C_POINTER, C_INT}, C_INT),
		WRITE  = define_c_func(STDLIB, "write",  {C_INT, C_POINTER, C_INT}, C_INT),
		CLOSE  = define_c_func(STDLIB, "close",  {C_INT}, C_INT),
		DUP2   = define_c_func(STDLIB, "dup2",   {C_INT, C_INT}, C_INT),
		KILL   = define_c_func(STDLIB, "kill",   {C_INT, C_INT}, C_INT),
		FORK   = define_c_func(STDLIB, "fork",   {}, C_INT),
		EXECV  = define_c_func(STDLIB, "execv",  {C_POINTER, C_POINTER}, C_INT),
		SIGNAL = define_c_func(STDLIB, "signal", {C_INT, C_POINTER}, C_POINTER),
		ERRNO  = define_c_var( STDLIB, "errno"),
		FAIL   = -1
	
	enum
		os_stdin = 0, os_stdout, os_stderr,
		os_sig_dfl = 0, os_sig_ign
end ifdef

--****
-- === Accessor Constants

public enum
	--** Child processes standard input
	STDIN,
	--** Child processes standard output
	STDOUT,
	--** Child processes standard error
	STDERR,
	--** Process ID
	PID

public enum
	--** Set of pipes that are for the use of the parent
	PARENT,
	--** Set of pipes that are given to the child - should not be used by the parent
	CHILD

atom os_errno = 0


-- Common functions
function get_errno()
	ifdef WIN32 then
		return c_func(iGetLastError,{})
	elsifdef DOS32 then
		return 1
	elsedef
		return peek4u(ERRNO)
	end ifdef
end function

--****
-- === Opening/Closing

--**
-- Process Type

public type process(object o)
	if atom(o) then
		return 0
	end if

	if length(o) != 4 then
		return 0
	end if

	return 1
end type

--**
-- Close handle fd
--
-- Returns:
--   0 on success, -1 on failure
--
-- Example 1:
-- <eucode>
-- integer status=pipe:close(p[STDIN])
-- </eucode>
--

public function close(atom fd)
	atom ret

	ifdef DOS32 then
		if fd = -2 then
			return 0
		end if
		eu:close(fd)
		return 0
	end ifdef

	ifdef WIN32 then
		ret=c_func(iCloseHandle,{fd})
	elsedef
		ret=c_func(CLOSE, {fd})
	end ifdef
	
	if ret = FAIL then
		os_errno = get_errno()
		return -1
	end if
	
	return 0
end function

--**
-- Close pipes and kill process p with signal signal (default 15)
--
-- Comments:
--   Signal is ignored on Windows.
--
-- Example 1:
-- <eucode>
-- pipe:kill(p)
-- </eucode>
--

public procedure kill(process p, atom signal=15)
	atom ret

	ifdef DOS32 then
		return -- nop
	end ifdef
	
	--Close the pipes
	--If any fail its probably just because they were already closed, so that is ignored
	ret=close(p[STDIN])
	ret=close(p[STDOUT])
	ret=close(p[STDERR])
	
	--Error may result, but it is usually just because the process has already ended.
	ifdef WIN32 then
		--Not how to handle "signal", so its ignored on Windows for now
		ret=c_func(iTerminateProcess,{p[PID],0})
	elsedef
		ret=c_func(KILL, {p[PID], signal})
	end ifdef
end procedure

function os_pipe()
	sequence handles
	atom ret
	
	ifdef WIN32 then
		atom psaAttrib, phWriteToPipe, phReadFromPipe
		
		psaAttrib = allocate(SA_SIZE+2*4)
		poke4(psaAttrib,{SA_SIZE,0,1})
		phWriteToPipe = psaAttrib+SA_SIZE
		phReadFromPipe = psaAttrib+SA_SIZE+4
		ret = c_func(iCreatePipe,{phReadFromPipe,phWriteToPipe,psaAttrib,0})
		handles = peek4u({phWriteToPipe,2})
		free(psaAttrib)
	elsedef
		atom cmd = allocate(8)
		ret = c_func(PIPE,{cmd})
		handles = peek4u({cmd,2})
		free(cmd)
	end ifdef
	
	if ret = FAIL then
		os_errno = get_errno()
		return -1
	end if
	
	return handles
end function

--****
-- === Read/Write Process

--**
-- Read ##bytes## bytes from handle ##fd##
--
-- Returns:
--   sequence containing data, an empty sequence on EOF or an error code.
--   Similar to [[:get_bytes]].
--
-- Example 1:
-- <eucode>
-- sequence data=pipe:read(p[STDOUT],256)
-- </eucode>
--

public function read(atom fd, integer bytes)
	ifdef DOS32 then
		if fd = -2 then
			return ""
		end if
		return get_bytes(fd, bytes)
	end ifdef

	if bytes=0 then return "" end if

	sequence data
	atom
		ret, ReadCount,
		buf = allocate(bytes)
	
	ifdef WIN32 then
		atom pReadCount=allocate(4)
		ret = c_func(iReadFile,{fd,buf,bytes,pReadCount,0})
		ReadCount=peek4u(pReadCount)
		free(pReadCount)
	elsedef
		ret = c_func(READ, {fd, buf, bytes})
		ReadCount=ret
	end ifdef
	
	if ret = FAIL then
		os_errno = get_errno()
		free(buf)
		return ""
	end if
	
	data=peek({buf,ReadCount})
	
	free(buf)
	
	return data
end function

--****
-- Write ##bytes## to handle ##fd##
--
-- Returns:
--   number of bytes written, or -1 on error
--
-- Example 1:
-- <eucode>
-- integer bytes_written=pipe:write(p[STDIN],"Hello World!")
-- </eucode>
--

public function write(atom fd, sequence str)
	ifdef DOS32 then
		if fd = -2 then
			return length(str)
		end if
		puts(fd, str)
		return length(str)
	end ifdef

	atom
	--	fd = p[2],
		buf = allocate_string(str),
		ret,WrittenCount
	
	ifdef WIN32 then
		atom pWrittenCount=allocate(4)
		ret=c_func(iWriteFile,{fd,buf,length(str),pWrittenCount,0})
		WrittenCount=peek4u(pWrittenCount)
		free(pWrittenCount)
	elsedef
		ret = c_func(WRITE, {fd, buf, length(str)})
		WrittenCount=ret
	end ifdef
	
	free(buf)
	
	if ret = FAIL then
		os_errno = get_errno()
		return -1
	end if

	return WrittenCount
end function

procedure error()
    crash(sprintf("Errno = %d", os_errno))
end procedure

--**
-- Get error no from last call to a pipe function
--
-- Comments:
--   Value returned will be OS-specific, and is not always set on Windows at least
--
-- Example 1:
-- <eucode>
-- integer error=pipe:error_no()
-- </eucode>
--
public function error_no()
	return os_errno
end function

ifdef WIN32 then
	--WIN32-specific functions
	function GetStdHandle(atom device)
		return c_func(iGetStdHandle,{device})
	end function
	
	function SetHandleInformation(atom hObject, atom dwMask, atom dwFlags)
		return c_func(iSetHandleInformation,{hObject,dwMask,dwFlags})
	end function
	
	procedure CloseAllHandles(sequence handles)
	atom ret
	   for i = 1 to length(handles) do
	     ret=close(handles[i])
	   end for
	end procedure
	
	function CreateProcess(sequence CommandLine,sequence StdHandles)
	object fnVal
	atom pPI, pSUI, pCmdLine
	sequence ProcInfo
	
	   pCmdLine = allocate_string(CommandLine)
	   pPI = allocate(PROCESS_INFORMATION_SIZE)
	   mem_set(pPI,0,PROCESS_INFORMATION_SIZE)
	   pSUI = allocate(STARTUPINFO_SIZE)
	   mem_set(pSUI,0,STARTUPINFO_SIZE)
	   poke4(pSUI,STARTUPINFO_SIZE)
	   poke4(pSUI+SUIdwFlags,or_bits(STARTF_USESTDHANDLES,STARTF_USESHOWWINDOW))
	   poke4(pSUI+SUIhStdInput,StdHandles)
	   fnVal = c_func(iCreateProcess,{0,pCmdLine,0,0,1,0,0,0,pSUI,pPI})
	   free(pCmdLine)
	   free(pSUI)
	   ProcInfo = peek4u({pPI,4})
	   free(pPI)
	   if not fnVal then
	     return 0
	   end if
	   return ProcInfo
	end function -- CreateProcess()

	--WIN32 version of create()

	--**
	-- Create pipes for interprocess communication
	--
	-- Returns:
	--   Returns process handles { {parent side pipes},{child side pipes} }
	--
	-- Example 1:
	-- <eucode>
	-- object p=pipe:exec("dir", pipe:create())
	-- </eucode>
	--
	public function create()
	atom hChildStdInRd,hChildStdOutWr, hChildStdErrWr, -- handles used by child process
	     hChildStdInWr, hChildStdOutRd,hChildStdErrRd  -- handles used by parent process
	
	object
	  StdInPipe = {},
	  StdOutPipe = {},
	  StdErrPipe = {}
	  
	object fnVal

	  -- capture chid process std input
	    StdInPipe = os_pipe()
	    if atom(StdInPipe) then return -1 end if
	    hChildStdInRd = StdInPipe[PIPE_READ_HANDLE]
	    hChildStdInWr = StdInPipe[PIPE_WRITE_HANDLE]
	  
	  
	  -- capture child process std output  
	    StdOutPipe = os_pipe()
	    if atom(StdOutPipe) then 
	      CloseAllHandles(StdInPipe)
	      return -1
	    end if
	    hChildStdOutWr = StdOutPipe[PIPE_WRITE_HANDLE]
	    hChildStdOutRd = StdOutPipe[PIPE_READ_HANDLE]
	  
	  -- capture child process std error
	    StdErrPipe = os_pipe()
	    if atom(fnVal) then
	       CloseAllHandles(StdErrPipe & StdOutPipe)
	       return -1
	    end if
	    hChildStdErrWr = StdErrPipe[PIPE_WRITE_HANDLE]
	    hChildStdErrRd = StdErrPipe[PIPE_READ_HANDLE]

	    fnVal = SetHandleInformation(StdInPipe[PIPE_WRITE_HANDLE],HANDLE_FLAG_INHERIT,0)
	    fnVal = SetHandleInformation(StdOutPipe[PIPE_READ_HANDLE],HANDLE_FLAG_INHERIT,0)
	    fnVal = SetHandleInformation(StdErrPipe[PIPE_READ_HANDLE],HANDLE_FLAG_INHERIT,0)

	  return {{hChildStdInWr,hChildStdOutRd,hChildStdErrRd},
	         {hChildStdInRd,hChildStdOutWr,hChildStdErrWr}}
	  
	end function
	
	--WIN32 version of exec()

	--**
	-- Open process with command line cmd
	--
	-- Returns:
	--   Returns process handles { [[:PID]], [[:STDIN]], [[:STDOUT]], [[:STDERR]] }
	--
	-- Example 1:
	-- <eucode>
	-- object p=pipe:exec("dir", pipe:create())
	-- </eucode>
	--

	public function exec(sequence cmd, sequence pipe)
	object fnVal
	atom hChildStdInRd,hChildStdOutWr, hChildStdErrWr, -- handles used by child process
	     hChildStdInWr, hChildStdOutRd,hChildStdErrRd  -- handles used by parent process
	atom ret
	
	hChildStdInWr = pipe[1][1]
	hChildStdOutRd = pipe[1][2]
	hChildStdErrRd = pipe[1][3]
	hChildStdInRd = pipe[2][1]
	hChildStdOutWr = pipe[2][2]
	hChildStdErrWr = pipe[2][3]

	atom hChildProcess
	
	  -- create child process
	  fnVal = CreateProcess(cmd,{hChildStdInRd,hChildStdOutWr,hChildStdErrWr})
	  if atom(fnVal) then
	    return -1
	  end if
	  hChildProcess = fnVal[1]
	  ret=close(fnVal[2]) -- hChildThread not needed.
	
	     ret=close(hChildStdInRd)
	  
	     ret=close(hChildStdOutWr)
	  
	     ret=close(hChildStdErrWr)
	  
	  return {hChildStdInWr,hChildStdOutRd,hChildStdErrRd,hChildProcess}
	
	end function
elsifdef DOS32 then
	public function create()
		return {{open("tempfile.tmp", "wb"),-2,-2},{-2,-2,-2}}
	end function

	public function exec(sequence cmd, sequence pipe)
		close(pipe[1][1])
		system(cmd&" < tempfile.tmp > tempfil2.tmp", 2)
		return {-2,open("tempfil2.tmp", "rb"),-2,0}
	end function
elsedef
	--*NIX-specific functions
	function os_dup2(atom oldfd, atom newfd)
		atom r = c_func(DUP2, {oldfd, newfd})
		if r = -1 then
			os_errno = peek4u(ERRNO)
			return -1
		end if
		
		return r
	end function
	
	function os_fork()
		atom pid = c_func(FORK, {})
		if pid = -1 then
			os_errno = peek4u(ERRNO)
			return -1
		end if
		
		return pid
	end function
	
	function os_execv(sequence s, sequence v)
		atom sbuf
		atom vbuf
		sequence vbufseq
		atom r
		
		sbuf = allocate_string(s)
		vbufseq = {sbuf}--http://www.cs.toronto.edu/~demke/369S.07/OS161_man/syscall/execv.html
		
		for i = 1 to length(v) do
			vbufseq &= allocate_string(v[i])
		end for
		
		vbufseq &= 0
		vbuf = allocate(length(vbufseq)*4)
		poke4(vbuf, vbufseq)
		r = c_func(EXECV, {sbuf, vbuf}) -- execv() should never return
		os_errno = peek4u(ERRNO)
		return -1
	end function
	
	function os_signal(integer signal, atom handler)
		return c_func(SIGNAL, {signal, handler})
	end function

	--*NIX version of create()
	
	--See docs above in WIN32 version
	public function create()
	    object ipipe,opipe,epipe
	    integer ret
		
		--Create pipes
		ipipe=os_pipe()
		if atom(ipipe) then
			return -1
	    end if
	    
		opipe=os_pipe()
		if atom(opipe) then
			ret=close(ipipe[1])
			ret=close(ipipe[2])
			return -1
	    end if
	    
	    epipe=os_pipe()
		if atom(epipe) then
			ret=close(ipipe[1])
			ret=close(ipipe[2])
			ret=close(opipe[1])
			ret=close(opipe[2])
			return -1
	    end if
	    return {{ipipe[2],opipe[1],epipe[1]},{ipipe[1],opipe[2],epipe[2]}}
	end function
	
	--Linux takes parameters as a sequence of args,
	--so this is wrapped in a function below to make it compatible with the Windows implementation
	function exec_args(sequence command,sequence args, sequence pipe)
	    atom pid
	    integer ret
	    sequence p
	    object ipipe,opipe,epipe

	    ipipe = pipe[2][1] & pipe[1][1]
	    opipe = pipe[1][2] & pipe[2][2]
	    epipe = pipe[1][3] & pipe[2][3]
	    
		--Fork
	    pid=os_fork()
		
	    if pid=0 then
	    	--Child process
	    	
			--Not much can really be done about errors at this stage,
			--so most are left unchecked
			
			--Close the sides we don't need, otherwise they will be left hanging
			ret=close(ipipe[2])
			ret=close(opipe[1])
			ret=close(epipe[1])
			
			--What does this do?
			ret=os_signal(15, os_sig_dfl)--15 = sigterm
			
			--dup our pipe descriptors to STD*, then close them so they aren't left hanging
			ret=os_dup2(ipipe[1], os_stdin)
			ret=close(ipipe[1])
	
			ret=os_dup2(opipe[2], os_stdout)
			ret=close(opipe[2])
			
			ret=os_dup2(epipe[2], os_stderr)
			ret=close(epipe[2])
			
			--Replace the forked child process with the process we intend to launch
			ret=os_execv(command,args)
			
			--We should never reach this, so its an error no matter what happens
			error()
	    elsif pid=-1 then
	    	--Failed to fork
	    	--Close all the descriptors
			ret=close(ipipe[1])
			ret=close(ipipe[2])
			ret=close(opipe[1])
			ret=close(opipe[2])
			ret=close(epipe[1])
			ret=close(epipe[2])
			return -1
		else
			--Parent process
			
			--Process info
			p={ipipe[2], opipe[1], epipe[1], pid}
			
			--Close the sides we don't need, otherwise they will be left hanging
			ret=close(ipipe[1])
			ret=close(opipe[2]) or ret
			ret=close(epipe[2]) or ret
			
			--If any failed to close, something is wrong with them, so bail out
			if ret then
				kill(p)
				return -1
			end if
			
		    return p
   		end if
	end function
	
	--*NIX version of exec()
	
	--See docs above in WIN32 version
	public function exec(sequence cmd, sequence pipe)
		--*NIX needs exe and args seperated,
		--but for Windows compatibility, we need to accept a command line
		
		--PHP's proc_open() does it this way.
		--If there is a better way, please fix it.
		--Need to make sure this works on all *NIX platforms
		return exec_args("/bin/sh",{"-c", cmd}, pipe)
	end function
end ifdef

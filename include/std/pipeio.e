--****
-- == Pipe Input and Output
--
-- <<LEVELTOC level=2 depth=4>>
--
-- === Notes
-- Due to a bug, Euphoria does not handle ##STDERR## properly.
-- ##STDERR## cannot captured for Euphoria programs (other programs will work fully)
-- The IO functions currently work with file handles, a future version might wrap them in streams
-- so that they can be used directly alongside other file/socket/other-streams with a
-- ##stream_select## function.
--

namespace pipeio

include std/dll.e
include std/error.e
include std/machine.e

ifdef WINDOWS then
	constant
		kernel32 = dll:open_dll("kernel32.dll"),
		--iGetExitCodeProcess=define_c_func(kernel32,"GetExitCodeProcess",{C_UINT,C_POINTER},C_INT),
		iCreatePipe = dll:define_c_func(kernel32,"CreatePipe",{dll:C_POINTER, dll:C_POINTER, dll:C_POINTER, dll:C_DWORD},dll:C_BOOL),
		iReadFile = dll:define_c_func(kernel32,"ReadFile",{dll:C_POINTER, dll:C_POINTER, dll:C_DWORD, dll:C_POINTER, dll:C_POINTER}, dll:C_BOOL),
		iWriteFile = dll:define_c_func(kernel32,"WriteFile",{dll:C_POINTER, dll:C_POINTER, dll:C_DWORD, dll:C_POINTER, dll:C_POINTER}, dll:C_BOOL),
		iCloseHandle = dll:define_c_func(kernel32,"CloseHandle",{dll:C_POINTER}, dll:C_BOOL),
		iTerminateProcess=dll:define_c_func(kernel32,"TerminateProcess",{dll:C_POINTER, dll:C_UINT}, dll:C_BOOL),
		iGetLastError = dll:define_c_func(kernel32,"GetLastError",{},dll:C_DWORD),
		iGetStdHandle = dll:define_c_func(kernel32,"GetStdHandle",{dll:C_DWORD}, dll:C_HANDLE),
		iSetHandleInformation = dll:define_c_func(kernel32,"SetHandleInformation",{dll:C_POINTER, dll:C_DWORD, dll:C_DWORD}, dll:C_BOOL),
		iCreateProcess = dll:define_c_func(kernel32,"CreateProcessA",{dll:C_POINTER, dll:C_POINTER, dll:C_POINTER,
			dll:C_POINTER, dll:C_BOOL, dll:C_DWORD, dll:C_POINTER, dll:C_POINTER, dll:C_POINTER, dll:C_POINTER},dll:C_BOOL)
	
	constant
		PIPE_WRITE_HANDLE = 1, PIPE_READ_HANDLE=2,
		HANDLE_FLAG_INHERIT=1,
		STARTF_USESHOWWINDOW = 1,
		STARTF_USESTDHANDLES = 256,
		FAIL = 0,
		$
ifdef BITS32 then
	constant
		SA_SIZE = 12,
		SUIdwFlags = 44, 
		SUIhStdInput = 56, 
		STARTUPINFO_SIZE = 68,
		PROCESS_INFORMATION_SIZE = 16,
		$
elsedef
	constant
		SA_SIZE = 24,
		SUIdwFlags = 60, 
		SUIhStdInput = 80, 
		STARTUPINFO_SIZE = 104,
		PROCESS_INFORMATION_SIZE = 24,
		$
	
end ifdef
elsedef
	constant
		STDLIB = dll:open_dll({ "libc.so", "libc.dylib", "" }),
		PIPE   = dll:define_c_func(STDLIB, "pipe",   {dll:C_POINTER}, dll:C_INT),
		READ   = dll:define_c_func(STDLIB, "read",   {dll:C_INT, dll:C_POINTER, dll:C_POINTER}, dll:C_LONG),
		WRITE  = dll:define_c_func(STDLIB, "write",  {dll:C_INT, dll:C_POINTER, dll:C_POINTER}, dll:C_LONG),
		CLOSE  = dll:define_c_func(STDLIB, "close",  {dll:C_INT}, dll:C_INT),
		DUP2   = dll:define_c_func(STDLIB, "dup2",   {dll:C_INT, dll:C_INT}, dll:C_INT),
		KILL   = dll:define_c_func(STDLIB, "kill",   {dll:C_INT, dll:C_INT}, dll:C_INT),
		FORK   = dll:define_c_func(STDLIB, "fork",   {}, dll:C_INT),
		EXECV  = dll:define_c_func(STDLIB, "execv",  {dll:C_POINTER, dll:C_POINTER}, dll:C_INT),
		SIGNAL = dll:define_c_func(STDLIB, "signal", {dll:C_INT, dll:C_POINTER}, dll:C_POINTER),
		ERRNO  = dll:define_c_var( STDLIB, "errno"),
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

--
public enum
	--** Set of pipes that are for the use of the parent
	PARENT,
	--** Set of pipes that are given to the child ~-- should not be used by the parent
	CHILD

--
atom os_errno = 0

-- Common functions
function get_errno()
	ifdef WINDOWS then
		return c_func(iGetLastError,{})
	elsedef
		return peek4u(ERRNO)
	end ifdef
end function

--****
-- === Opening and Closing

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
-- closes handle ##fd##.
--
-- Returns:
--   An **integer**, 0 on success, -1 on failure
--
-- Example 1:
-- <eucode>
-- integer status = pipeio:close(p[STDIN])
-- </eucode>
--

public function close(atom fd)
	atom ret

	ifdef WINDOWS then
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
-- closes pipes and kills process ##p## with signal signal (default 15).
--
-- Comments:
--   Signal is ignored on //Windows//.
--
-- Example 1:
-- <eucode>
-- kill(p)
-- </eucode>
--

public procedure kill(process p, atom signal=15)

	close(p[STDIN])
	close(p[STDOUT])
	close(p[STDERR])
	
	ifdef WINDOWS then
		c_func(iTerminateProcess,{p[PID],signal and 0})
	elsedef
		c_func(KILL, {p[PID], signal})
	end ifdef
end procedure

function os_pipe()
	sequence handles
	atom ret
	
	ifdef WINDOWS then
		atom psaAttrib, phWriteToPipe, phReadFromPipe
		
		psaAttrib = machine:allocate(SA_SIZE + 2 * sizeof( C_POINTER ) )
		poke4( psaAttrib, SA_SIZE )
		poke_pointer(psaAttrib + sizeof( C_POINTER),{0,1})
		
		phWriteToPipe = psaAttrib + SA_SIZE
		phReadFromPipe = psaAttrib + SA_SIZE + sizeof( C_POINTER )
		
		ret = c_func(iCreatePipe,{phReadFromPipe,phWriteToPipe,psaAttrib,0})
		handles = peek_pointer({phWriteToPipe,2})
		
		machine:free(psaAttrib)
	elsedef
		atom cmd = machine:allocate(8)
		ret = c_func(PIPE,{cmd})
		handles = peek4u({cmd,2})
		machine:free(cmd)
	end ifdef
	
	if ret = FAIL then
		os_errno = get_errno()
		return -1
	end if
	
	return handles
end function

--****
-- === Read and Write Process

--**
-- reads ##bytes## bytes from handle ##fd##.
--
-- Returns:
--   A **sequence**, containing data, an empty sequence on EOF or an error code.
--   Similar to [[:get_bytes]].
--
-- Example 1:
-- <eucode>
-- sequence data=read(p[STDOUT],256)
-- </eucode>
--

public function read(atom fd, integer bytes)
	if bytes=0 then return "" end if

	sequence data
	atom
		ret, ReadCount,
		buf = allocate(bytes)
	
	ifdef WINDOWS then
		atom pReadCount=machine:allocate(4)
		ret = c_func(iReadFile,{fd,buf,bytes,pReadCount,0})
		ReadCount=peek4u(pReadCount)
		machine:free(pReadCount)
	elsedef
		ret = c_func(READ, {fd, buf, bytes})
		ReadCount=ret
	end ifdef
	
	if ret = FAIL then
		os_errno = get_errno()
		machine:free(buf)
		return ""
	end if
	
	data=peek({buf,ReadCount})
	machine:free(buf)
	
	return data
end function

--**
-- writes ##bytes## to handle ##fd##.
--
-- Returns:
--   An **integer**, number of bytes written, or -1 on error
--
-- Example 1:
-- <eucode>
-- integer bytes_written = write(p[STDIN],"Hello World!")
-- </eucode>
--

public function write(atom fd, sequence str)
	atom
		buf = allocate_string(str),
		ret,WrittenCount
	
	ifdef WINDOWS then
		atom pWrittenCount=machine:allocate(4)
		ret=c_func(iWriteFile,{fd,buf,length(str),pWrittenCount,0})
		WrittenCount=peek4u(pWrittenCount)
		machine:free(pWrittenCount)
	elsedef
		ret = c_func(WRITE, {fd, buf, length(str)})
		WrittenCount=ret
	end ifdef
	
	machine:free(buf)
	
	if ret = FAIL then
		os_errno = get_errno()
		return -1
	end if

	return WrittenCount
end function

procedure error()
    error:crash(sprintf("Errno = %d", os_errno))
end procedure

--**
-- gets error no from last call to a pipe function.
--
-- Comments:
--   Value returned will be OS-specific, and is not always set on //Windows// at least
--
-- Example 1:
-- <eucode>
-- integer error = error_no()
-- </eucode>
--
public function error_no()
	return os_errno
end function

ifdef WINDOWS then
	function GetStdHandle(atom device)
		return c_func(iGetStdHandle,{device})
	end function
	
	function SetHandleInformation(atom hObject, atom dwMask, atom dwFlags)
		return c_func(iSetHandleInformation,{hObject,dwMask,dwFlags})
	end function
	
	procedure CloseAllHandles(sequence handles)
	   for i = 1 to length(handles) do
	     close(handles[i])
	   end for
	end procedure
	
	function CreateProcess(sequence CommandLine,sequence StdHandles)
	object fnVal
	atom pPI, pSUI, pCmdLine
	sequence ProcInfo
	
		pCmdLine = machine:allocate_string(CommandLine)
		
		pPI = machine:allocate(PROCESS_INFORMATION_SIZE)
		mem_set(pPI,0,PROCESS_INFORMATION_SIZE)
		
		pSUI = machine:allocate(STARTUPINFO_SIZE)
		mem_set( pSUI, 0, STARTUPINFO_SIZE)
		poke4( pSUI, STARTUPINFO_SIZE)
		poke4( pSUI + SUIdwFlags, or_bits( STARTF_USESTDHANDLES, STARTF_USESHOWWINDOW ) )
		poke_pointer( pSUI + SUIhStdInput, StdHandles)
		
		fnVal = c_func(iCreateProcess,{0,pCmdLine,0,0,1,0,0,0,pSUI,pPI})
		machine:free(pCmdLine)
		machine:free(pSUI)
		ifdef BITS32 then
			ProcInfo = peek4u({pPI,4})
		elsedef
			ProcInfo = peek_pointer( {pPI, 2} ) & peek4u( {pPI + 16, 2})
		end ifdef
		machine:free(pPI)
		if not fnVal then
			return 0
		end if
		return ProcInfo
	end function

	--**
	-- creates pipes for inter-process communication.
	--
	-- Returns:
	--   A **handle**, process handles { {parent side pipes},{child side pipes} }
	--
	-- Example 1:
	-- <eucode>
	-- object p = exec("dir", create())
	-- </eucode>
	--
	public function create()
	atom hChildStdInRd,hChildStdOutWr, hChildStdErrWr,
	     hChildStdInWr, hChildStdOutRd,hChildStdErrRd
	
	object
	  StdInPipe = {},
	  StdOutPipe = {},
	  StdErrPipe = {}
	  
	    StdInPipe = os_pipe()
	    if atom(StdInPipe) then return -1 end if
	    hChildStdInRd = StdInPipe[PIPE_READ_HANDLE]
	    hChildStdInWr = StdInPipe[PIPE_WRITE_HANDLE]
	  
	    StdOutPipe = os_pipe()
	    if atom(StdOutPipe) then 
	      CloseAllHandles(StdInPipe)
	      return -1
	    end if
	    hChildStdOutWr = StdOutPipe[PIPE_WRITE_HANDLE]
	    hChildStdOutRd = StdOutPipe[PIPE_READ_HANDLE]
	  
	    StdErrPipe = os_pipe()
	    if atom(StdErrPipe) then
	       CloseAllHandles(StdErrPipe & StdOutPipe)
	       return -1
	    end if
	    hChildStdErrWr = StdErrPipe[PIPE_WRITE_HANDLE]
	    hChildStdErrRd = StdErrPipe[PIPE_READ_HANDLE]

	    SetHandleInformation(StdInPipe[PIPE_WRITE_HANDLE],HANDLE_FLAG_INHERIT,0)
	    SetHandleInformation(StdOutPipe[PIPE_READ_HANDLE],HANDLE_FLAG_INHERIT,0)
	    SetHandleInformation(StdErrPipe[PIPE_READ_HANDLE],HANDLE_FLAG_INHERIT,0)

	  return {{hChildStdInWr,hChildStdOutRd,hChildStdErrRd},
	         {hChildStdInRd,hChildStdOutWr,hChildStdErrWr}}
	  
	end function
	
	--WIN32 version of exec()

	--**
	-- opens process with command line cmd.
	--
	-- Returns:
	--   A **handle**, process handles { [[:PID]], [[:STDIN]], [[:STDOUT]], [[:STDERR]] }
	--
	-- Example 1:
	-- <eucode>
	-- object p = exec("dir", create())
	-- </eucode>
	--

	public function exec(sequence cmd, sequence pipe)
	object fnVal
	atom hChildStdInRd,hChildStdOutWr, hChildStdErrWr,
	     hChildStdInWr, hChildStdOutRd,hChildStdErrRd
	
	hChildStdInWr = pipe[1][1]
	hChildStdOutRd = pipe[1][2]
	hChildStdErrRd = pipe[1][3]
	hChildStdInRd = pipe[2][1]
	hChildStdOutWr = pipe[2][2]
	hChildStdErrWr = pipe[2][3]

	atom hChildProcess
	
	  fnVal = CreateProcess(cmd,{hChildStdInRd,hChildStdOutWr,hChildStdErrWr})
	  if atom(fnVal) then
	    return -1
	  end if
	  hChildProcess = fnVal[1]
	  close(fnVal[2])
	
	  close(hChildStdInRd)
	  
	  close(hChildStdOutWr)
	  
	  close(hChildStdErrWr)
	  
	  return {hChildStdInWr, hChildStdOutRd, hChildStdErrRd, hChildProcess}
	
	end function

elsedef

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
		
		sbuf = machine:allocate_string(s)
		vbufseq = {sbuf}
		
		for i = 1 to length(v) do
			vbufseq &= machine:allocate_string(v[i])
		end for
		
		vbufseq &= 0
		vbuf = machine:allocate(length(vbufseq) * sizeof( C_POINTER ) )
		poke_pointer(vbuf, vbufseq)
		r = c_func(EXECV, {sbuf, vbuf})
		os_errno = peek4u(ERRNO)
		return -1
	end function
	
	function os_signal(integer signal, atom handler)
		return c_func(SIGNAL, {signal, handler})
	end function

	--See docs above in WIN32 version
	public function create()
	    object ipipe,opipe,epipe
	    integer ret
		
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
	
	function exec_args(sequence command,sequence args, sequence pipe)
	    atom pid
	    integer ret
	    sequence p
	    object ipipe,opipe,epipe

	    ipipe = pipe[2][1] & pipe[1][1]
	    opipe = pipe[1][2] & pipe[2][2]
	    epipe = pipe[1][3] & pipe[2][3]
	    
	    pid=os_fork()
		
	    if pid=0 then
			ret=close(ipipe[2])
			ret=close(opipe[1])
			ret=close(epipe[1])
			
			ret=os_signal(15, os_sig_dfl)
			
			ret=os_dup2(ipipe[1], os_stdin)
			ret=close(ipipe[1])
	
			ret=os_dup2(opipe[2], os_stdout)
			ret=close(opipe[2])
			
			ret=os_dup2(epipe[2], os_stderr)
			ret=close(epipe[2])
			
			ret=os_execv(command,args)
			
			error()
	    elsif pid=-1 then
			ret=close(ipipe[1])
			ret=close(ipipe[2])
			ret=close(opipe[1])
			ret=close(opipe[2])
			ret=close(epipe[1])
			ret=close(epipe[2])
			return -1
		else
			
			p={ipipe[2], opipe[1], epipe[1], pid}
			
			ret=close(ipipe[1])
			ret=close(opipe[2]) or ret
			ret=close(epipe[2]) or ret
			
			if ret then
				kill(p)
				return -1
			end if
			
		    return p
   		end if
	end function
	
	--See docs above in WIN32 version
	public function exec(sequence cmd, sequence pipe)
		return exec_args("/bin/sh",{"-c", cmd}, pipe)
	end function
end ifdef

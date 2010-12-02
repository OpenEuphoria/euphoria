
print_platform.exe: print_platform.ex
	eubind -con print_platform.ex

clean:
	del print_platform.exe
	
.error:
	pause

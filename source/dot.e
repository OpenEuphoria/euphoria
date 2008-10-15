include global.e
include std/get.e
include std/map.e as map
include std/sequence.e
include std/search.e
include std/sets.e as set
include std/math.e

-- called_from:  file -> proc -> called_proc file : called proc
-- called_by  :  called_proc file -> called proc -> file : proc
export map:map called_from = map:new()
export map:map called_by   = map:new()
export map:map proc_names  = map:new()

-- file, token (proc/func), scope, proc sym : 0
map:map cluster

export sequence short_names = {}
export sequence std_libs    = {}
export integer  show_stdlib = 0

export constant
	INTER_FILE = 1,
	INTRA_FILE = 2,
	ALL_FILES  = 3
	
export constant
	CALL_BY   = 1,
	CALL_FROM = 2,
	ALL_CALLS = 3


-- reset any local variables
procedure new_diagram()
	cluster = map:new()
end procedure


function edges( map:map call_map, integer proc, integer files, integer direction )
	integer file = SymTab[proc][S_FILE_NO]
	map:map proc_map = new_extra( map:nested_get( call_map, { file, proc } ) )
	sequence from_files = map:keys( proc_map )
	
	sequence lines = {}
	for i = 1 to length( from_files ) do
		if and_bits( INTER_FILE, files ) or file = from_files[i] then
			
			map:map file_map = new_extra( map:get( proc_map, from_files[i]) )
			sequence procs = map:keys( file_map )
			sequence edge_lines = ""
			integer edge_count = 0
			for j = 1 to length( procs ) do
				integer called_proc = procs[j]
				
				if called_proc then
					symtab_entry sym_ent = SymTab[called_proc]
					sequence caller, callee
					if direction = CALL_FROM then
						caller = SymTab[proc][S_NAME]
						callee = SymTab[called_proc][S_NAME]
					else
						callee = SymTab[proc][S_NAME]
						caller = SymTab[called_proc][S_NAME]
					end if
					
					map:nested_put( cluster, {direction, from_files[i], sym_ent[S_TOKEN], sym_ent[S_SCOPE], called_proc}, 0 )
					edge_lines &= sprintf("\t\"%s\" -> \"%s\"\n", { caller, callee } )
					integer count = map:get( file_map, called_proc, 1 )
					if count > 1 then
						edge_lines &= sprintf("\t[label=\"%d\"]\n", count )
					end if
					edge_count += 1
				end if
			end for
			
			lines &= edge_lines
			
		end if
	end for
	
	return lines
end function

function clusters()
	sequence lines = {}
	sequence call_type = map:keys( cluster )
	for ct = 1 to length( call_type ) do
		map:map file_map = new_extra( map:get( cluster, call_type[ct]) )
		sequence files = map:keys( file_map )
		for f = 1 to length( files ) do
			integer fn = files[f]
			if call_type[ct] then
				lines &= sprintf("\tsubgraph \"cluster_%d_%d\" {\n\t\tlabel = \"%s\"\n\t\tcolor = blue\n", 
						{ call_type[ct], fn, file_name[fn] } )
			else
				lines &= sprintf("\tsubgraph \"cluster_target\" {\n\t\tlabel = \"%s\"\n\t\tcolor = blue\n", 
						{ file_name[fn] } )
			end if
			map:map token_map = new_extra( map:get( file_map, fn) )
			sequence tokens = map:keys( token_map )
			for t = 1 to length( tokens ) do
				sequence fill
				integer token = tokens[t]
				if token = PROC then
					fill = ",style=filled,color=lightgrey"
				else
					fill = ",style=\"\""
				end if
				
				map:map scope_map = new_extra( map:get( token_map, token) )
				sequence scopes = map:keys( scope_map )
				for s = 1 to length( scopes ) do
					integer scope = scopes[s]
					sequence shape
					if scope = SC_LOCAL then
						shape = "shape=ellipse"
					elsif scope = SC_EXPORT then
						shape = "shape=diamond"
					else
						shape = "shape=box"
					end if
					
					map:map proc_map = new_extra( map:get( scope_map, scope) )
					sequence procs = map:keys( proc_map )
					lines &= sprintf( "\t\t\tnode [%s%s]\n", {shape, fill})
					for p = 1 to length( procs ) do
						symtab_index proc = procs[p]
						lines &= sprintf( "\t\t\t\"%s\"\n", {SymTab[proc][S_NAME]} )
					end for -- procs
				end for -- scopes
			end for  -- tokens
			lines &= "\t}\n" -- end of the subgraph
		end for -- files
	end for -- call types
	return  lines
end function

export function diagram_routine( object proc, integer files = ALL_FILES, integer calls = ALL_CALLS )
	integer same_file  = and_bits( INTRA_FILE, files )
	integer other_file = and_bits( INTER_FILE, files )
	
	new_diagram()
	
	if sequence( proc ) then
		proc = map:get( proc_names, proc, 0 )
	end if
	
	if not proc then
		return ""
	end if
	
	sequence lines = {}
	lines = ""
	integer fn = SymTab[proc][S_FILE_NO]
	
	map:nested_put( cluster, {0, fn, SymTab[proc][S_TOKEN], SymTab[proc][S_SCOPE], proc}, 0 )
	
	if and_bits( calls, CALL_BY ) then
		lines &= edges( called_by, proc, files, CALL_BY )
	end if
	
	if and_bits( calls, CALL_FROM ) then
		lines &= edges( called_from, proc, files, CALL_FROM )
	end if
	
	return sprintf("digraph %s { rankdir=BT ratio=auto \n", {SymTab[proc][S_NAME]}) & clusters() & lines & "}\n"
end function

export procedure short_files()
	short_names = file_name
	
	for f = 1 to length( short_names ) do
		-- just the short name
		sequence name = short_names[f]
		name = find_replace( '\\', name, '/' )
		file_name[f] = name
		for r = length( name ) to 1 by -1 do
			if name[r] = '/' then
				name = name[r+1..$]
				exit
			end if
		end for
		short_names[f] = name
	end for
	std_libs = repeat( 0, length( short_names ) )
	for i = 1 to length( file_name ) do
		if match( "std/", file_name[i]) then
			short_names[i] = "std/" & short_names[i]
			if not show_stdlib then
				-- we only care if user doesn't want to show it
				std_libs[i] = 1
			end if
		end if
	end for
end procedure

export function diagram_includes( integer show_all = 0, integer stdlib = 0)
	sequence lines = "digraph include { rankdir=TB ranksep=1.5 style=filled color=lightgrey node [shape=box] \n"
	
	lines &= "\tsubgraph \"cluster_stdlib\"{ rank=max\n"
	for i = 1 to length(short_names) do
		if match( "std/", short_names[i] ) = 1 then
			if stdlib then
				lines &= sprintf( "\"%s\"\n", {short_names[i]})
			end if
		end if
	end for
	lines &= "\t}\n"
	
	set:set included = {}
	for fi = 1 to length( file_include ) do
		for i = 1 to length( file_include[fi] ) do
			integer file = abs( file_include[fi][i])
			if show_all or not set:belongs_to( file, included ) then
				if stdlib or match( "std/", short_names[file] ) != 1 then
					lines &= sprintf("\t\"%s\" -> \"%s\"\n", {short_names[fi], short_names[file]})
					included = set:add_to( file, included )
				end if
			end if
		end for
	end for
	return lines & "}\n"
end function

export function diagram_file_deps( integer fn )
	sequence lines = "digraph filedep { rankdir=TB \n"
	lines &= sprintf( "\tnode [shape=box,style=filled,color=lightblue] \"%s\"\n\tnode [shape=box,style=\"\",color=black]\n", {short_names[fn]} )
	if show_stdlib then
		lines &= "\tsubgraph \"cluster_stdlib\"{ rank=max\n"
		for i = 1 to length(short_names) do
			if std_libs[i] then
				lines &= sprintf( "\"%s\"\n", {short_names[i]})
			end if
		end for
		lines &= "\t}\n"
	end if
	
	for f = 1 to length( short_names ) do
		if f != fn then
			-- look to see if this was included
			if find( fn, file_include[f] ) and (show_stdlib or not std_libs[f]) then
				lines &= sprintf("\t\"%s\" -> \"%s\"\n", { short_names[f], short_names[fn] } )
			end if
		else
			
			for i = 1 to length( file_include[f] ) do
				lines &= sprintf("\t\"%s\" -> \"%s\"\n", { short_names[fn], short_names[abs(file_include[f][i])] } )
			end for
		end if
	end for
	
	return lines & "}\n"
end function

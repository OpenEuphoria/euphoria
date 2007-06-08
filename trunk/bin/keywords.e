-- (c) Copyright 2007 Rapid Deployment Software - See License.txt
--
-- Euphoria 3.1
-- Keywords and routines built in to ex, exw and exu

global constant keywords = {
    "if", "end", "then", "procedure", "else", "for", "return",
    "do", "elsif", "while", "type", "constant", "to", "and", "or",
    "exit", "function", "global", "by", "not", "include",
    "with", "without", "xor"}

global constant builtins = {
    "length", "puts", "integer", "sequence", "position", "object",
    "append", "prepend", "print", "printf", 
    "clear_screen", "floor", "getc", "gets", "get_key",
    "rand", "repeat", "atom", "compare", "find", "match",
    "time", "command_line", "open", "close", "trace", "getenv",
    "sqrt", "sin", "cos", "tan", "log", "system", "date", "remainder",
    "power", "machine_func", "machine_proc", "abort", "peek", "poke", 
    "call", "sprintf", "arctan", "and_bits", "or_bits", "xor_bits",
    "not_bits", "pixel", "get_pixel", "mem_copy", "mem_set",
    "c_proc", "c_func", "routine_id", "call_proc", "call_func", 
    "poke4", "peek4s", "peek4u", "profile", "equal", "system_exec",
    "platform", "task_create", "task_schedule", "task_yield",
    "task_self", "task_suspend", "task_list",
    "task_status", "task_clock_stop", "task_clock_start","find_from",
    "match_from"}



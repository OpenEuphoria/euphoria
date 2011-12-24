/*****************************************************************************/
/*                                                                           */
/*                         RESERVED WORD TABLE                               */
/*                                                                           */
/*****************************************************************************/

/* execute() opcodes - must be consecutive integers for good switch */

/* Keep in sync with reswords.e */

#undef TRACE // DJGPP defines TRACE

// origin 1
#define LESS                1   // keep relops consecutive LESS..GREATER, NOT
#define GREATEREQ           2
#define EQUALS              3
#define NOTEQ               4
#define LESSEQ              5
#define GREATER             6
#define NOT                 7
#define AND                 8
#define OR                  9
#define MINUS               10
#define PLUS                11
#define UMINUS              12
#define MULTIPLY            13
#define DIVIDE              14
#define CONCAT              15
#define ASSIGN_SUBS         16
#define GETS                17
#define ASSIGN              18
#define PRINT               19
#define IF                  20
#define FOR                 21
#define ENDWHILE            22
#define ELSE                23
#define OR_BITS             24
#define RHS_SUBS            25
#define XOR_BITS            26
#define PROC                27
#define RETURNF             28
#define RETURNP             29
#define PRIVATE_INIT_CHECK  30
#define RIGHT_BRACE_N       31 // see also RIGHT_BRACE_2
#define REPEAT              32
#define GETC                33
#define RETURNT             34
#define APPEND              35
#define QPRINT              36
#define OPEN                37
#define PRINTF              38
#define ENDFOR_GENERAL      39
#define IS_AN_OBJECT        40
#define SQRT                41
#define LENGTH              42
#define BADRETURNF          43
#define PUTS                44
#define ASSIGN_SLICE        45
#define RHS_SLICE           46
#define WHILE               47
#define ENDFOR_INT_UP       48
#define ENDFOR_UP           49
#define ENDFOR_DOWN         50
#define NOT_BITS            51
#define ENDFOR_INT_DOWN     52
#define SPRINTF             53
#define ENDFOR_INT_UP1      54
#define ENDFOR_INT_DOWN1    55
#define AND_BITS            56
#define PREPEND             57
#define STARTLINE           58
#define CLEAR_SCREEN        59
#define POSITION            60
#define EXIT                61
#define RAND                62
#define FLOOR_DIV           63
#define TRACE               64
#define TYPE_CHECK          65
#define FLOOR_DIV2          66
#define IS_AN_ATOM          67
#define IS_A_SEQUENCE       68
#define DATE                69
#define TIME                70
#define REMAINDER           71
#define POWER               72
#define ARCTAN              73
#define LOG                 74
#define SPACE_USED          75
#define COMPARE             76
#define FIND                77
#define MATCH               78
#define GET_KEY             79
#define SIN                 80
#define COS                 81
#define TAN                 82
#define FLOOR               83
#define ASSIGN_SUBS_CHECK   84
#define RIGHT_BRACE_2       85
#define CLOSE               86
#define DISPLAY_VAR         87
#define ERASE_PRIVATE_NAMES 88
#define UPDATE_GLOBALS      89
#define ERASE_SYMBOL        90
#define GETENV              91
#define RHS_SUBS_CHECK      92
#define PLUS1               93
#define IS_AN_INTEGER       94
#define LHS_SUBS            95
#define INTEGER_CHECK       96
#define SEQUENCE_CHECK      97
#define DIV2                98
#define SYSTEM              99
#define COMMAND_LINE        100
#define ATOM_CHECK          101
#define LESS_IFW            102 // keep relops consecutive LESS..GREATER, NOT
#define GREATEREQ_IFW       103
#define EQUALS_IFW          104
#define NOTEQ_IFW           105
#define LESSEQ_IFW          106
#define GREATER_IFW         107
#define NOT_IFW             108
#define GLOBAL_INIT_CHECK   109
#define NOP2                110
#define MACHINE_FUNC        111
#define MACHINE_PROC        112
#define ASSIGN_I            113 // keep these _I's together ...
#define RHS_SUBS_I          114
#define PLUS_I              115
#define MINUS_I             116
#define PLUS1_I             117 // ... they check for integer result
#define ASSIGN_SUBS_I       118
#define LESS_IFW_I          119 // keep relop _I's consecutive LESS..GREATER
#define GREATEREQ_IFW_I     120
#define EQUALS_IFW_I        121
#define NOTEQ_IFW_I         122
#define LESSEQ_IFW_I        123
#define GREATER_IFW_I       124
#define FOR_I               125
#define ABORT               126
#define PEEK                127
#define POKE                128
#define CALL                129
#define MEM_COPY            130
#define MEM_SET             131
#define C_PROC              132
#define C_FUNC              133
#define ROUTINE_ID          134
#define CALL_BACK_RETURN    135
#define CALL_PROC           136
#define CALL_FUNC           137
#define POKE4               138
#define PEEK4S              139
#define PEEK4U              140
#define SC1_AND             141
#define SC2_AND             142
#define SC1_OR              143
#define SC2_OR              144
#define SC2_NULL            145  // no code address for this one
#define SC1_AND_IF          146
#define SC1_OR_IF           147
#define ASSIGN_SUBS2        148  // just for emit, not x.c
#define ASSIGN_OP_SUBS      149
#define ASSIGN_OP_SLICE     150
#define PROFILE             151
#define XOR                 152
#define EQUAL               153
#define SYSTEM_EXEC         154
#define PLATFORM            155
#define END_PARAM_CHECK     156
#define CONCAT_N            157
#define NOPWHILE            158 // Translator only
#define NOP1                159 // Translator only
#define PLENGTH             160
#define LHS_SUBS1           161
#define PASSIGN_SUBS        162
#define PASSIGN_SLICE       163
#define PASSIGN_OP_SUBS     164
#define PASSIGN_OP_SLICE    165
#define LHS_SUBS1_COPY      166
#define TASK_CREATE         167
#define TASK_SCHEDULE       168
#define TASK_YIELD          169
#define TASK_SELF           170
#define TASK_SUSPEND        171
#define TASK_LIST           172
#define TASK_STATUS         173
#define TASK_CLOCK_STOP     174
#define TASK_CLOCK_START    175
#define FIND_FROM           176
#define MATCH_FROM          177
#define POKE2               178
#define PEEK2S              179
#define PEEK2U              180
#define PEEKS               181
#define PEEK_STRING         182
#define OPTION_SWITCHES     183
#define RETRY               184
#define SWITCH              185
#define CASE                186
#define NOPSELECT           187
#define GOTO                188
#define GLABEL              189
#define SPLICE              190
#define INSERT              191
#define SWITCH_SPI          192
#define SWITCH_I            193
#define HASH                194
#define PROC_FORWARD        195
#define FUNC_FORWARD        196
#define TYPE_CHECK_FORWARD  197
#define HEAD                198
#define TAIL                199
#define REMOVE              200
#define REPLACE             201
#define SWITCH_RT           202
#define PROC_TAIL           203
#define DELETE_ROUTINE      204
#define DELETE_OBJECT       205
#define EXIT_BLOCK          206
#define REF_TEMP            207
#define DEREF_TEMP          208
#define NOVALUE_TEMP        209
#define COVERAGE_LINE       210
#define COVERAGE_ROUTINE    211
#define POKE8               212
#define PEEK8S              213
#define PEEK8U              214
#define POKE_POINTER        215
#define PEEK_POINTER        216
#define SIZEOF              217
#define STARTLINE_BREAK     218
#define MAX_OPCODE          218

/* remember to update reswords.e, opnames.e,
   opnames.h, optable[], localjumptab[]
   in be_execute.c, be_runtime.c. redef.h,
   emit.e, keylist.e, compile.e, be_syncolor.c
*/

#define END_OF_FILE_CHAR   26
#define VARIABLE         -100
#define NAMESPACE         523
#define FUNC              501
#define TYPE              504

//struct key {
//  char *name;
//  short int scope;    /* keyword or predefined */
//  short int token;    /* token number returned to parser */
//  short int opcode;   /* opcode to emit (predefined subprograms) */
//  unsigned char num_args; /* number of arguments (predefined subprograms) */
//  unsigned char effect; /* side effects */
//};

//struct tokenval {
//  int id;            /* token number */
//  symtab_ptr sym;    /* symbol table/temp pointer */
//};

// typedef struct tokenval TOKEN;


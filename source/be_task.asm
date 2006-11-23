
Module: C:\euphoria\source\be_task.c
Group: 'DGROUP' CONST,CONST2,_DATA,_BSS

Segment: _TEXT  PARA USE32  000014d3 bytes  
 0000  53                InitTask_       push    ebx
 0001  52                                push    edx
 0002  56                                push    esi
 0003  57                                push    edi
 0004  55                                push    ebp
 0005  b8 64 00 00 00                    mov     eax,00000064H
 000a  e8 00 00 00 00                    call    EMalloc_
 000f  c7 00 ff ff ff ff                 mov     dword ptr [eax],0ffffffffH
 0015  c7 40 04 00 00 00 
       00                                mov     dword ptr +4H[eax],00000000H
 001c  c7 40 08 00 00 00 
       00                                mov     dword ptr +8H[eax],00000000H
 0023  c7 40 0c 02 00 00 
       00                                mov     dword ptr +0cH[eax],00000002H
 002a  c7 40 10 00 00 00 
       00                                mov     dword ptr +10H[eax],00000000H
 0031  c7 40 14 00 00 00 
       00                                mov     dword ptr +14H[eax],00000000H
 0038  c7 40 18 00 00 00 
       00                                mov     dword ptr +18H[eax],00000000H
 003f  c7 40 1c 00 00 00 
       00                                mov     dword ptr +1cH[eax],00000000H
 0046  c7 40 20 00 00 00 
       00                                mov     dword ptr +20H[eax],00000000H
 004d  c7 40 24 00 00 00 
       00                                mov     dword ptr +24H[eax],00000000H
 0054  c7 40 28 00 00 00 
       00                                mov     dword ptr +28H[eax],00000000H
 005b  c7 40 2c 00 00 00 
       00                                mov     dword ptr +2cH[eax],00000000H
 0062  c7 40 30 00 00 f0 
       3f                                mov     dword ptr +30H[eax],3ff00000H
 0069  c7 40 34 00 00 00 
       00                                mov     dword ptr +34H[eax],00000000H
 0070  c7 40 38 00 00 f0 
       3f                                mov     dword ptr +38H[eax],3ff00000H
 0077  c7 40 3c 01 00 00 
       00                                mov     dword ptr +3cH[eax],00000001H
 007e  c7 40 40 01 00 00 
       00                                mov     dword ptr +40H[eax],00000001H
 0085  c7 40 44 ff ff ff 
       ff                                mov     dword ptr +44H[eax],0ffffffffH
 008c  c7 40 48 00 00 00 
       00                                mov     dword ptr +48H[eax],00000000H
 0093  8b 15 00 00 00 00                 mov     edx,_total_stack_size
 0099  c7 40 4c 01 00 00 
       00                                mov     dword ptr +4cH[eax],00000001H
 00a0  89 c3                             mov     ebx,eax
 00a2  c7 40 54 00 00 00 
       00                                mov     dword ptr +54H[eax],00000000H
 00a9  a3 00 00 00 00                    mov     _tcb,eax
 00ae  c7 40 58 00 00 00 
       00                                mov     dword ptr +58H[eax],00000000H
 00b5  a1 00 00 00 00                    mov     eax,_stack_base
 00ba  81 ea 00 20 00 00                 sub     edx,00002000H
 00c0  29 d0                             sub     eax,edx
 00c2  89 43 50                          mov     +50H[ebx],eax
 00c5  8b 43 50                          mov     eax,+50H[ebx]
 00c8  89 53 60                          mov     +60H[ebx],edx
 00cb  c7 00 3f 2a 1d 0f                 mov     dword ptr [eax],0f1d2a3fH
 00d1  8b 43 60                          mov     eax,+60H[ebx]
 00d4  89 15 00 00 00 00                 mov     _total_stack_size,edx
 00da  89 c2                             mov     edx,eax
 00dc  c1 fa 1f                          sar     edx,1fH
 00df  2b c2                             sub     eax,edx
 00e1  d1 f8                             sar     eax,1
 00e3  be 01 00 00 00                    mov     esi,00000001H
 00e8  bd ff ff ff ff                    mov     ebp,0ffffffffH
 00ed  31 ff                             xor     edi,edi
 00ef  89 35 00 00 00 00                 mov     _tcb_size,esi
 00f5  8b 53 50                          mov     edx,+50H[ebx]
 00f8  89 3d 00 00 00 00                 mov     _ts_first,edi
 00fe  89 2d 00 00 00 00                 mov     _rt_first,ebp
 0104  c7 04 02 3f 2a 1d 
       0f                                mov     dword ptr [edx+eax],0f1d2a3fH
 010b  a1 00 00 00 00                    mov     eax,_stack_base
 0110  89 3d 00 00 00 00                 mov     _current_task,edi
 0116  89 43 5c                          mov     +5cH[ebx],eax
 0119  5d                                pop     ebp
 011a  5f                                pop     edi
 011b  5e                                pop     esi
 011c  5a                                pop     edx
 011d  5b                                pop     ebx
 011e  c3                                ret     
 011f  90                                nop     
 0120  53                task_delete_    push    ebx
 0121  51                                push    ecx
 0122  56                                push    esi
 0123  57                                push    edi
 0124  8b 35 00 00 00 00                 mov     esi,_tcb
 012a  89 c7                             mov     edi,eax
 012c  89 d1                             mov     ecx,edx
 012e  bb ff ff ff ff                    mov     ebx,0ffffffffH
 0133  39 d8                             cmp     eax,ebx
 0135  74 3f                             je      L4
 0137  6b d0 64          L1              imul    edx,eax,64H
 013a  39 c8                             cmp     eax,ecx
 013c  75 2b                             jne     L3
 013e  83 fb ff                          cmp     ebx,0ffffffffH
 0141  75 08                             jne     L2
 0143  89 f0                             mov     eax,esi
 0145  8b 44 02 44                       mov     eax,+44H[edx+eax]
 0149  eb 2d                             jmp     L5
 014b  8d 04 9d 00 00 00 
       00                L2              lea     eax,+0H[ebx*4]
 0152  29 d8                             sub     eax,ebx
 0154  c1 e0 03                          shl     eax,03H
 0157  01 d8                             add     eax,ebx
 0159  c1 e0 02                          shl     eax,02H
 015c  01 f2                             add     edx,esi
 015e  8d 0c 06                          lea     ecx,[esi+eax]
 0161  8b 42 44                          mov     eax,+44H[edx]
 0164  89 41 44                          mov     +44H[ecx],eax
 0167  eb 0d                             jmp     L4
 0169  89 c3             L3              mov     ebx,eax
 016b  89 f0                             mov     eax,esi
 016d  8b 44 02 44                       mov     eax,+44H[edx+eax]
 0171  83 f8 ff                          cmp     eax,0ffffffffH
 0174  75 c1                             jne     L1
 0176  89 f8             L4              mov     eax,edi
 0178  89 35 00 00 00 00 L5              mov     _tcb,esi
 017e  5f                                pop     edi
 017f  5e                                pop     esi
 0180  59                                pop     ecx
 0181  5b                                pop     ebx
 0182  c3                                ret     
 0183  90                                nop     
 0184  53                terminate_task_ push    ebx
 0185  52                                push    edx
 0186  89 c3                             mov     ebx,eax
 0188  c1 e0 02                          shl     eax,02H
 018b  29 d8                             sub     eax,ebx
 018d  c1 e0 03                          shl     eax,03H
 0190  8b 15 00 00 00 00                 mov     edx,_tcb
 0196  01 d8                             add     eax,ebx
 0198  83 7c 82 0c 01                    cmp     dword ptr +0cH[edx+eax*4],00000001H
 019d  75 13                             jne     L6
 019f  a1 00 00 00 00                    mov     eax,_rt_first
 01a4  89 da                             mov     edx,ebx
 01a6  e8 00 00 00 00                    call    task_delete_
 01ab  a3 00 00 00 00                    mov     _rt_first,eax
 01b0  eb 11                             jmp     L7
 01b2  a1 00 00 00 00    L6              mov     eax,_ts_first
 01b7  89 da                             mov     edx,ebx
 01b9  e8 00 00 00 00                    call    task_delete_
 01be  a3 00 00 00 00                    mov     _ts_first,eax
 01c3  8d 14 9d 00 00 00 
       00                L7              lea     edx,+0H[ebx*4]
 01ca  29 da                             sub     edx,ebx
 01cc  c1 e2 03                          shl     edx,03H
 01cf  01 da                             add     edx,ebx
 01d1  a1 00 00 00 00                    mov     eax,_tcb
 01d6  c1 e2 02                          shl     edx,02H
 01d9  c7 44 02 10 02 00 
       00 00                             mov     dword ptr +10H[edx+eax],00000002H
 01e1  5a                                pop     edx
 01e2  5b                                pop     ebx
 01e3  c3                                ret     
 01e4  50                wait_           push    eax
 01e5  53                                push    ebx
 01e6  52                                push    edx
 01e7  55                                push    ebp
 01e8  89 e5                             mov     ebp,esp
 01ea  83 ec 1c                          sub     esp,0000001cH
 01ed  83 e4 f8                          and     esp,0fffffff8H
 01f0  8b 55 18                          mov     edx,+18H[ebp]
 01f3  52                                push    edx
 01f4  8b 5d 14                          mov     ebx,+14H[ebp]
 01f7  53                                push    ebx
 01f8  e8 00 00 00 00                    call    floor_
 01fd  d9 e8                             fld1    
 01ff  d9 c9                             fxch    st(1)
 0201  dd 5c 24 14                       fstp    qword ptr +14H[esp]
 0205  dc 5c 24 14                       fcomp   qword ptr +14H[esp]
 0209  df e0                             fstsw   ax
 020b  9e                                sahf    
 020c  77 1e                             ja      L8
 020e  dd 44 24 14                       fld     qword ptr +14H[esp]
 0212  e8 00 00 00 00                    call    __CHP
 0217  db 1c 24                          fistp   dword ptr [esp]
 021a  8b 04 24                          mov     eax,[esp]
 021d  e8 00 00 00 00                    call    sleep_
 0222  dd 45 14                          fld     qword ptr +14H[ebp]
 0225  dc 64 24 14                       fsub    qword ptr +14H[esp]
 0229  dd 5d 14                          fstp    qword ptr +14H[ebp]
 022c  e8 00 00 00 00    L8              call    current_time_
 0231  dd 54 24 0c                       fst     qword ptr +0cH[esp]
 0235  dc 45 14                          fadd    qword ptr +14H[ebp]
 0238  dd 44 24 0c                       fld     qword ptr +0cH[esp]
 023c  d9 c9                             fxch    st(1)
 023e  dd 5c 24 04                       fstp    qword ptr +4H[esp]
 0242  dc 5c 24 04                       fcomp   qword ptr +4H[esp]
 0246  df e0                             fstsw   ax
 0248  9e                                sahf    
 0249  73 12                             jae     L10
 024b  e8 00 00 00 00    L9              call    current_time_
 0250  dd 54 24 0c                       fst     qword ptr +0cH[esp]
 0254  dc 5c 24 04                       fcomp   qword ptr +4H[esp]
 0258  df e0                             fstsw   ax
 025a  9e                                sahf    
 025b  72 ee                             jb      L9
 025d  dd 44 24 0c       L10             fld     qword ptr +0cH[esp]
 0261  89 ec                             mov     esp,ebp
 0263  5d                                pop     ebp
 0264  5a                                pop     edx
 0265  5b                                pop     ebx
 0266  58                                pop     eax
 0267  c2 08 00                          ret     0008H
 026a  8b c0                             mov     eax,eax
 026c  51 03 00 00       L11             DD      L20
 0270  fb 02 00 00                       DD      L15
 0274  24 03 00 00                       DD      L17
 0278  31 03 00 00                       DD      L18
 027c  41 03 00 00                       DD      L19
 0280  56 03 00 00                       DD      L21
 0284  70 03 00 00                       DD      L22
 0288  91 03 00 00                       DD      L23
 028c  b6 03 00 00                       DD      L24
 0290  dd 03 00 00                       DD      L25
 0294  08 04 00 00                       DD      L26
 0298  39 04 00 00                       DD      L27
 029c  6c 04 00 00                       DD      L28
 02a0  53                call_task_      push    ebx
 02a1  51                                push    ecx
 02a2  56                                push    esi
 02a3  57                                push    edi
 02a4  55                                push    ebp
 02a5  83 ec 04                          sub     esp,00000004H
 02a8  89 c3                             mov     ebx,eax
 02aa  c1 e0 02                          shl     eax,02H
 02ad  8d 34 d5 00 00 00 
       00                                lea     esi,+0H[edx*8]
 02b4  01 d8                             add     eax,ebx
 02b6  8b 16                             mov     edx,[esi]
 02b8  8b 76 04                          mov     esi,+4H[esi]
 02bb  8b 04 85 04 00 00 
       00                                mov     eax,__00+4H[eax*4]
 02c2  bb 01 00 00 00                    mov     ebx,00000001H
 02c7  89 04 24                          mov     [esp],eax
 02ca  39 de                             cmp     esi,ebx
 02cc  7c 1c                             jl      L14
 02ce  8d 42 04                          lea     eax,+4H[edx]
 02d1  8b 08             L12             mov     ecx,[eax]
 02d3  81 f9 ff ff ff bf                 cmp     ecx,0bfffffffH
 02d9  7d 07                             jge     L13
 02db  ff 04 cd 08 00 00 
       00                                inc     dword ptr +8H[ecx*8]
 02e2  43                L13             inc     ebx
 02e3  83 c0 04                          add     eax,00000004H
 02e6  39 f3                             cmp     ebx,esi
 02e8  7e e7                             jle     L12
 02ea  83 fe 0c          L14             cmp     esi,0000000cH
 02ed  0f 87 b2 01 00 00                 ja      L29
 02f3  2e ff 24 b5 6c 02 
       00 00                             jmp     dword ptr cs:L11[esi*4]
 02fb  8b 42 04          L15             mov     eax,+4H[edx]
 02fe  ff 14 24                          call    dword ptr [esp]
 0301  a1 00 00 00 00    L16             mov     eax,_current_task
 0306  e8 00 00 00 00                    call    terminate_task_
 030b  e8 00 00 00 00                    call    current_time_
 0310  83 ec 08                          sub     esp,00000008H
 0313  dd 1c 24                          fstp    qword ptr [esp]
 0316  e8 00 00 00 00                    call    scheduler_
 031b  83 c4 04                          add     esp,00000004H
 031e  5d                                pop     ebp
 031f  5f                                pop     edi
 0320  5e                                pop     esi
 0321  59                                pop     ecx
 0322  5b                                pop     ebx
 0323  c3                                ret     
 0324  8b 5a 08          L17             mov     ebx,+8H[edx]
 0327  8b 42 04                          mov     eax,+4H[edx]
 032a  89 da                             mov     edx,ebx
 032c  ff 14 24                          call    dword ptr [esp]
 032f  eb d0                             jmp     L16
 0331  8b 5a 0c          L18             mov     ebx,+0cH[edx]
 0334  8b 4a 08                          mov     ecx,+8H[edx]
 0337  8b 42 04                          mov     eax,+4H[edx]
 033a  89 ca                             mov     edx,ecx
 033c  ff 14 24                          call    dword ptr [esp]
 033f  eb c0                             jmp     L16
 0341  8b 4a 10          L19             mov     ecx,+10H[edx]
 0344  8b 5a 0c                          mov     ebx,+0cH[edx]
 0347  8b 42 08                          mov     eax,+8H[edx]
 034a  8b 72 04                          mov     esi,+4H[edx]
 034d  89 c2                             mov     edx,eax
 034f  89 f0                             mov     eax,esi
 0351  ff 14 24          L20             call    dword ptr [esp]
 0354  eb ab                             jmp     L16
 0356  8b 42 14          L21             mov     eax,+14H[edx]
 0359  8b 4a 10                          mov     ecx,+10H[edx]
 035c  8b 5a 0c                          mov     ebx,+0cH[edx]
 035f  50                                push    eax
 0360  8b 42 08                          mov     eax,+8H[edx]
 0363  8b 72 04                          mov     esi,+4H[edx]
 0366  89 c2                             mov     edx,eax
 0368  89 f0                             mov     eax,esi
 036a  ff 54 24 04                       call    dword ptr +4H[esp]
 036e  eb 91                             jmp     L16
 0370  8b 7a 18          L22             mov     edi,+18H[edx]
 0373  8b 6a 14                          mov     ebp,+14H[edx]
 0376  8b 4a 10                          mov     ecx,+10H[edx]
 0379  8b 5a 0c                          mov     ebx,+0cH[edx]
 037c  57                                push    edi
 037d  8b 42 08                          mov     eax,+8H[edx]
 0380  8b 72 04                          mov     esi,+4H[edx]
 0383  55                                push    ebp
 0384  89 c2                             mov     edx,eax
 0386  89 f0                             mov     eax,esi
 0388  ff 54 24 08                       call    dword ptr +8H[esp]
 038c  e9 70 ff ff ff                    jmp     L16
 0391  8b 5a 1c          L23             mov     ebx,+1cH[edx]
 0394  53                                push    ebx
 0395  8b 4a 18                          mov     ecx,+18H[edx]
 0398  8b 72 14                          mov     esi,+14H[edx]
 039b  51                                push    ecx
 039c  8b 42 08                          mov     eax,+8H[edx]
 039f  8b 5a 0c                          mov     ebx,+0cH[edx]
 03a2  56                                push    esi
 03a3  8b 4a 10                          mov     ecx,+10H[edx]
 03a6  8b 72 04                          mov     esi,+4H[edx]
 03a9  89 c2                             mov     edx,eax
 03ab  89 f0                             mov     eax,esi
 03ad  ff 54 24 0c                       call    dword ptr +0cH[esp]
 03b1  e9 4b ff ff ff                    jmp     L16
 03b6  8b 72 20          L24             mov     esi,+20H[edx]
 03b9  56                                push    esi
 03ba  8b 7a 1c                          mov     edi,+1cH[edx]
 03bd  8b 6a 18                          mov     ebp,+18H[edx]
 03c0  57                                push    edi
 03c1  8b 42 14                          mov     eax,+14H[edx]
 03c4  8b 4a 10                          mov     ecx,+10H[edx]
 03c7  55                                push    ebp
 03c8  8b 5a 0c                          mov     ebx,+0cH[edx]
 03cb  8b 72 08                          mov     esi,+8H[edx]
 03ce  50                                push    eax
 03cf  8b 42 04                          mov     eax,+4H[edx]
 03d2  89 f2                             mov     edx,esi
 03d4  ff 54 24 10                       call    dword ptr +10H[esp]
 03d8  e9 24 ff ff ff                    jmp     L16
 03dd  8b 7a 24          L25             mov     edi,+24H[edx]
 03e0  57                                push    edi
 03e1  8b 6a 20                          mov     ebp,+20H[edx]
 03e4  55                                push    ebp
 03e5  8b 42 1c                          mov     eax,+1cH[edx]
 03e8  50                                push    eax
 03e9  8b 5a 18                          mov     ebx,+18H[edx]
 03ec  8b 4a 14                          mov     ecx,+14H[edx]
 03ef  53                                push    ebx
 03f0  8b 72 08                          mov     esi,+8H[edx]
 03f3  8b 42 04                          mov     eax,+4H[edx]
 03f6  51                                push    ecx
 03f7  8b 5a 0c                          mov     ebx,+0cH[edx]
 03fa  8b 4a 10                          mov     ecx,+10H[edx]
 03fd  89 f2                             mov     edx,esi
 03ff  ff 54 24 14                       call    dword ptr +14H[esp]
 0403  e9 f9 fe ff ff                    jmp     L16
 0408  8b 7a 28          L26             mov     edi,+28H[edx]
 040b  57                                push    edi
 040c  8b 6a 24                          mov     ebp,+24H[edx]
 040f  55                                push    ebp
 0410  8b 42 20                          mov     eax,+20H[edx]
 0413  50                                push    eax
 0414  8b 5a 1c                          mov     ebx,+1cH[edx]
 0417  53                                push    ebx
 0418  8b 4a 18                          mov     ecx,+18H[edx]
 041b  8b 72 14                          mov     esi,+14H[edx]
 041e  51                                push    ecx
 041f  8b 42 08                          mov     eax,+8H[edx]
 0422  8b 5a 0c                          mov     ebx,+0cH[edx]
 0425  56                                push    esi
 0426  8b 4a 10                          mov     ecx,+10H[edx]
 0429  8b 72 04                          mov     esi,+4H[edx]
 042c  89 c2                             mov     edx,eax
 042e  89 f0                             mov     eax,esi
 0430  ff 54 24 18                       call    dword ptr +18H[esp]
 0434  e9 c8 fe ff ff                    jmp     L16
 0439  8b 72 2c          L27             mov     esi,+2cH[edx]
 043c  56                                push    esi
 043d  8b 7a 28                          mov     edi,+28H[edx]
 0440  57                                push    edi
 0441  8b 6a 24                          mov     ebp,+24H[edx]
 0444  55                                push    ebp
 0445  8b 42 20                          mov     eax,+20H[edx]
 0448  50                                push    eax
 0449  8b 5a 1c                          mov     ebx,+1cH[edx]
 044c  53                                push    ebx
 044d  8b 4a 18                          mov     ecx,+18H[edx]
 0450  8b 72 14                          mov     esi,+14H[edx]
 0453  51                                push    ecx
 0454  8b 42 04                          mov     eax,+4H[edx]
 0457  8b 5a 0c                          mov     ebx,+0cH[edx]
 045a  56                                push    esi
 045b  8b 72 08                          mov     esi,+8H[edx]
 045e  8b 4a 10                          mov     ecx,+10H[edx]
 0461  89 f2                             mov     edx,esi
 0463  ff 54 24 1c                       call    dword ptr +1cH[esp]
 0467  e9 95 fe ff ff                    jmp     L16
 046c  8b 5a 30          L28             mov     ebx,+30H[edx]
 046f  53                                push    ebx
 0470  8b 4a 2c                          mov     ecx,+2cH[edx]
 0473  51                                push    ecx
 0474  8b 72 28                          mov     esi,+28H[edx]
 0477  56                                push    esi
 0478  8b 7a 24                          mov     edi,+24H[edx]
 047b  57                                push    edi
 047c  8b 6a 20                          mov     ebp,+20H[edx]
 047f  55                                push    ebp
 0480  8b 42 1c                          mov     eax,+1cH[edx]
 0483  50                                push    eax
 0484  8b 5a 18                          mov     ebx,+18H[edx]
 0487  8b 4a 14                          mov     ecx,+14H[edx]
 048a  53                                push    ebx
 048b  8b 72 04                          mov     esi,+4H[edx]
 048e  8b 42 08                          mov     eax,+8H[edx]
 0491  51                                push    ecx
 0492  8b 5a 0c                          mov     ebx,+0cH[edx]
 0495  8b 4a 10                          mov     ecx,+10H[edx]
 0498  89 c2                             mov     edx,eax
 049a  89 f0                             mov     eax,esi
 049c  ff 54 24 20                       call    dword ptr +20H[esp]
 04a0  e9 5c fe ff ff                    jmp     L16
 04a5  b8 00 00 00 00    L29             mov     eax,offset L129
 04aa  e9 00 00 00 00                    jmp     RTFatal_
 04af  90                                nop     
 04b0  53                task_yield_     push    ebx
 04b1  51                                push    ecx
 04b2  52                                push    edx
 04b3  56                                push    esi
 04b4  57                                push    edi
 04b5  55                                push    ebp
 04b6  89 e5                             mov     ebp,esp
 04b8  83 ec 08                          sub     esp,00000008H
 04bb  83 e4 f8                          and     esp,0fffffff8H
 04be  e8 00 00 00 00                    call    current_time_
 04c3  8b 15 00 00 00 00                 mov     edx,_current_task
 04c9  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 04d0  29 d0                             sub     eax,edx
 04d2  c1 e0 03                          shl     eax,03H
 04d5  01 d0                             add     eax,edx
 04d7  8b 15 00 00 00 00                 mov     edx,_tcb
 04dd  c1 e0 02                          shl     eax,02H
 04e0  01 d0                             add     eax,edx
 04e2  8b 50 10                          mov     edx,+10H[eax]
 04e5  dd 1c 24                          fstp    qword ptr [esp]
 04e8  85 d2                             test    edx,edx
 04ea  0f 85 a1 00 00 00                 jne     L32
 04f0  8b 58 3c                          mov     ebx,+3cH[eax]
 04f3  85 db                             test    ebx,ebx
 04f5  7e 06                             jle     L30
 04f7  8d 4b ff                          lea     ecx,-1H[ebx]
 04fa  89 48 3c                          mov     +3cH[eax],ecx
 04fd  8b 15 00 00 00 00 L30             mov     edx,_current_task
 0503  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 050a  29 d0                             sub     eax,edx
 050c  c1 e0 03                          shl     eax,03H
 050f  01 d0                             add     eax,edx
 0511  8b 15 00 00 00 00                 mov     edx,_tcb
 0517  c1 e0 02                          shl     eax,02H
 051a  01 c2                             add     edx,eax
 051c  8b 72 0c                          mov     esi,+0cH[edx]
 051f  83 fe 01                          cmp     esi,00000001H
 0522  75 6d                             jne     L32
 0524  8b 7a 40                          mov     edi,+40H[edx]
 0527  39 f7                             cmp     edi,esi
 0529  7e 33                             jle     L31
 052b  dd 42 14                          fld     qword ptr +14H[edx]
 052e  dc 24 24                          fsub    qword ptr [esp]
 0531  d9 e1                             fabs    
 0533  dc 1d 3c 00 00 00                 fcomp   qword ptr L130
 0539  df e0                             fstsw   ax
 053b  9e                                sahf    
 053c  73 20                             jae     L31
 053e  83 7a 3c 00                       cmp     dword ptr +3cH[edx],00000000H
 0542  75 4d                             jne     L32
 0544  89 7a 3c                          mov     +3cH[edx],edi
 0547  dd 04 24                          fld     qword ptr [esp]
 054a  d9 c0                             fld     st(0)
 054c  dc 42 1c                          fadd    qword ptr +1cH[edx]
 054f  d9 c9                             fxch    st(1)
 0551  dc 42 24                          fadd    qword ptr +24H[edx]
 0554  d9 c9                             fxch    st(1)
 0556  dd 5a 2c                          fstp    qword ptr +2cH[edx]
 0559  dd 5a 34                          fstp    qword ptr +34H[edx]
 055c  eb 33                             jmp     L32
 055e  8b 15 00 00 00 00 L31             mov     edx,_current_task
 0564  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 056b  29 d0                             sub     eax,edx
 056d  c1 e0 03                          shl     eax,03H
 0570  01 d0                             add     eax,edx
 0572  8b 15 00 00 00 00                 mov     edx,_tcb
 0578  dd 04 24                          fld     qword ptr [esp]
 057b  d9 c0                             fld     st(0)
 057d  dc 44 82 1c                       fadd    qword ptr +1cH[edx+eax*4]
 0581  d9 c9                             fxch    st(1)
 0583  dc 44 82 24                       fadd    qword ptr +24H[edx+eax*4]
 0587  d9 c9                             fxch    st(1)
 0589  dd 5c 82 2c                       fstp    qword ptr +2cH[edx+eax*4]
 058d  dd 5c 82 34                       fstp    qword ptr +34H[edx+eax*4]
 0591  8b 54 24 04       L32             mov     edx,+4H[esp]
 0595  52                                push    edx
 0596  8b 5c 24 04                       mov     ebx,+4H[esp]
 059a  53                                push    ebx
 059b  e8 00 00 00 00                    call    scheduler_
 05a0  89 ec                             mov     esp,ebp
 05a2  5d                                pop     ebp
 05a3  5f                                pop     edi
 05a4  5e                                pop     esi
 05a5  5a                                pop     edx
 05a6  59                                pop     ecx
 05a7  5b                                pop     ebx
 05a8  c3                                ret     
 05a9  8d 40 00                          lea     eax,+0H[eax]
 05ac  53                task_insert_    push    ebx
 05ad  51                                push    ecx
 05ae  89 c1                             mov     ecx,eax
 05b0  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 05b7  29 d0                             sub     eax,edx
 05b9  c1 e0 03                          shl     eax,03H
 05bc  8b 1d 00 00 00 00                 mov     ebx,_tcb
 05c2  01 d0                             add     eax,edx
 05c4  89 4c 83 44                       mov     +44H[ebx+eax*4],ecx
 05c8  89 d0                             mov     eax,edx
 05ca  59                                pop     ecx
 05cb  5b                                pop     ebx
 05cc  c3                                ret     
 05cd  8d 40 00                          lea     eax,+0H[eax]
 05d0  53                which_task_     push    ebx
 05d1  51                                push    ecx
 05d2  52                                push    edx
 05d3  56                                push    esi
 05d4  55                                push    ebp
 05d5  89 e5                             mov     ebp,esp
 05d7  83 ec 30                          sub     esp,00000030H
 05da  83 e4 f8                          and     esp,0fffffff8H
 05dd  8b 45 18                          mov     eax,+18H[ebp]
 05e0  89 44 24 28                       mov     +28H[esp],eax
 05e4  8b 45 1c                          mov     eax,+1cH[ebp]
 05e7  89 44 24 2c                       mov     +2cH[esp],eax
 05eb  8b 15 00 00 00 00                 mov     edx,_tcb_size
 05f1  31 db                             xor     ebx,ebx
 05f3  85 d2                             test    edx,edx
 05f5  7e 36                             jle     L35
 05f7  a1 00 00 00 00                    mov     eax,_tcb_size
 05fc  8d 0c 85 00 00 00 
       00                                lea     ecx,+0H[eax*4]
 0603  29 c1                             sub     ecx,eax
 0605  c1 e1 03                          shl     ecx,03H
 0608  01 c1                             add     ecx,eax
 060a  31 d2                             xor     edx,edx
 060c  c1 e1 02                          shl     ecx,02H
 060f  a1 00 00 00 00    L33             mov     eax,_tcb
 0614  dd 44 02 04                       fld     qword ptr +4H[edx+eax]
 0618  dc 5c 24 28                       fcomp   qword ptr +28H[esp]
 061c  df e0                             fstsw   ax
 061e  9e                                sahf    
 061f  75 04                             jne     L34
 0621  89 de                             mov     esi,ebx
 0623  eb 2b                             jmp     L36
 0625  83 c2 64          L34             add     edx,00000064H
 0628  43                                inc     ebx
 0629  39 ca                             cmp     edx,ecx
 062b  7c e2                             jl      L33
 062d  8b 5c 24 2c       L35             mov     ebx,+2cH[esp]
 0631  53                                push    ebx
 0632  8b 4c 24 2c                       mov     ecx,+2cH[esp]
 0636  51                                push    ecx
 0637  68 44 00 00 00                    push    offset L131
 063c  8d 44 24 0c                       lea     eax,+0cH[esp]
 0640  50                                push    eax
 0641  e8 00 00 00 00                    call    sprintf_
 0646  83 c4 10                          add     esp,00000010H
 0649  89 e0                             mov     eax,esp
 064b  e9 00 00 00 00                    jmp     RTFatal_
 0650  89 f0             L36             mov     eax,esi
 0652  89 ec                             mov     esp,ebp
 0654  5d                                pop     ebp
 0655  5e                                pop     esi
 0656  5a                                pop     edx
 0657  59                                pop     ecx
 0658  5b                                pop     ebx
 0659  c2 08 00                          ret     0008H
 065c  53                task_schedule_  push    ebx
 065d  51                                push    ecx
 065e  56                                push    esi
 065f  57                                push    edi
 0660  55                                push    ebp
 0661  89 e5                             mov     ebp,esp
 0663  83 ec 3c                          sub     esp,0000003cH
 0666  83 e4 f8                          and     esp,0fffffff8H
 0669  89 44 24 38                       mov     +38H[esp],eax
 066d  3d ff ff ff bf                    cmp     eax,0bfffffffH
 0672  7e 0a                             jle     L37
 0674  db 44 24 38                       fild    dword ptr +38H[esp]
 0678  dd 5c 24 28                       fstp    qword ptr +28H[esp]
 067c  eb 29                             jmp     L39
 067e  3d 00 00 00 a0    L37             cmp     eax,0a0000000H
 0683  7c 18                             jl      L38
 0685  8b 1c c5 00 00 00 
       00                                mov     ebx,+0H[eax*8]
 068c  8b 04 c5 04 00 00 
       00                                mov     eax,+4H[eax*8]
 0693  89 5c 24 28                       mov     +28H[esp],ebx
 0697  89 44 24 2c                       mov     +2cH[esp],eax
 069b  eb 0a                             jmp     L39
 069d  b8 5c 00 00 00    L38             mov     eax,offset L132
 06a2  e9 00 00 00 00                    jmp     RTFatal_
 06a7  8b 74 24 2c       L39             mov     esi,+2cH[esp]
 06ab  56                                push    esi
 06ac  8b 7c 24 2c                       mov     edi,+2cH[esp]
 06b0  57                                push    edi
 06b1  e8 00 00 00 00                    call    which_task_
 06b6  89 c3                             mov     ebx,eax
 06b8  8d 04 d5 00 00 00 
       00                                lea     eax,+0H[edx*8]
 06bf  81 fa 00 00 00 a0                 cmp     edx,0a0000000H
 06c5  0f 8c ed 00 00 00                 jl      L48
 06cb  81 fa ff ff ff bf                 cmp     edx,0bfffffffH
 06d1  7e 06                             jle     L40
 06d3  89 54 24 0c                       mov     +0cH[esp],edx
 06d7  eb 3e                             jmp     L43
 06d9  8b 10             L40             mov     edx,[eax]
 06db  8b 40 04                          mov     eax,+4H[eax]
 06de  89 54 24 10                       mov     +10H[esp],edx
 06e2  89 44 24 14                       mov     +14H[esp],eax
 06e6  d9 ee                             fldz    
 06e8  dc 5c 24 10                       fcomp   qword ptr +10H[esp]
 06ec  df e0                             fstsw   ax
 06ee  9e                                sahf    
 06ef  73 0f                             jae     L41
 06f1  dd 44 24 10                       fld     qword ptr +10H[esp]
 06f5  dc 1d 7b 01 00 00                 fcomp   qword ptr L140
 06fb  df e0                             fstsw   ax
 06fd  9e                                sahf    
 06fe  76 0a                             jbe     L42
 0700  c7 44 24 0c ff ff 
       ff ff             L41             mov     dword ptr +0cH[esp],0ffffffffH
 0708  eb 0d                             jmp     L43
 070a  dd 44 24 10       L42             fld     qword ptr +10H[esp]
 070e  e8 00 00 00 00                    call    __CHP
 0713  db 5c 24 0c                       fistp   dword ptr +0cH[esp]
 0717  83 7c 24 0c 00    L43             cmp     dword ptr +0cH[esp],00000000H
 071c  7f 0a                             jg      L44
 071e  b8 7c 00 00 00                    mov     eax,offset L133
 0723  e9 00 00 00 00                    jmp     RTFatal_
 0728  8d 04 9d 00 00 00 
       00                L44             lea     eax,+0H[ebx*4]
 072f  29 d8                             sub     eax,ebx
 0731  c1 e0 03                          shl     eax,03H
 0734  01 d8                             add     eax,ebx
 0736  8b 15 00 00 00 00                 mov     edx,_tcb
 073c  c1 e0 02                          shl     eax,02H
 073f  01 c2                             add     edx,eax
 0741  8b 44 24 0c                       mov     eax,+0cH[esp]
 0745  8b 4a 0c                          mov     ecx,+0cH[edx]
 0748  89 42 40                          mov     +40H[edx],eax
 074b  83 f9 01                          cmp     ecx,00000001H
 074e  75 11                             jne     L45
 0750  a1 00 00 00 00                    mov     eax,_rt_first
 0755  89 da                             mov     edx,ebx
 0757  e8 00 00 00 00                    call    task_delete_
 075c  a3 00 00 00 00                    mov     _rt_first,eax
 0761  8d 04 9d 00 00 00 
       00                L45             lea     eax,+0H[ebx*4]
 0768  29 d8                             sub     eax,ebx
 076a  c1 e0 03                          shl     eax,03H
 076d  8d 14 03                          lea     edx,[ebx+eax]
 0770  a1 00 00 00 00                    mov     eax,_tcb
 0775  c1 e2 02                          shl     edx,02H
 0778  01 d0                             add     eax,edx
 077a  83 78 0c 01                       cmp     dword ptr +0cH[eax],00000001H
 077e  74 06                             je      L46
 0780  83 78 10 01                       cmp     dword ptr +10H[eax],00000001H
 0784  75 11                             jne     L47
 0786  a1 00 00 00 00    L46             mov     eax,_ts_first
 078b  89 da                             mov     edx,ebx
 078d  e8 00 00 00 00                    call    task_insert_
 0792  a3 00 00 00 00                    mov     _ts_first,eax
 0797  8d 04 9d 00 00 00 
       00                L47             lea     eax,+0H[ebx*4]
 079e  29 d8                             sub     eax,ebx
 07a0  c1 e0 03                          shl     eax,03H
 07a3  8b 15 00 00 00 00                 mov     edx,_tcb
 07a9  01 d8                             add     eax,ebx
 07ab  c7 44 82 0c 02 00 
       00 00                             mov     dword ptr +0cH[edx+eax*4],00000002H
 07b3  e9 1f 02 00 00                    jmp     L65
 07b8  8b 48 04          L48             mov     ecx,+4H[eax]
 07bb  89 c2                             mov     edx,eax
 07bd  83 f9 02                          cmp     ecx,00000002H
 07c0  74 0a                             je      L49
 07c2  b8 bc 00 00 00                    mov     eax,offset L134
 07c7  e9 00 00 00 00                    jmp     RTFatal_
 07cc  8b 12             L49             mov     edx,[edx]
 07ce  8b 42 04                          mov     eax,+4H[edx]
 07d1  89 44 24 34                       mov     +34H[esp],eax
 07d5  8b 42 08                          mov     eax,+8H[edx]
 07d8  8b 74 24 34                       mov     esi,+34H[esp]
 07dc  89 44 24 30                       mov     +30H[esp],eax
 07e0  81 fe 00 00 00 a0                 cmp     esi,0a0000000H
 07e6  7c 07                             jl      L50
 07e8  3d 00 00 00 a0                    cmp     eax,0a0000000H
 07ed  7d 0a                             jge     L51
 07ef  b8 ec 00 00 00    L50             mov     eax,offset L135
 07f4  e9 00 00 00 00                    jmp     RTFatal_
 07f9  8b 44 24 34       L51             mov     eax,+34H[esp]
 07fd  3d ff ff ff bf                    cmp     eax,0bfffffffH
 0802  7e 0a                             jle     L52
 0804  db 44 24 34                       fild    dword ptr +34H[esp]
 0808  dd 5c 24 20                       fstp    qword ptr +20H[esp]
 080c  eb 16                             jmp     L53
 080e  8b 14 c5 00 00 00 
       00                L52             mov     edx,+0H[eax*8]
 0815  8b 04 c5 04 00 00 
       00                                mov     eax,+4H[eax*8]
 081c  89 54 24 20                       mov     +20H[esp],edx
 0820  89 44 24 24                       mov     +24H[esp],eax
 0824  8b 54 24 30       L53             mov     edx,+30H[esp]
 0828  81 fa ff ff ff bf                 cmp     edx,0bfffffffH
 082e  7e 0a                             jle     L54
 0830  db 44 24 30                       fild    dword ptr +30H[esp]
 0834  dd 5c 24 18                       fstp    qword ptr +18H[esp]
 0838  eb 18                             jmp     L55
 083a  89 d0             L54             mov     eax,edx
 083c  8b 14 d5 00 00 00 
       00                                mov     edx,+0H[edx*8]
 0843  8b 04 c5 04 00 00 
       00                                mov     eax,+4H[eax*8]
 084a  89 54 24 18                       mov     +18H[esp],edx
 084e  89 44 24 1c                       mov     +1cH[esp],eax
 0852  d9 ee             L55             fldz    
 0854  dc 5c 24 20                       fcomp   qword ptr +20H[esp]
 0858  df e0                             fstsw   ax
 085a  9e                                sahf    
 085b  77 0b                             ja      L56
 085d  d9 ee                             fldz    
 085f  dc 5c 24 18                       fcomp   qword ptr +18H[esp]
 0863  df e0                             fstsw   ax
 0865  9e                                sahf    
 0866  76 0a                             jbe     L57
 0868  b8 0c 01 00 00    L56             mov     eax,offset L136
 086d  e9 00 00 00 00                    jmp     RTFatal_
 0872  dd 44 24 20       L57             fld     qword ptr +20H[esp]
 0876  dc 5c 24 18                       fcomp   qword ptr +18H[esp]
 087a  df e0                             fstsw   ax
 087c  9e                                sahf    
 087d  76 0a                             jbe     L58
 087f  b8 44 01 00 00                    mov     eax,offset L137
 0884  e9 00 00 00 00                    jmp     RTFatal_
 0889  8d 0c 9d 00 00 00 
       00                L58             lea     ecx,+0H[ebx*4]
 0890  29 d9                             sub     ecx,ebx
 0892  c1 e1 03                          shl     ecx,03H
 0895  dd 05 00 00 00 00                 fld     qword ptr _clock_period
 089b  01 d9                             add     ecx,ebx
 089d  8b 15 00 00 00 00                 mov     edx,_tcb
 08a3  c1 e1 02                          shl     ecx,02H
 08a6  8b 44 24 20                       mov     eax,+20H[esp]
 08aa  01 ca                             add     edx,ecx
 08ac  dc 0d 6b 01 00 00                 fmul    qword ptr L138
 08b2  89 42 1c                          mov     +1cH[edx],eax
 08b5  8b 44 24 24                       mov     eax,+24H[esp]
 08b9  89 42 20                          mov     +20H[edx],eax
 08bc  dc 5c 24 20                       fcomp   qword ptr +20H[esp]
 08c0  df e0                             fstsw   ax
 08c2  9e                                sahf    
 08c3  76 46                             jbe     L60
 08c5  dd 44 24 20                       fld     qword ptr +20H[esp]
 08c9  dc 1d 73 01 00 00                 fcomp   qword ptr L139
 08cf  df e0                             fstsw   ax
 08d1  9e                                sahf    
 08d2  76 2e                             jbe     L59
 08d4  dd 05 00 00 00 00                 fld     qword ptr _clock_period
 08da  dc 74 24 20                       fdiv    qword ptr +20H[esp]
 08de  83 ec 08                          sub     esp,00000008H
 08e1  dd 1c 24                          fstp    qword ptr [esp]
 08e4  e8 00 00 00 00                    call    floor_
 08e9  a1 00 00 00 00                    mov     eax,_tcb
 08ee  e8 00 00 00 00                    call    __CHP
 08f3  01 c1                             add     ecx,eax
 08f5  db 5c 24 08                       fistp   dword ptr +8H[esp]
 08f9  8b 44 24 08                       mov     eax,+8H[esp]
 08fd  89 41 40                          mov     +40H[ecx],eax
 0900  eb 10                             jmp     L61
 0902  c7 42 40 00 ca 9a 
       3b                L59             mov     dword ptr +40H[edx],3b9aca00H
 0909  eb 07                             jmp     L61
 090b  c7 42 40 01 00 00 
       00                L60             mov     dword ptr +40H[edx],00000001H
 0912  8d 04 9d 00 00 00 
       00                L61             lea     eax,+0H[ebx*4]
 0919  29 d8                             sub     eax,ebx
 091b  c1 e0 03                          shl     eax,03H
 091e  8d 14 03                          lea     edx,[ebx+eax]
 0921  a1 00 00 00 00                    mov     eax,_tcb
 0926  c1 e2 02                          shl     edx,02H
 0929  8b 4c 24 18                       mov     ecx,+18H[esp]
 092d  89 4c 02 24                       mov     +24H[edx+eax],ecx
 0931  8b 4c 24 1c                       mov     ecx,+1cH[esp]
 0935  89 4c 02 28                       mov     +28H[edx+eax],ecx
 0939  e8 00 00 00 00                    call    current_time_
 093e  dd 14 24                          fst     qword ptr [esp]
 0941  a1 00 00 00 00                    mov     eax,_tcb
 0946  dd 04 24                          fld     qword ptr [esp]
 0949  01 d0                             add     eax,edx
 094b  d9 c9                             fxch    st(1)
 094d  dc 44 24 20                       fadd    qword ptr +20H[esp]
 0951  d9 c9                             fxch    st(1)
 0953  dc 44 24 18                       fadd    qword ptr +18H[esp]
 0957  8b 14 24                          mov     edx,[esp]
 095a  8b 48 0c                          mov     ecx,+0cH[eax]
 095d  d9 c9                             fxch    st(1)
 095f  dd 58 2c                          fstp    qword ptr +2cH[eax]
 0962  89 50 14                          mov     +14H[eax],edx
 0965  8b 54 24 04                       mov     edx,+4H[esp]
 0969  dd 58 34                          fstp    qword ptr +34H[eax]
 096c  89 50 18                          mov     +18H[eax],edx
 096f  83 f9 02                          cmp     ecx,00000002H
 0972  75 11                             jne     L62
 0974  a1 00 00 00 00                    mov     eax,_ts_first
 0979  89 da                             mov     edx,ebx
 097b  e8 00 00 00 00                    call    task_delete_
 0980  a3 00 00 00 00                    mov     _ts_first,eax
 0985  8d 04 9d 00 00 00 
       00                L62             lea     eax,+0H[ebx*4]
 098c  29 d8                             sub     eax,ebx
 098e  c1 e0 03                          shl     eax,03H
 0991  8d 14 03                          lea     edx,[ebx+eax]
 0994  a1 00 00 00 00                    mov     eax,_tcb
 0999  c1 e2 02                          shl     edx,02H
 099c  01 d0                             add     eax,edx
 099e  83 78 0c 02                       cmp     dword ptr +0cH[eax],00000002H
 09a2  74 06                             je      L63
 09a4  83 78 10 01                       cmp     dword ptr +10H[eax],00000001H
 09a8  75 11                             jne     L64
 09aa  a1 00 00 00 00    L63             mov     eax,_rt_first
 09af  89 da                             mov     edx,ebx
 09b1  e8 00 00 00 00                    call    task_insert_
 09b6  a3 00 00 00 00                    mov     _rt_first,eax
 09bb  8d 04 9d 00 00 00 
       00                L64             lea     eax,+0H[ebx*4]
 09c2  29 d8                             sub     eax,ebx
 09c4  c1 e0 03                          shl     eax,03H
 09c7  8b 15 00 00 00 00                 mov     edx,_tcb
 09cd  01 d8                             add     eax,ebx
 09cf  c7 44 82 0c 01 00 
       00 00                             mov     dword ptr +0cH[edx+eax*4],00000001H
 09d7  8d 04 9d 00 00 00 
       00                L65             lea     eax,+0H[ebx*4]
 09de  29 d8                             sub     eax,ebx
 09e0  c1 e0 03                          shl     eax,03H
 09e3  8b 15 00 00 00 00                 mov     edx,_tcb
 09e9  01 d8                             add     eax,ebx
 09eb  c7 44 82 10 00 00 
       00 00                             mov     dword ptr +10H[edx+eax*4],00000000H
 09f3  89 ec                             mov     esp,ebp
 09f5  5d                                pop     ebp
 09f6  5f                                pop     edi
 09f7  5e                                pop     esi
 09f8  59                                pop     ecx
 09f9  5b                                pop     ebx
 09fa  c3                                ret     
 09fb  90                                nop     
 09fc  53                task_suspend_   push    ebx
 09fd  51                                push    ecx
 09fe  52                                push    edx
 09ff  56                                push    esi
 0a00  57                                push    edi
 0a01  55                                push    ebp
 0a02  89 e5                             mov     ebp,esp
 0a04  83 ec 0c                          sub     esp,0000000cH
 0a07  83 e4 f8                          and     esp,0fffffff8H
 0a0a  89 44 24 08                       mov     +8H[esp],eax
 0a0e  3d ff ff ff bf                    cmp     eax,0bfffffffH
 0a13  7e 09                             jle     L66
 0a15  db 44 24 08                       fild    dword ptr +8H[esp]
 0a19  dd 1c 24                          fstp    qword ptr [esp]
 0a1c  eb 28                             jmp     L68
 0a1e  3d 00 00 00 a0    L66             cmp     eax,0a0000000H
 0a23  7c 17                             jl      L67
 0a25  8b 14 c5 00 00 00 
       00                                mov     edx,+0H[eax*8]
 0a2c  8b 04 c5 04 00 00 
       00                                mov     eax,+4H[eax*8]
 0a33  89 14 24                          mov     [esp],edx
 0a36  89 44 24 04                       mov     +4H[esp],eax
 0a3a  eb 0a                             jmp     L68
 0a3c  b8 84 01 00 00    L67             mov     eax,offset L141
 0a41  e9 00 00 00 00                    jmp     RTFatal_
 0a46  8b 4c 24 04       L68             mov     ecx,+4H[esp]
 0a4a  51                                push    ecx
 0a4b  8b 74 24 04                       mov     esi,+4H[esp]
 0a4f  56                                push    esi
 0a50  e8 00 00 00 00                    call    which_task_
 0a55  89 c2                             mov     edx,eax
 0a57  c1 e0 02                          shl     eax,02H
 0a5a  29 d0                             sub     eax,edx
 0a5c  c1 e0 03                          shl     eax,03H
 0a5f  8d 1c 02                          lea     ebx,[edx+eax]
 0a62  a1 00 00 00 00                    mov     eax,_tcb
 0a67  c1 e3 02                          shl     ebx,02H
 0a6a  c7 44 03 10 01 00 
       00 00                             mov     dword ptr +10H[ebx+eax],00000001H
 0a72  c7 44 03 34 9c 75 
       00 88                             mov     dword ptr +34H[ebx+eax],8800759cH
 0a7a  8b 7c 03 0c                       mov     edi,+0cH[ebx+eax]
 0a7e  c7 44 03 38 3c e4 
       37 7e                             mov     dword ptr +38H[ebx+eax],7e37e43cH
 0a86  83 ff 01                          cmp     edi,00000001H
 0a89  75 11                             jne     L69
 0a8b  a1 00 00 00 00                    mov     eax,_rt_first
 0a90  e8 00 00 00 00                    call    task_delete_
 0a95  a3 00 00 00 00                    mov     _rt_first,eax
 0a9a  eb 0f                             jmp     L70
 0a9c  a1 00 00 00 00    L69             mov     eax,_ts_first
 0aa1  e8 00 00 00 00                    call    task_delete_
 0aa6  a3 00 00 00 00                    mov     _ts_first,eax
 0aab  89 ec             L70             mov     esp,ebp
 0aad  5d                                pop     ebp
 0aae  5f                                pop     edi
 0aaf  5e                                pop     esi
 0ab0  5a                                pop     edx
 0ab1  59                                pop     ecx
 0ab2  5b                                pop     ebx
 0ab3  c3                                ret     
 0ab4  53                task_list_      push    ebx
 0ab5  51                                push    ecx
 0ab6  52                                push    edx
 0ab7  56                                push    esi
 0ab8  55                                push    ebp
 0ab9  83 ec 04                          sub     esp,00000004H
 0abc  31 c0                             xor     eax,eax
 0abe  e8 00 00 00 00                    call    NewS1_
 0ac3  c1 e8 03                          shr     eax,03H
 0ac6  31 f6                             xor     esi,esi
 0ac8  05 00 00 00 80                    add     eax,80000000H
 0acd  8b 15 00 00 00 00                 mov     edx,_tcb_size
 0ad3  89 04 24                          mov     [esp],eax
 0ad6  85 d2                             test    edx,edx
 0ad8  7e 36                             jle     L73
 0ada  31 c9                             xor     ecx,ecx
 0adc  a1 00 00 00 00    L71             mov     eax,_tcb
 0ae1  01 c8                             add     eax,ecx
 0ae3  83 78 10 02                       cmp     dword ptr +10H[eax],00000002H
 0ae7  74 19                             je      L72
 0ae9  8b 68 08                          mov     ebp,+8H[eax]
 0aec  55                                push    ebp
 0aed  8b 50 04                          mov     edx,+4H[eax]
 0af0  52                                push    edx
 0af1  e8 00 00 00 00                    call    NewDouble_
 0af6  8b 14 24                          mov     edx,[esp]
 0af9  89 c3                             mov     ebx,eax
 0afb  89 e0                             mov     eax,esp
 0afd  e8 00 00 00 00                    call    Append_
 0b02  8b 1d 00 00 00 00 L72             mov     ebx,_tcb_size
 0b08  46                                inc     esi
 0b09  83 c1 64                          add     ecx,00000064H
 0b0c  39 de                             cmp     esi,ebx
 0b0e  7c cc                             jl      L71
 0b10  8b 04 24          L73             mov     eax,[esp]
 0b13  83 c4 04                          add     esp,00000004H
 0b16  5d                                pop     ebp
 0b17  5e                                pop     esi
 0b18  5a                                pop     edx
 0b19  59                                pop     ecx
 0b1a  5b                                pop     ebx
 0b1b  c3                                ret     
 0b1c  53                task_status_    push    ebx
 0b1d  51                                push    ecx
 0b1e  52                                push    edx
 0b1f  56                                push    esi
 0b20  57                                push    edi
 0b21  55                                push    ebp
 0b22  89 e5                             mov     ebp,esp
 0b24  83 ec 0c                          sub     esp,0000000cH
 0b27  83 e4 f8                          and     esp,0fffffff8H
 0b2a  8b 35 00 00 00 00                 mov     esi,_tcb
 0b30  89 44 24 08                       mov     +8H[esp],eax
 0b34  3d ff ff ff bf                    cmp     eax,0bfffffffH
 0b39  7e 09                             jle     L74
 0b3b  db 44 24 08                       fild    dword ptr +8H[esp]
 0b3f  dd 1c 24                          fstp    qword ptr [esp]
 0b42  eb 20                             jmp     L75
 0b44  3d 00 00 00 a0    L74             cmp     eax,0a0000000H
 0b49  0f 8c ed fe ff ff                 jl      L67
 0b4f  8b 1c c5 00 00 00 
       00                                mov     ebx,+0H[eax*8]
 0b56  8b 14 c5 04 00 00 
       00                                mov     edx,+4H[eax*8]
 0b5d  89 1c 24                          mov     [esp],ebx
 0b60  89 54 24 04                       mov     +4H[esp],edx
 0b64  bf ff ff ff ff    L75             mov     edi,0ffffffffH
 0b69  8b 0d 00 00 00 00                 mov     ecx,_tcb_size
 0b6f  8b 35 00 00 00 00                 mov     esi,_tcb
 0b75  85 c9                             test    ecx,ecx
 0b77  7e 3d                             jle     L79
 0b79  89 cb                             mov     ebx,ecx
 0b7b  c1 e1 02                          shl     ecx,02H
 0b7e  29 d9                             sub     ecx,ebx
 0b80  c1 e1 03                          shl     ecx,03H
 0b83  01 d9                             add     ecx,ebx
 0b85  31 d2                             xor     edx,edx
 0b87  c1 e1 02                          shl     ecx,02H
 0b8a  8d 1c 16          L76             lea     ebx,[esi+edx]
 0b8d  dd 43 04                          fld     qword ptr +4H[ebx]
 0b90  dc 1c 24                          fcomp   qword ptr [esp]
 0b93  df e0                             fstsw   ax
 0b95  9e                                sahf    
 0b96  75 17                             jne     L78
 0b98  8b 43 10                          mov     eax,+10H[ebx]
 0b9b  85 c0                             test    eax,eax
 0b9d  75 07                             jne     L77
 0b9f  bf 01 00 00 00                    mov     edi,00000001H
 0ba4  eb 10                             jmp     L79
 0ba6  83 f8 01          L77             cmp     eax,00000001H
 0ba9  75 0b                             jne     L79
 0bab  31 ff                             xor     edi,edi
 0bad  eb 07                             jmp     L79
 0baf  83 c2 64          L78             add     edx,00000064H
 0bb2  39 ca                             cmp     edx,ecx
 0bb4  7c d4                             jl      L76
 0bb6  89 f8             L79             mov     eax,edi
 0bb8  89 35 00 00 00 00                 mov     _tcb,esi
 0bbe  89 ec                             mov     esp,ebp
 0bc0  5d                                pop     ebp
 0bc1  5f                                pop     edi
 0bc2  5e                                pop     esi
 0bc3  5a                                pop     edx
 0bc4  59                                pop     ecx
 0bc5  5b                                pop     ebx
 0bc6  c3                                ret     
 0bc7  90                                nop     
 0bc8                    task_clock_stop_:
 0bc8  53                                push    ebx
 0bc9  83 3d 00 00 00 00 
       00                                cmp     dword ptr _clock_stopped,00000000H
 0bd0  75 16                             jne     L80
 0bd2  e8 00 00 00 00                    call    current_time_
 0bd7  bb 01 00 00 00                    mov     ebx,00000001H
 0bdc  dd 1d 00 00 00 00                 fstp    qword ptr _save_clock
 0be2  89 1d 00 00 00 00                 mov     _clock_stopped,ebx
 0be8  5b                L80             pop     ebx
 0be9  c3                                ret     
 0bea  8b c0                             mov     eax,eax
 0bec                    task_clock_start_:
 0bec  53                                push    ebx
 0bed  51                                push    ecx
 0bee  52                                push    edx
 0bef  56                                push    esi
 0bf0  55                                push    ebp
 0bf1  89 e5                             mov     ebp,esp
 0bf3  83 ec 08                          sub     esp,00000008H
 0bf6  83 e4 f8                          and     esp,0fffffff8H
 0bf9  83 3d 00 00 00 00 
       00                                cmp     dword ptr _clock_stopped,00000000H
 0c00  0f 84 71 00 00 00                 je      L83
 0c06  d9 ee                             fldz    
 0c08  dc 1d 00 00 00 00                 fcomp   qword ptr _save_clock
 0c0e  df e0                             fstsw   ax
 0c10  9e                                sahf    
 0c11  77 5c                             ja      L82
 0c13  e8 00 00 00 00                    call    current_time_
 0c18  dc 1d 00 00 00 00                 fcomp   qword ptr _save_clock
 0c1e  df e0                             fstsw   ax
 0c20  9e                                sahf    
 0c21  76 4c                             jbe     L82
 0c23  e8 00 00 00 00                    call    current_time_
 0c28  8b 1d 00 00 00 00                 mov     ebx,_tcb_size
 0c2e  dc 25 00 00 00 00                 fsub    qword ptr _save_clock
 0c34  31 d2                             xor     edx,edx
 0c36  dd 1c 24                          fstp    qword ptr [esp]
 0c39  85 db                             test    ebx,ebx
 0c3b  7e 32                             jle     L82
 0c3d  dd 04 24                          fld     qword ptr [esp]
 0c40  31 db                             xor     ebx,ebx
 0c42  a1 00 00 00 00    L81             mov     eax,_tcb
 0c47  83 c3 64                          add     ebx,00000064H
 0c4a  8b 0d 00 00 00 00                 mov     ecx,_tcb_size
 0c50  42                                inc     edx
 0c51  dd 44 03 d0                       fld     qword ptr -30H[ebx+eax]
 0c55  dd 44 03 c8                       fld     qword ptr -38H[ebx+eax]
 0c59  d8 c2                             fadd    st,st(2)
 0c5b  d9 c9                             fxch    st(1)
 0c5d  d8 c2                             fadd    st,st(2)
 0c5f  d9 c9                             fxch    st(1)
 0c61  dd 5c 03 c8                       fstp    qword ptr -38H[ebx+eax]
 0c65  dd 5c 03 d0                       fstp    qword ptr -30H[ebx+eax]
 0c69  39 ca                             cmp     edx,ecx
 0c6b  7c d5                             jl      L81
 0c6d  dd d8                             fstp    st(0)
 0c6f  31 f6             L82             xor     esi,esi
 0c71  89 35 00 00 00 00                 mov     _clock_stopped,esi
 0c77  89 ec             L83             mov     esp,ebp
 0c79  5d                                pop     ebp
 0c7a  5e                                pop     esi
 0c7b  5a                                pop     edx
 0c7c  59                                pop     ecx
 0c7d  5b                                pop     ebx
 0c7e  c3                                ret     
 0c7f  90                                nop     
 0c80  53                task_create_    push    ebx
 0c81  51                                push    ecx
 0c82  56                                push    esi
 0c83  57                                push    edi
 0c84  55                                push    ebp
 0c85  89 e5                             mov     ebp,esp
 0c87  83 ec 34                          sub     esp,00000034H
 0c8a  8b 0d 00 00 00 00                 mov     ecx,_tcb
 0c90  89 45 e4                          mov     -1cH[ebp],eax
 0c93  89 55 e8                          mov     -18H[ebp],edx
 0c96  89 c2                             mov     edx,eax
 0c98  b8 a0 01 00 00                    mov     eax,offset L142
 0c9d  e8 00 00 00 00                    call    get_pos_int_
 0ca2  89 45 e4                          mov     -1cH[ebp],eax
 0ca5  3d 00 ff ff ff                    cmp     eax,0ffffff00H
 0caa  72 0a                             jb      L84
 0cac  b8 ac 01 00 00                    mov     eax,offset L143
 0cb1  e9 00 00 00 00                    jmp     RTFatal_
 0cb6  81 7d e8 00 00 00 
       a0                L84             cmp     dword ptr -18H[ebp],0a0000000H
 0cbd  7c 0a                             jl      L85
 0cbf  b8 c0 01 00 00                    mov     eax,offset L144
 0cc4  e9 00 00 00 00                    jmp     RTFatal_
 0cc9  8b 55 e4          L85             mov     edx,-1cH[ebp]
 0ccc  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 0cd3  01 d0                             add     eax,edx
 0cd5  8b 14 85 0e 00 00 
       00                                mov     edx,__00+0eH[eax*4]
 0cdc  8b 45 e8                          mov     eax,-18H[ebp]
 0cdf  c1 e0 03                          shl     eax,03H
 0ce2  c1 fa 10                          sar     edx,10H
 0ce5  8b 58 04                          mov     ebx,+4H[eax]
 0ce8  39 da                             cmp     edx,ebx
 0cea  74 1e                             je      L86
 0cec  52                                push    edx
 0ced  53                                push    ebx
 0cee  68 e4 01 00 00                    push    offset L145
 0cf3  68 00 00 00 00                    push    offset _TempBuff
 0cf8  e8 00 00 00 00                    call    sprintf_
 0cfd  83 c4 10                          add     esp,00000010H
 0d00  b8 00 00 00 00                    mov     eax,offset _TempBuff
 0d05  e9 00 00 00 00                    jmp     RTFatal_
 0d0a  bf ff ff ff ff    L86             mov     edi,0ffffffffH
 0d0f  8b 35 00 00 00 00                 mov     esi,_tcb_size
 0d15  8b 0d 00 00 00 00                 mov     ecx,_tcb
 0d1b  89 7d f4                          mov     -0cH[ebp],edi
 0d1e  89 7d ec                          mov     -14H[ebp],edi
 0d21  89 7d f8                          mov     -8H[ebp],edi
 0d24  89 7d f0                          mov     -10H[ebp],edi
 0d27  31 ff                             xor     edi,edi
 0d29  85 f6                             test    esi,esi
 0d2b  0f 8e 8a 00 00 00                 jle     L92
 0d31  89 7d fc                          mov     -4H[ebp],edi
 0d34  8b 55 fc          L87             mov     edx,-4H[ebp]
 0d37  8d 1c 11                          lea     ebx,[ecx+edx]
 0d3a  83 7b 10 02                       cmp     dword ptr +10H[ebx],00000002H
 0d3e  75 05                             jne     L88
 0d40  8b 73 60                          mov     esi,+60H[ebx]
 0d43  eb 38                             jmp     L89
 0d45  8b 53 50          L88             mov     edx,+50H[ebx]
 0d48  8b 73 5c                          mov     esi,+5cH[ebx]
 0d4b  8b 43 60                          mov     eax,+60H[ebx]
 0d4e  29 d6                             sub     esi,edx
 0d50  89 c2                             mov     edx,eax
 0d52  c1 fa 1f                          sar     edx,1fH
 0d55  2b c2                             sub     eax,edx
 0d57  d1 f8                             sar     eax,1
 0d59  8b 53 50                          mov     edx,+50H[ebx]
 0d5c  01 d0                             add     eax,edx
 0d5e  8b 10                             mov     edx,[eax]
 0d60  c1 fe 02                          sar     esi,02H
 0d63  81 fa 3f 2a 1d 0f                 cmp     edx,0f1d2a3fH
 0d69  74 12                             je      L89
 0d6b  8b 43 60                          mov     eax,+60H[ebx]
 0d6e  89 c2                             mov     edx,eax
 0d70  c1 fa 1f                          sar     edx,1fH
 0d73  c1 e2 04                          shl     edx,04H
 0d76  1b c2                             sbb     eax,edx
 0d78  c1 f8 04                          sar     eax,04H
 0d7b  89 c6                             mov     esi,eax
 0d7d  3b 75 f8          L89             cmp     esi,-8H[ebp]
 0d80  7e 06                             jle     L90
 0d82  89 75 f8                          mov     -8H[ebp],esi
 0d85  89 7d ec                          mov     -14H[ebp],edi
 0d88  8b 75 fc          L90             mov     esi,-4H[ebp]
 0d8b  8d 04 31                          lea     eax,[ecx+esi]
 0d8e  83 78 10 02                       cmp     dword ptr +10H[eax],00000002H
 0d92  75 10                             jne     L91
 0d94  8b 5d f4                          mov     ebx,-0cH[ebp]
 0d97  8b 50 60                          mov     edx,+60H[eax]
 0d9a  39 da                             cmp     edx,ebx
 0d9c  7e 06                             jle     L91
 0d9e  89 7d f0                          mov     -10H[ebp],edi
 0da1  89 55 f4                          mov     -0cH[ebp],edx
 0da4  8b 75 fc          L91             mov     esi,-4H[ebp]
 0da7  a1 00 00 00 00                    mov     eax,_tcb_size
 0dac  83 c6 64                          add     esi,00000064H
 0daf  47                                inc     edi
 0db0  89 75 fc                          mov     -4H[ebp],esi
 0db3  39 c7                             cmp     edi,eax
 0db5  0f 8c 79 ff ff ff                 jl      L87
 0dbb  8b 55 f0          L92             mov     edx,-10H[ebp]
 0dbe  83 fa ff                          cmp     edx,0ffffffffH
 0dc1  75 47                             jne     L93
 0dc3  a1 00 00 00 00                    mov     eax,_tcb_size
 0dc8  40                                inc     eax
 0dc9  a3 00 00 00 00                    mov     _tcb_size,eax
 0dce  89 c2                             mov     edx,eax
 0dd0  c1 e0 02                          shl     eax,02H
 0dd3  29 d0                             sub     eax,edx
 0dd5  c1 e0 03                          shl     eax,03H
 0dd8  01 c2                             add     edx,eax
 0dda  c1 e2 02                          shl     edx,02H
 0ddd  89 c8                             mov     eax,ecx
 0ddf  89 0d 00 00 00 00                 mov     _tcb,ecx
 0de5  e8 00 00 00 00                    call    ERealloc_
 0dea  8b 15 00 00 00 00                 mov     edx,_tcb_size
 0df0  89 c3                             mov     ebx,eax
 0df2  4a                                dec     edx
 0df3  89 c1                             mov     ecx,eax
 0df5  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 0dfc  29 d0                             sub     eax,edx
 0dfe  c1 e0 03                          shl     eax,03H
 0e01  01 d0                             add     eax,edx
 0e03  c1 e0 02                          shl     eax,02H
 0e06  01 c3                             add     ebx,eax
 0e08  eb 5b                             jmp     L95
 0e0a  8d 04 95 00 00 00 
       00                L93             lea     eax,+0H[edx*4]
 0e11  29 d0                             sub     eax,edx
 0e13  c1 e0 03                          shl     eax,03H
 0e16  01 c2                             add     edx,eax
 0e18  c1 e2 02                          shl     edx,02H
 0e1b  8d 04 11                          lea     eax,[ecx+edx]
 0e1e  8b 58 48                          mov     ebx,+48H[eax]
 0e21  89 0d 00 00 00 00                 mov     _tcb,ecx
 0e27  81 fb ff ff ff bf                 cmp     ebx,0bfffffffH
 0e2d  7d 19                             jge     L94
 0e2f  8b 34 dd 08 00 00 
       00                                mov     esi,+8H[ebx*8]
 0e36  4e                                dec     esi
 0e37  89 34 dd 08 00 00 
       00                                mov     +8H[ebx*8],esi
 0e3e  75 08                             jne     L94
 0e40  8b 40 48                          mov     eax,+48H[eax]
 0e43  e8 00 00 00 00                    call    de_reference_
 0e48  8b 55 f0          L94             mov     edx,-10H[ebp]
 0e4b  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 0e52  29 d0                             sub     eax,edx
 0e54  c1 e0 03                          shl     eax,03H
 0e57  01 d0                             add     eax,edx
 0e59  8b 0d 00 00 00 00                 mov     ecx,_tcb
 0e5f  c1 e0 02                          shl     eax,02H
 0e62  8d 1c 01                          lea     ebx,[ecx+eax]
 0e65  c7 43 0c 01 00 00 
       00                L95             mov     dword ptr +0cH[ebx],00000001H
 0e6c  c7 43 10 01 00 00 
       00                                mov     dword ptr +10H[ebx],00000001H
 0e73  c7 43 14 00 00 00 
       00                                mov     dword ptr +14H[ebx],00000000H
 0e7a  c7 43 18 00 00 00 
       00                                mov     dword ptr +18H[ebx],00000000H
 0e81  c7 43 1c 00 00 00 
       00                                mov     dword ptr +1cH[ebx],00000000H
 0e88  c7 43 20 00 00 00 
       00                                mov     dword ptr +20H[ebx],00000000H
 0e8f  c7 43 24 00 00 00 
       00                                mov     dword ptr +24H[ebx],00000000H
 0e96  c7 43 28 00 00 00 
       00                                mov     dword ptr +28H[ebx],00000000H
 0e9d  c7 43 2c 00 00 00 
       00                                mov     dword ptr +2cH[ebx],00000000H
 0ea4  c7 43 30 00 00 00 
       00                                mov     dword ptr +30H[ebx],00000000H
 0eab  c7 43 34 9c 75 00 
       88                                mov     dword ptr +34H[ebx],8800759cH
 0eb2  c7 43 38 3c e4 37 
       7e                                mov     dword ptr +38H[ebx],7e37e43cH
 0eb9  c7 43 3c 01 00 00 
       00                                mov     dword ptr +3cH[ebx],00000001H
 0ec0  c7 43 40 01 00 00 
       00                                mov     dword ptr +40H[ebx],00000001H
 0ec7  8b 45 e4                          mov     eax,-1cH[ebp]
 0eca  c7 43 44 ff ff ff 
       ff                                mov     dword ptr +44H[ebx],0ffffffffH
 0ed1  dd 05 00 00 00 00                 fld     qword ptr _next_task_id
 0ed7  89 03                             mov     [ebx],eax
 0ed9  8b 45 e8                          mov     eax,-18H[ebp]
 0edc  dd 5b 04                          fstp    qword ptr +4H[ebx]
 0edf  89 43 48                          mov     +48H[ebx],eax
 0ee2  3d ff ff ff bf                    cmp     eax,0bfffffffH
 0ee7  7d 07                             jge     L96
 0ee9  ff 04 c5 08 00 00 
       00                                inc     dword ptr +8H[eax*8]
 0ef0  8b 7d f0          L96             mov     edi,-10H[ebp]
 0ef3  c7 43 4c 00 00 00 
       00                                mov     dword ptr +4cH[ebx],00000000H
 0efa  83 ff ff                          cmp     edi,0ffffffffH
 0efd  74 3a                             je      L97
 0eff  8d 04 bd 00 00 00 
       00                                lea     eax,+0H[edi*4]
 0f06  29 f8                             sub     eax,edi
 0f08  c1 e0 03                          shl     eax,03H
 0f0b  01 f8                             add     eax,edi
 0f0d  c1 e0 02                          shl     eax,02H
 0f10  8d 1c 01                          lea     ebx,[ecx+eax]
 0f13  8b 43 60                          mov     eax,+60H[ebx]
 0f16  89 c2                             mov     edx,eax
 0f18  c1 fa 1f                          sar     edx,1fH
 0f1b  2b c2                             sub     eax,edx
 0f1d  d1 f8                             sar     eax,1
 0f1f  8b 53 50                          mov     edx,+50H[ebx]
 0f22  c7 04 02 3f 2a 1d 
       0f                                mov     dword ptr [edx+eax],0f1d2a3fH
 0f29  8b 43 50                          mov     eax,+50H[ebx]
 0f2c  8b 53 60                          mov     edx,+60H[ebx]
 0f2f  01 d0                             add     eax,edx
 0f31  89 43 5c                          mov     +5cH[ebx],eax
 0f34  e9 34 01 00 00                    jmp     L101
 0f39  8b 55 ec          L97             mov     edx,-14H[ebp]
 0f3c  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 0f43  29 d0                             sub     eax,edx
 0f45  c1 e0 03                          shl     eax,03H
 0f48  01 d0                             add     eax,edx
 0f4a  c1 e0 02                          shl     eax,02H
 0f4d  8d 3c 01                          lea     edi,[ecx+eax]
 0f50  89 45 e0                          mov     -20H[ebp],eax
 0f53  8b 77 60                          mov     esi,+60H[edi]
 0f56  8b 47 50                          mov     eax,+50H[edi]
 0f59  c1 fe 03                          sar     esi,03H
 0f5c  89 43 50                          mov     +50H[ebx],eax
 0f5f  c1 e6 02                          shl     esi,02H
 0f62  8b 43 50                          mov     eax,+50H[ebx]
 0f65  89 f2                             mov     edx,esi
 0f67  01 f0                             add     eax,esi
 0f69  c1 fa 1f                          sar     edx,1fH
 0f6c  89 43 5c                          mov     +5cH[ebx],eax
 0f6f  89 f0                             mov     eax,esi
 0f71  2b c2                             sub     eax,edx
 0f73  d1 f8                             sar     eax,1
 0f75  8b 53 50                          mov     edx,+50H[ebx]
 0f78  89 73 60                          mov     +60H[ebx],esi
 0f7b  c7 04 02 3f 2a 1d 
       0f                                mov     dword ptr [edx+eax],0f1d2a3fH
 0f82  8b 57 50                          mov     edx,+50H[edi]
 0f85  01 f2                             add     edx,esi
 0f87  89 57 50                          mov     +50H[edi],edx
 0f8a  c7 02 3f 2a 1d 0f                 mov     dword ptr [edx],0f1d2a3fH
 0f90  31 db                             xor     ebx,ebx
 0f92  8b 57 50                          mov     edx,+50H[edi]
 0f95  89 77 60                          mov     +60H[edi],esi
 0f98  01 c2                             add     edx,eax
 0f9a  89 5d dc                          mov     -24H[ebp],ebx
 0f9d  89 0d 00 00 00 00                 mov     _tcb,ecx
 0fa3  89 65 dc                          mov     -24H[ebp],esp
 0fa6  8b 1d 00 00 00 00                 mov     ebx,_current_task
 0fac  8d 04 9d 00 00 00 
       00                                lea     eax,+0H[ebx*4]
 0fb3  29 d8                             sub     eax,ebx
 0fb5  c1 e0 03                          shl     eax,03H
 0fb8  01 d8                             add     eax,ebx
 0fba  8b 0d 00 00 00 00                 mov     ecx,_tcb
 0fc0  c1 e0 02                          shl     eax,02H
 0fc3  8d 3c 01                          lea     edi,[ecx+eax]
 0fc6  8b 45 dc                          mov     eax,-24H[ebp]
 0fc9  89 47 5c                          mov     +5cH[edi],eax
 0fcc  8b 45 e0                          mov     eax,-20H[ebp]
 0fcf  01 c8                             add     eax,ecx
 0fd1  8b 58 50                          mov     ebx,+50H[eax]
 0fd4  3b 58 5c                          cmp     ebx,+5cH[eax]
 0fd7  76 72                             jbe     L100
 0fd9  56                                push    esi
 0fda  8b 58 08                          mov     ebx,+8H[eax]
 0fdd  8b 70 04                          mov     esi,+4H[eax]
 0fe0  f7 c3 ff ff ff 7f                 test    ebx,7fffffffH
 0fe6  75 0b                             jne     L98
 0fe8  85 f6                             test    esi,esi
 0fea  75 07                             jne     L98
 0fec  b8 28 02 00 00                    mov     eax,offset L146
 0ff1  eb 12                             jmp     L99
 0ff3  8b 18             L98             mov     ebx,[eax]
 0ff5  8d 04 9d 00 00 00 
       00                                lea     eax,+0H[ebx*4]
 0ffc  01 d8                             add     eax,ebx
 0ffe  8b 04 85 00 00 00 
       00                                mov     eax,__00[eax*4]
 1005  8b 5d ec          L99             mov     ebx,-14H[ebp]
 1008  50                                push    eax
 1009  8d 04 9d 00 00 00 
       00                                lea     eax,+0H[ebx*4]
 1010  29 d8                             sub     eax,ebx
 1012  c1 e0 03                          shl     eax,03H
 1015  01 d8                             add     eax,ebx
 1017  89 cb                             mov     ebx,ecx
 1019  8b 7c 83 08                       mov     edi,+8H[ebx+eax*4]
 101d  57                                push    edi
 101e  8b 74 83 04                       mov     esi,+4H[ebx+eax*4]
 1022  56                                push    esi
 1023  68 38 02 00 00                    push    offset L147
 1028  68 00 00 00 00                    push    offset _TempBuff
 102d  89 0d 00 00 00 00                 mov     _tcb,ecx
 1033  e8 00 00 00 00                    call    sprintf_
 1038  83 c4 18                          add     esp,00000018H
 103b  b8 00 00 00 00                    mov     eax,offset _TempBuff
 1040  8b 0d 00 00 00 00                 mov     ecx,_tcb
 1046  e9 00 00 00 00                    jmp     RTFatal_
 104b  8b 5d ec          L100            mov     ebx,-14H[ebp]
 104e  8d 04 9d 00 00 00 
       00                                lea     eax,+0H[ebx*4]
 1055  29 d8                             sub     eax,ebx
 1057  c1 e0 03                          shl     eax,03H
 105a  01 c3                             add     ebx,eax
 105c  c1 e3 02                          shl     ebx,02H
 105f  89 c8                             mov     eax,ecx
 1061  3b 54 03 5c                       cmp     edx,+5cH[ebx+eax]
 1065  73 06                             jae     L101
 1067  c7 02 3f 2a 1d 0f                 mov     dword ptr [edx],0f1d2a3fH
 106d  a1 00 00 00 00    L101            mov     eax,_next_task_id
 1072  89 45 d4                          mov     -2cH[ebp],eax
 1075  a1 04 00 00 00                    mov     eax,_next_task_id+4H
 107a  8b 1d 00 00 00 00                 mov     ebx,_id_wrap
 1080  89 45 d8                          mov     -28H[ebp],eax
 1083  85 db                             test    ebx,ebx
 1085  75 1e                             jne     L102
 1087  dd 45 d4                          fld     qword ptr -2cH[ebp]
 108a  dc 1d 76 02 00 00                 fcomp   qword ptr L148
 1090  df e0                             fstsw   ax
 1092  9e                                sahf    
 1093  73 10                             jae     L102
 1095  d9 e8                             fld1    
 1097  dc 45 d4                          fadd    qword ptr -2cH[ebp]
 109a  dd 1d 00 00 00 00                 fstp    qword ptr _next_task_id
 10a0  e9 85 00 00 00                    jmp     L107
 10a5  be 01 00 00 00    L102            mov     esi,00000001H
 10aa  b8 00 00 f0 3f                    mov     eax,3ff00000H
 10af  31 ff                             xor     edi,edi
 10b1  89 35 00 00 00 00                 mov     _id_wrap,esi
 10b7  89 7d cc                          mov     -34H[ebp],edi
 10ba  89 45 d0                          mov     -30H[ebp],eax
 10bd  8b 35 00 00 00 00                 mov     esi,_tcb_size
 10c3  8b 45 cc          L103            mov     eax,-34H[ebp]
 10c6  a3 00 00 00 00                    mov     _next_task_id,eax
 10cb  8b 45 d0                          mov     eax,-30H[ebp]
 10ce  8b 15 00 00 00 00                 mov     edx,_tcb_size
 10d4  a3 04 00 00 00                    mov     _next_task_id+4H,eax
 10d9  85 d2                             test    edx,edx
 10db  7e 2d                             jle     L106
 10dd  31 d2                             xor     edx,edx
 10df  6b de 64                          imul    ebx,esi,64H
 10e2  89 c8             L104            mov     eax,ecx
 10e4  dd 05 00 00 00 00                 fld     qword ptr _next_task_id
 10ea  dc 5c 02 04                       fcomp   qword ptr +4H[edx+eax]
 10ee  df e0                             fstsw   ax
 10f0  9e                                sahf    
 10f1  75 10                             jne     L105
 10f3  31 ff                             xor     edi,edi
 10f5  89 3d 00 00 00 00                 mov     _next_task_id,edi
 10fb  89 3d 04 00 00 00                 mov     _next_task_id+4H,edi
 1101  eb 07                             jmp     L106
 1103  83 c2 64          L105            add     edx,00000064H
 1106  39 da                             cmp     edx,ebx
 1108  7c d8                             jl      L104
 110a  d9 ee             L106            fldz    
 110c  dc 1d 00 00 00 00                 fcomp   qword ptr _next_task_id
 1112  df e0                             fstsw   ax
 1114  9e                                sahf    
 1115  72 13                             jb      L107
 1117  d9 e8                             fld1    
 1119  dc 45 cc                          fadd    qword ptr -34H[ebp]
 111c  dd 55 cc                          fst     qword ptr -34H[ebp]
 111f  dc 1d 76 02 00 00                 fcomp   qword ptr L148
 1125  df e0                             fstsw   ax
 1127  9e                                sahf    
 1128  76 99                             jbe     L103
 112a  8b 55 d8          L107            mov     edx,-28H[ebp]
 112d  52                                push    edx
 112e  8b 5d d4                          mov     ebx,-2cH[ebp]
 1131  53                                push    ebx
 1132  89 0d 00 00 00 00                 mov     _tcb,ecx
 1138  e8 00 00 00 00                    call    NewDouble_
 113d  8b 0d 00 00 00 00                 mov     ecx,_tcb
 1143  89 ec                             mov     esp,ebp
 1145  5d                                pop     ebp
 1146  5f                                pop     edi
 1147  5e                                pop     esi
 1148  59                                pop     ecx
 1149  5b                                pop     ebx
 114a  c3                                ret     
 114b  90                                nop     
 114c  53                scheduler_      push    ebx
 114d  51                                push    ecx
 114e  52                                push    edx
 114f  56                                push    esi
 1150  57                                push    edi
 1151  55                                push    ebp
 1152  89 e5                             mov     ebp,esp
 1154  83 ec 14                          sub     esp,00000014H
 1157  8b 0d 00 00 00 00                 mov     ecx,_tcb
 115d  8b 15 00 00 00 00                 mov     edx,_clock_stopped
 1163  8b 35 00 00 00 00                 mov     esi,_rt_first
 1169  85 d2                             test    edx,edx
 116b  75 05                             jne     L108
 116d  83 fe ff                          cmp     esi,0ffffffffH
 1170  75 1d                             jne     L109
 1172  ba 00 00 f0 bf    L108            mov     edx,0bff00000H
 1177  31 db                             xor     ebx,ebx
 1179  bf 00 00 f0 3f                    mov     edi,3ff00000H
 117e  89 5d 1c                          mov     +1cH[ebp],ebx
 1181  89 55 20                          mov     +20H[ebp],edx
 1184  89 5d f4                          mov     -0cH[ebp],ebx
 1187  89 7d f8                          mov     -8H[ebp],edi
 118a  e9 d8 00 00 00                    jmp     L115
 118f  8d 04 b5 00 00 00 
       00                L109            lea     eax,+0H[esi*4]
 1196  29 f0                             sub     eax,esi
 1198  c1 e0 03                          shl     eax,03H
 119b  89 cb                             mov     ebx,ecx
 119d  01 f0                             add     eax,esi
 119f  8b 54 83 34                       mov     edx,+34H[ebx+eax*4]
 11a3  8b 44 83 38                       mov     eax,+38H[ebx+eax*4]
 11a7  89 45 f0                          mov     -10H[ebp],eax
 11aa  8d 04 b5 00 00 00 
       00                                lea     eax,+0H[esi*4]
 11b1  29 f0                             sub     eax,esi
 11b3  c1 e0 03                          shl     eax,03H
 11b6  01 f0                             add     eax,esi
 11b8  89 55 ec                          mov     -14H[ebp],edx
 11bb  8b 54 83 44                       mov     edx,+44H[ebx+eax*4]
 11bf  83 fa ff                          cmp     edx,0ffffffffH
 11c2  74 27                             je      L112
 11c4  6b c2 64          L110            imul    eax,edx,64H
 11c7  8d 1c 01                          lea     ebx,[ecx+eax]
 11ca  dd 43 34                          fld     qword ptr +34H[ebx]
 11cd  dc 5d ec                          fcomp   qword ptr -14H[ebp]
 11d0  df e0                             fstsw   ax
 11d2  9e                                sahf    
 11d3  73 0e                             jae     L111
 11d5  8b 43 34                          mov     eax,+34H[ebx]
 11d8  89 45 ec                          mov     -14H[ebp],eax
 11db  8b 43 38                          mov     eax,+38H[ebx]
 11de  89 d6                             mov     esi,edx
 11e0  89 45 f0                          mov     -10H[ebp],eax
 11e3  8b 53 44          L111            mov     edx,+44H[ebx]
 11e6  83 fa ff                          cmp     edx,0ffffffffH
 11e9  75 d9                             jne     L110
 11eb  8d 04 b5 00 00 00 
       00                L112            lea     eax,+0H[esi*4]
 11f2  29 f0                             sub     eax,esi
 11f4  c1 e0 03                          shl     eax,03H
 11f7  89 cb                             mov     ebx,ecx
 11f9  01 f0                             add     eax,esi
 11fb  8b 3d 00 00 00 00                 mov     edi,_current_task
 1201  8b 54 83 2c                       mov     edx,+2cH[ebx+eax*4]
 1205  8b 44 83 30                       mov     eax,+30H[ebx+eax*4]
 1209  89 55 f4                          mov     -0cH[ebp],edx
 120c  89 45 f8                          mov     -8H[ebp],eax
 120f  39 fe                             cmp     esi,edi
 1211  75 15                             jne     L113
 1213  8d 04 bd 00 00 00 
       00                                lea     eax,+0H[edi*4]
 121a  29 f8                             sub     eax,edi
 121c  c1 e0 03                          shl     eax,03H
 121f  01 f8                             add     eax,edi
 1221  83 7c 83 3c 00                    cmp     dword ptr +3cH[ebx+eax*4],00000000H
 1226  7f 3f                             jg      L115
 1228  8b 15 00 00 00 00 L113            mov     edx,_current_task
 122e  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 1235  29 d0                             sub     eax,edx
 1237  c1 e0 03                          shl     eax,03H
 123a  01 d0                             add     eax,edx
 123c  c1 e0 02                          shl     eax,02H
 123f  01 c8                             add     eax,ecx
 1241  83 78 0c 01                       cmp     dword ptr +0cH[eax],00000001H
 1245  75 07                             jne     L114
 1247  c7 40 3c 00 00 00 
       00                                mov     dword ptr +3cH[eax],00000000H
 124e  8d 04 b5 00 00 00 
       00                L114            lea     eax,+0H[esi*4]
 1255  29 f0                             sub     eax,esi
 1257  c1 e0 03                          shl     eax,03H
 125a  01 f0                             add     eax,esi
 125c  c1 e0 02                          shl     eax,02H
 125f  01 c8                             add     eax,ecx
 1261  8b 50 40                          mov     edx,+40H[eax]
 1264  89 50 3c                          mov     +3cH[eax],edx
 1267  dd 45 f4          L115            fld     qword ptr -0cH[ebp]
 126a  89 0d 00 00 00 00                 mov     _tcb,ecx
 1270  89 35 00 00 00 00                 mov     _earliest_task,esi
 1276  dc 5d 1c                          fcomp   qword ptr +1cH[ebp]
 1279  df e0                             fstsw   ax
 127b  9e                                sahf    
 127c  0f 86 9e 00 00 00                 jbe     L122
 1282  a1 00 00 00 00                    mov     eax,_ts_first
 1287  31 ff                             xor     edi,edi
 1289  83 f8 ff                          cmp     eax,0ffffffffH
 128c  74 1d                             je      L118
 128e  6b d8 64          L116            imul    ebx,eax,64H
 1291  8d 14 19                          lea     edx,[ecx+ebx]
 1294  83 7a 3c 00                       cmp     dword ptr +3cH[edx],00000000H
 1298  7e 09                             jle     L117
 129a  bf 01 00 00 00                    mov     edi,00000001H
 129f  89 c6                             mov     esi,eax
 12a1  eb 08                             jmp     L118
 12a3  8b 42 44          L117            mov     eax,+44H[edx]
 12a6  83 f8 ff                          cmp     eax,0ffffffffH
 12a9  75 e3                             jne     L116
 12ab  85 ff             L118            test    edi,edi
 12ad  75 22                             jne     L120
 12af  a1 00 00 00 00                    mov     eax,_ts_first
 12b4  83 f8 ff                          cmp     eax,0ffffffffH
 12b7  74 18                             je      L120
 12b9  89 cb                             mov     ebx,ecx
 12bb  6b d0 64          L119            imul    edx,eax,64H
 12be  89 c6                             mov     esi,eax
 12c0  8b 44 1a 40                       mov     eax,+40H[edx+ebx]
 12c4  89 44 1a 3c                       mov     +3cH[edx+ebx],eax
 12c8  8b 44 1a 44                       mov     eax,+44H[edx+ebx]
 12cc  83 f8 ff                          cmp     eax,0ffffffffH
 12cf  75 ea                             jne     L119
 12d1  89 0d 00 00 00 00 L120            mov     _tcb,ecx
 12d7  89 35 00 00 00 00                 mov     _earliest_task,esi
 12dd  83 fe ff                          cmp     esi,0ffffffffH
 12e0  75 07                             jne     L121
 12e2  31 c0                             xor     eax,eax
 12e4  e9 00 00 00 00                    jmp     Cleanup_
 12e9  8b 35 00 00 00 00 L121            mov     esi,_earliest_task
 12ef  8d 04 b5 00 00 00 
       00                                lea     eax,+0H[esi*4]
 12f6  29 f0                             sub     eax,esi
 12f8  8b 0d 00 00 00 00                 mov     ecx,_tcb
 12fe  c1 e0 03                          shl     eax,03H
 1301  89 ca                             mov     edx,ecx
 1303  01 f0                             add     eax,esi
 1305  83 7c 82 0c 01                    cmp     dword ptr +0cH[edx+eax*4],00000001H
 130a  75 14                             jne     L122
 130c  dd 45 f4                          fld     qword ptr -0cH[ebp]
 130f  dc 65 1c                          fsub    qword ptr +1cH[ebp]
 1312  83 ec 08                          sub     esp,00000008H
 1315  dd 1c 24                          fstp    qword ptr [esp]
 1318  e8 00 00 00 00                    call    wait_
 131d  dd 5d 1c                          fstp    qword ptr +1cH[ebp]
 1320  8b 35 00 00 00 00 L122            mov     esi,_earliest_task
 1326  8d 04 b5 00 00 00 
       00                                lea     eax,+0H[esi*4]
 132d  29 f0                             sub     eax,esi
 132f  c1 e0 03                          shl     eax,03H
 1332  01 f0                             add     eax,esi
 1334  8b 0d 00 00 00 00                 mov     ecx,_tcb
 133a  c1 e0 02                          shl     eax,02H
 133d  01 c8                             add     eax,ecx
 133f  8b 55 1c                          mov     edx,+1cH[ebp]
 1342  89 50 14                          mov     +14H[eax],edx
 1345  8b 55 20                          mov     edx,+20H[ebp]
 1348  89 50 18                          mov     +18H[eax],edx
 134b  3b 35 00 00 00 00                 cmp     esi,_current_task
 1351  0f 84 6b 01 00 00                 je      L128
 1357  60                                pushad  
 1358  89 65 fc                          mov     -4H[ebp],esp
 135b  8b 15 00 00 00 00                 mov     edx,_current_task
 1361  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 1368  29 d0                             sub     eax,edx
 136a  c1 e0 03                          shl     eax,03H
 136d  01 d0                             add     eax,edx
 136f  8b 0d 00 00 00 00                 mov     ecx,_tcb
 1375  c1 e0 02                          shl     eax,02H
 1378  8d 14 01                          lea     edx,[ecx+eax]
 137b  8b 45 fc                          mov     eax,-4H[ebp]
 137e  89 42 5c                          mov     +5cH[edx],eax
 1381  8b 45 fc                          mov     eax,-4H[ebp]
 1384  8b 5a 50                          mov     ebx,+50H[edx]
 1387  39 d8                             cmp     eax,ebx
 1389  72 0c                             jb      L123
 138b  81 3b 3f 2a 1d 0f                 cmp     dword ptr [ebx],0f1d2a3fH
 1391  0f 84 97 00 00 00                 je      L126
 1397  8b 15 00 00 00 00 L123            mov     edx,_current_task
 139d  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 13a4  29 d0                             sub     eax,edx
 13a6  c1 e0 03                          shl     eax,03H
 13a9  01 d0                             add     eax,edx
 13ab  c1 e0 02                          shl     eax,02H
 13ae  01 c8                             add     eax,ecx
 13b0  8b 35 00 00 00 00                 mov     esi,_earliest_task
 13b6  8b 50 60                          mov     edx,+60H[eax]
 13b9  8b 58 08                          mov     ebx,+8H[eax]
 13bc  8b 78 04                          mov     edi,+4H[eax]
 13bf  52                                push    edx
 13c0  f7 c3 ff ff ff 7f                 test    ebx,7fffffffH
 13c6  75 0b                             jne     L124
 13c8  85 ff                             test    edi,edi
 13ca  75 07                             jne     L124
 13cc  b8 28 02 00 00                    mov     eax,offset L146
 13d1  eb 12                             jmp     L125
 13d3  8b 10             L124            mov     edx,[eax]
 13d5  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 13dc  01 d0                             add     eax,edx
 13de  8b 04 85 00 00 00 
       00                                mov     eax,__00[eax*4]
 13e5  8b 15 00 00 00 00 L125            mov     edx,_current_task
 13eb  50                                push    eax
 13ec  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 13f3  29 d0                             sub     eax,edx
 13f5  c1 e0 03                          shl     eax,03H
 13f8  01 d0                             add     eax,edx
 13fa  89 ca                             mov     edx,ecx
 13fc  8b 5c 82 08                       mov     ebx,+8H[edx+eax*4]
 1400  53                                push    ebx
 1401  8b 7c 82 04                       mov     edi,+4H[edx+eax*4]
 1405  57                                push    edi
 1406  68 80 02 00 00                    push    offset L149
 140b  68 00 00 00 00                    push    offset _TempBuff
 1410  89 0d 00 00 00 00                 mov     _tcb,ecx
 1416  e8 00 00 00 00                    call    sprintf_
 141b  83 c4 18                          add     esp,00000018H
 141e  b8 00 00 00 00                    mov     eax,offset _TempBuff
 1423  8b 0d 00 00 00 00                 mov     ecx,_tcb
 1429  e9 00 00 00 00                    jmp     RTFatal_
 142e  8b 35 00 00 00 00 L126            mov     esi,_earliest_task
 1434  89 35 00 00 00 00                 mov     _current_task,esi
 143a  8d 04 b5 00 00 00 
       00                                lea     eax,+0H[esi*4]
 1441  29 f0                             sub     eax,esi
 1443  c1 e0 03                          shl     eax,03H
 1446  01 f0                             add     eax,esi
 1448  c1 e0 02                          shl     eax,02H
 144b  01 c8                             add     eax,ecx
 144d  89 cb                             mov     ebx,ecx
 144f  8b 50 4c                          mov     edx,+4cH[eax]
 1452  89 0d 00 00 00 00                 mov     _tcb,ecx
 1458  85 d2                             test    edx,edx
 145a  75 47                             jne     L127
 145c  c7 40 4c 01 00 00 
       00                                mov     dword ptr +4cH[eax],00000001H
 1463  8b 50 50                          mov     edx,+50H[eax]
 1466  8b 40 60                          mov     eax,+60H[eax]
 1469  01 d0                             add     eax,edx
 146b  89 45 fc                          mov     -4H[ebp],eax
 146e  8b 65 fc                          mov     esp,-4H[ebp]
 1471  8b 15 00 00 00 00                 mov     edx,_current_task
 1477  8d 04 95 00 00 00 
       00                                lea     eax,+0H[edx*4]
 147e  29 d0                             sub     eax,edx
 1480  c1 e0 03                          shl     eax,03H
 1483  01 c2                             add     edx,eax
 1485  8b 0d 00 00 00 00                 mov     ecx,_tcb
 148b  c1 e2 02                          shl     edx,02H
 148e  8d 04 11                          lea     eax,[ecx+edx]
 1491  8b 50 48                          mov     edx,+48H[eax]
 1494  8b 00                             mov     eax,[eax]
 1496  e8 00 00 00 00                    call    call_task_
 149b  8b 0d 00 00 00 00                 mov     ecx,_tcb
 14a1  eb 1f                             jmp     L128
 14a3  8d 04 b5 00 00 00 
       00                L127            lea     eax,+0H[esi*4]
 14aa  29 f0                             sub     eax,esi
 14ac  c1 e0 03                          shl     eax,03H
 14af  01 f0                             add     eax,esi
 14b1  8b 44 83 5c                       mov     eax,+5cH[ebx+eax*4]
 14b5  89 45 fc                          mov     -4H[ebp],eax
 14b8  8b 65 fc                          mov     esp,-4H[ebp]
 14bb  61                                popad   
 14bc  8b 35 00 00 00 00                 mov     esi,_earliest_task
 14c2  8b 0d 00 00 00 00 L128            mov     ecx,_tcb
 14c8  89 ec                             mov     esp,ebp
 14ca  5d                                pop     ebp
 14cb  5f                                pop     edi
 14cc  5e                                pop     esi
 14cd  5a                                pop     edx
 14ce  59                                pop     ecx
 14cf  5b                                pop     ebx
 14d0  c2 08 00                          ret     0008H

No disassembly errors

------------------------------------------------------------

Segment: CONST  DWORD USE32  000002bc bytes  
 0000  74 68 65 20 54 72 61 6e L129            - the Tran
 0008  73 6c 61 74 6f 72 20 73                 - slator s
 0010  75 70 70 6f 72 74 73 20                 - upports 
 0018  61 20 6d 61 78 69 6d 75                 - a maximu
 0020  6d 20 6f 66 20 31 32 20                 - m of 12 
 0028  61 72 67 75 6d 65 6e 74                 - argument
 0030  73 20 66 6f 72 20 74 61                 - s for ta
 0038  73 6b 73 00                             - sks.
 003c  8d ed b5 a0 f7 c6 b0 3e L130            - .......>
 0044  49 6e 76 61 6c 69 64 20 L131            - Invalid 
 004c  74 61 73 6b 20 69 64 3a                 - task id:
 0054  20 25 31 30 2e 33 67 00                 -  %10.3g.
 005c  74 61 73 6b 20 69 64 20 L132            - task id 
 0064  6d 75 73 74 20 6e 6f 74                 - must not
 006c  20 62 65 20 61 20 73 65                 -  be a se
 0074  71 75 65 6e 63 65 00 00                 - quence..
 007c  6e 75 6d 62 65 72 20 6f L133            - number o
 0084  66 20 65 78 65 63 75 74                 - f execut
 008c  69 6f 6e 73 20 6d 75 73                 - ions mus
 0094  74 20 62 65 20 61 6e 20                 - t be an 
 009c  69 6e 74 65 67 65 72 20                 - integer 
 00a4  76 61 6c 75 65 20 67 72                 - value gr
 00ac  65 61 74 65 72 20 74 68                 - eater th
 00b4  61 6e 20 30 00 00 00 00                 - an 0....
 00bc  73 65 63 6f 6e 64 20 61 L134            - second a
 00c4  72 67 75 6d 65 6e 74 20                 - rgument 
 00cc  6d 75 73 74 20 62 65 20                 - must be 
 00d4  7b 6d 69 6e 2d 74 69 6d                 - {min-tim
 00dc  65 2c 20 6d 61 78 2d 74                 - e, max-t
 00e4  69 6d 65 7d 00 00 00 00                 - ime}....
 00ec  6d 69 6e 20 61 6e 64 20 L135            - min and 
 00f4  6d 61 78 20 74 69 6d 65                 - max time
 00fc  73 20 6d 75 73 74 20 62                 - s must b
 0104  65 20 61 74 6f 6d 73 00                 - e atoms.
 010c  6d 69 6e 20 61 6e 64 20 L136            - min and 
 0114  6d 61 78 20 74 69 6d 65                 - max time
 011c  73 20 6d 75 73 74 20 62                 - s must b
 0124  65 20 67 72 65 61 74 65                 - e greate
 012c  72 20 74 68 61 6e 20 6f                 - r than o
 0134  72 20 65 71 75 61 6c 20                 - r equal 
 013c  74 6f 20 30 00 00 00 00                 - to 0....
 0144  74 61 73 6b 20 6d 69 6e L137            - task min
 014c  20 74 69 6d 65 20 6d 75                 -  time mu
 0154  73 74 20 62 65 20 3c 3d                 - st be <=
 015c  20 74 61 73 6b 20 6d 61                 -  task ma
 0164  78 20 74 69 6d 65 00                    - x time.
 016b  00 00 00 00 00 00 e0 3f L138            - .......?
 0173  95 d6 26 e8 0b 2e 11 3e L139            - ..&....>
 017b  00 00 80 ff ff ff cf 41 L140            - .......A
 0183  00                                      - .
 0184  61 20 74 61 73 6b 20 69 L141            - a task i
 018c  64 20 6d 75 73 74 20 62                 - d must b
 0194  65 20 61 6e 20 61 74 6f                 - e an ato
 019c  6d 00 00 00                             - m...
 01a0  74 61 73 6b 5f 63 72 65 L142            - task_cre
 01a8  61 74 65 00                             - ate.
 01ac  69 6e 76 61 6c 69 64 20 L143            - invalid 
 01b4  72 6f 75 74 69 6e 65 20                 - routine 
 01bc  69 64 00 00                             - id..
 01c0  41 72 67 75 6d 65 6e 74 L144            - Argument
 01c8  20 6c 69 73 74 20 6d 75                 -  list mu
 01d0  73 74 20 62 65 20 61 20                 - st be a 
 01d8  73 65 71 75 65 6e 63 65                 - sequence
 01e0  00 00 00 00                             - ....
 01e4  49 6e 63 6f 72 72 65 63 L145            - Incorrec
 01ec  74 20 6e 75 6d 62 65 72                 - t number
 01f4  20 6f 66 20 61 72 67 75                 -  of argu
 01fc  6d 65 6e 74 73 20 28 70                 - ments (p
 0204  61 73 73 69 6e 67 20 25                 - assing %
 020c  64 20 77 68 65 72 65 20                 - d where 
 0214  25 64 20 61 72 65 20 65                 - %d are e
 021c  78 70 65 63 74 65 64 29                 - xpected)
 0224  00 00 00 00                             - ....
 0228  69 6e 69 74 69 61 6c 20 L146            - initial 
 0230  74 61 73 6b 00 00 00 00                 - task....
 0238  54 61 73 6b 20 25 2e 30 L147            - Task %.0
 0240  66 20 28 25 2e 34 30 73                 - f (%.40s
 0248  29 20 6e 6f 20 6c 6f 6e                 - ) no lon
 0250  67 65 72 20 68 61 73 20                 - ger has 
 0258  65 6e 6f 75 67 68 20 73                 - enough s
 0260  74 61 63 6b 20 73 70 61                 - tack spa
 0268  63 65 20 28 25 64 20 62                 - ce (%d b
 0270  79 74 65 73 29 00                       - ytes).
 0276  00 80 fa ca 73 f9 3f 43 L148            - ....s.?C
 027e  00 00                                   - ..
 0280  54 61 73 6b 20 25 2e 30 L149            - Task %.0
 0288  66 20 28 25 2e 34 30 73                 - f (%.40s
 0290  29 20 65 78 63 65 65 64                 - ) exceed
 0298  65 64 20 69 74 73 20 73                 - ed its s
 02a0  74 61 63 6b 20 73 69 7a                 - tack siz
 02a8  65 20 6c 69 6d 69 74 20                 - e limit 
 02b0  6f 66 20 25 64 20 62 79                 - of %d by
 02b8  74 65 73 00                             - tes.

No disassembly errors

------------------------------------------------------------

Segment: _DATA  PARA USE32  00000020 bytes  
 0000  7b 14 ae 47 e1 7a 84 3f _clock_period   - {..G.z.?
 0008  00 00 00 00             _clock_stopped  - ....
 000c  00 00 00 00             _id_wrap        - ....
 0010  00 00 00 00 00 00 f0 3f _next_task_id   - .......?
 0018  00 00 00 00 00 00 f0 bf _save_clock     - ........

No disassembly errors

------------------------------------------------------------

Segment: _BSS  PARA USE32  00000018 bytes  

No disassembly errors

------------------------------------------------------------

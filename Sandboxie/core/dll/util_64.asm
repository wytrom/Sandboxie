;------------------------------------------------------------------------
; Copyright 2004-2020 Sandboxie Holdings, LLC 
;
; This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <https://www.gnu.org/licenses/>.
;------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Assembler Utilities -- 64-bit
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; ProtectCall2
;----------------------------------------------------------------------------


ProtectCall2            PROC

    sub rsp,8+(4*8)
    mov rax,rcx
    mov rcx,rdx
    mov rdx,r8
    call rax
    add rsp,8+(4*8)
    ret
    
ProtectCall2            ENDP


;----------------------------------------------------------------------------
; ProtectCall3
;----------------------------------------------------------------------------


;ProtectCall3           PROC
;
;   sub rsp,8+(4*8)
;   mov rax,rcx
;   mov rcx,rdx
;   mov rdx,r8
;   mov r8,r9
;   call rax
;   add rsp,8+(4*8)
;   ret
;
;ProtectCall3           ENDP


;----------------------------------------------------------------------------
; ProtectCall4
;----------------------------------------------------------------------------


ProtectCall4            PROC

    sub rsp,8+(4*8)
    mov rax,rcx
    mov rcx,rdx
    mov rdx,r8
    mov r8,r9
    mov r9,qword ptr [rsp+50h]
    call rax
    add rsp,8+(4*8)
    ret

ProtectCall4            ENDP


;----------------------------------------------------------------------------
; RpcRt_Ndr64AsyncClientCall
;----------------------------------------------------------------------------

EXTERN RpcRt_Ndr64AsyncClientCall_x64 : PROC
EXTERN Secure_HandleElevation     : PROC
EXTERN __sys_Ndr64AsyncClientCall : QWORD

RpcRt_Ndr64AsyncClientCall PROC

    mov rax,rsp
    mov [rax+1*8],rcx   ; spill pProxyInfo
    mov [rax+2*8],rdx   ; spill nProcNum
    mov [rax+3*8],r8    ; spill pReturnValue
    mov [rax+4*8],r9    ; spill first variadic parameter
    sub rsp,8+(4*8)

;;    xor rcx,rcx     ; clear pProxyInfo
;;    xor rdx,rdx     ; clear nProcNum
;;    xor r8,r8       ; clear pReturnValue
;	mov r8,[rsp + 8+(4*8)]			; return pointer
    lea r9,[rsp + 8+(4*8) + 4*8]    ; setup Args -> SECURE_UAC_ARGS
    call RpcRt_Ndr64AsyncClientCall_x64
        test al,al
        jnz WeHandleElevation
        
        lea rax,[rsp+8+(4*8)]
    mov rcx,[rax+1*8]   ; restore pProxyInfo
    mov rdx,[rax+2*8]   ; restore nProcNum
    mov r8,[rax+3*8]    ; restore pReturnValue
    mov r9,[rax+4*8]    ; restore first variadic parameter

    add rsp,8+(4*8)
        jmp [__sys_Ndr64AsyncClientCall]
    
WeHandleElevation:

    xor rcx,rcx     ; clear pStubDescriptor
    xor rdx,rdx     ; clear pFormat
    lea r8,[rsp + 8+(4*8) + 4*8]    ; setup Args -> SECURE_UAC_ARGS
    xor r9,r9       ; clear unused parameter
    call Secure_HandleElevation

    add rsp,8+(4*8)
    ret

RpcRt_Ndr64AsyncClientCall ENDP


;----------------------------------------------------------------------------
; Ldr_Inject_Entry64
;----------------------------------------------------------------------------


EXTERN Ldr_Inject_Entry           : PROC

Ldr_Inject_Entry64      PROC

        ;
        ; Normally we would start with sub rsp,8+(4*8) but in this case
        ; we know the caller has not aligned the stack correctly
        ;

    sub rsp,8+8+(4*8)
    lea rcx,[rsp+8+8+(4*8)]     ; setup pRetAddr parameter
    call Ldr_Inject_Entry
    add rsp,8+8+(4*8)
    
    ;
    ; clear the stack of any leftovers from Ldr_Inject_Entry.
    ; necessary because some injected code (e.g. F-Secure)
    ; assumes the stack is zero
    ;
    
    lea rdi,[rsp-200h]
    mov rcx,200h/8
    xor rax,rax
    cld
    rep stosq
    
    ret
    
Ldr_Inject_Entry64      ENDP


;----------------------------------------------------------------------------
; Gui_FixupCallbackPointers
;----------------------------------------------------------------------------


Gui_FixupCallbackPointers   PROC
    
    ;
    ; copy of USER32!FixupCallbackPointers
    ; with additional zeroing of the dword at [rcx+8] before returning
    ;

    mov     edx,dword ptr [rcx+18h]
    xor     r8d,r8d
    add     rdx,rcx
    cmp     dword ptr [rcx+8],r8d
    jbe     l02
l01:    mov     eax,dword ptr [rdx]
    inc     r8d
    add     rdx,4
    add     qword ptr [rax+rcx],rcx
    cmp     r8d,dword ptr [rcx+8]
    jb      l01
    xor     r8d,r8d
    mov     dword ptr [rcx+8],r8d
l02:    ret

Gui_FixupCallbackPointers   ENDP


;----------------------------------------------------------------------------
; Secure_NdrAsyncClientCall
;----------------------------------------------------------------------------


EXTERN RpcRt_NdrAsyncClientCall_x64      : PROC
EXTERN __sys_NdrAsyncClientCall : QWORD

RpcRt_NdrAsyncClientCall PROC

    mov rax,rsp
    mov [rax+1*8],rcx   ; spill pStubDescriptor
    mov [rax+2*8],rdx   ; spill pFormat
    mov [rax+3*8],r8    ; spill first variadic parameter
    mov [rax+4*8],r9    ; spill second variadic parameter
    sub rsp,8+(4*8)

;;    xor rcx,rcx     ; clear pStubDescriptor
;;    xor rdx,rdx     ; clear pFormat
;	mov r8,[rsp + 8+(4*8)]			; return pointer
    lea r8,[rsp + 8+(4*8) + 3*8]    ; Args
    call RpcRt_NdrAsyncClientCall_x64
    test al,al
    jnz CancelCallA
        
    lea rax,[rsp+8+(4*8)]
    mov rcx,[rax+1*8]   ; restore pStubDescriptor
    mov rdx,[rax+2*8]   ; restore pFormat
    mov r8,[rax+3*8]    ; restore first variadic parameter
    mov r9,[rax+4*8]    ; restore second variadic parameter

    add rsp,8+(4*8)
    jmp [__sys_NdrAsyncClientCall]
    
CancelCallA:

;;;    xor rcx,rcx     ; clear pProxyInfo
;;;    xor rdx,rdx     ; clear nProcNum
;;;    xor r8,r8       ; clear pReturnValue
;;	 mov r8,[rsp + 8+(4*8)]			 ; return pointer
;    lea r8,[rsp + 8+(4*8) + 3*8]    ; Args
;    call RpcRt_NdrAsyncClientCall_...

    add rsp,8+(4*8)
    ret

RpcRt_NdrAsyncClientCall ENDP


;----------------------------------------------------------------------------
; RpcRt_NdrClientCall2
;----------------------------------------------------------------------------


EXTERN RpcRt_NdrClientCall2_x64      : PROC
EXTERN __sys_NdrClientCall2 : QWORD

RpcRt_NdrClientCall2 PROC

    mov rax,rsp
    mov [rax+1*8],rcx   ; spill pStubDescriptor
    mov [rax+2*8],rdx   ; spill pFormat
    mov [rax+3*8],r8    ; spill first variadic parameter
    mov [rax+4*8],r9    ; spill second variadic parameter
    sub rsp,8+(4*8)

;;    xor rcx,rcx     ; clear pStubDescriptor
;;    xor rdx,rdx     ; clear pFormat
;	mov r8,[rsp + 8+(4*8)]			; return pointer
    lea r8,[rsp + 8+(4*8) + 3*8]    ; Args
    call RpcRt_NdrClientCall2_x64
    test al,al
    jnz CancelCall2
        
    lea rax,[rsp+8+(4*8)]
    mov rcx,[rax+1*8]   ; restore pStubDescriptor
    mov rdx,[rax+2*8]   ; restore pFormat
    mov r8,[rax+3*8]    ; restore first variadic parameter
    mov r9,[rax+4*8]    ; restore second variadic parameter

    add rsp,8+(4*8)
    jmp [__sys_NdrClientCall2]
    
CancelCall2:

;;;    xor rcx,rcx     ; clear pProxyInfo
;;;    xor rdx,rdx     ; clear nProcNum
;;;    xor r8,r8       ; clear pReturnValue
;;	 mov r8,[rsp + 8+(4*8)]			 ; return pointer
;    lea r8,[rsp + 8+(4*8) + 3*8]    ; Args
;    call RpcRt_NdrClientCall2_...

    add rsp,8+(4*8)
    ret

RpcRt_NdrClientCall2 ENDP


;----------------------------------------------------------------------------
; RpcRt_NdrClientCall3
;----------------------------------------------------------------------------


EXTERN RpcRt_NdrClientCall3_x64      : PROC
;EXTERN RpcRt_NdrClientCall3_...     : PROC
EXTERN __sys_NdrClientCall3 : QWORD

RpcRt_NdrClientCall3 PROC

    mov rax,rsp
    mov [rax+1*8],rcx   ; spill pProxyInfo
    mov [rax+2*8],rdx   ; spill nProcNum
    mov [rax+3*8],r8    ; spill pReturnValue
    mov [rax+4*8],r9    ; spill first variadic parameter
    sub rsp,8+(4*8)

;;    xor rcx,rcx     ; clear pProxyInfo
;;    xor rdx,rdx     ; clear nProcNum
;;    xor r8,r8       ; clear pReturnValue
;	mov r8,[rsp + 8+(4*8)]			; return pointer
    lea r9,[rsp + 8+(4*8) + 4*8]    ; Args
    call RpcRt_NdrClientCall3_x64
    test al,al
    jnz CancelCall3
        
    lea rax,[rsp+8+(4*8)]
    mov rcx,[rax+1*8]   ; restore pProxyInfo
    mov rdx,[rax+2*8]   ; restore nProcNum
    mov r8,[rax+3*8]    ; restore pReturnValue
    mov r9,[rax+4*8]    ; restore first variadic parameter

    add rsp,8+(4*8)
    jmp [__sys_NdrClientCall3]
    
CancelCall3:

;;;    xor rcx,rcx     ; clear pProxyInfo
;;;    xor rdx,rdx     ; clear nProcNum
;;;    xor r8,r8       ; clear pReturnValue
;;	 mov r8,[rsp + 8+(4*8)]			 ; return pointer
;    lea r9,[rsp + 8+(4*8) + 4*8]    ; Args
;    call RpcRt_NdrClientCall3_...

    add rsp,8+(4*8)
    ret

RpcRt_NdrClientCall3 ENDP



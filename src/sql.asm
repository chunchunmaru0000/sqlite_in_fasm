format pe64 console

include 'V:/fasm/include/win64a.inc'

section '.data' data readable writeable
; ######################################
; SOME STRINGS
; ######################################
    text_begin db '[ OPEN  CONN ]', 10, 0
    text_end db   '[ CLOSE CONN ]', 10, '# ура ура ура', 0
    text_prapare_begin db  '[ BEGIN PREPARE ] %s', 10, 0
    text_prapare_end db    '[ END   PREPARE ]', 10, 0
    text_step_return db    '[ STEP    RETURNED ] %lld', 10, 0
    text_destroy_return db '[ DESTROY RETURNED ] %lld', 10, 0
    
    text_user_record db '[ ID ] %ddl [ NAME ] %s [ AGE ] %lld', 10, 0
    
    a db 'some ___ %lld ___', 10, 0
    b dq 123
; ######################################
; DATABASE RELATED
; ######################################
    db_file_name db 'asdf.db', 0
    sql_connection dq 0 ; sqlite3 object **
    statement dq 0      ; sqlite3_stmt **
    
    SQLITE_ROW equ 100
    SQLITE_DONE equ 101
; ######################################
; QUERIES
; ######################################
    create_table_query db \
    'create table if not exists asdf(', \
        'id INTEGER PRIMARY KEY AUTOINCREMENT,', \
        'name TEXT, age INTEGER', \
    ')', 0
    insert_query db \
    'insert into asdf (name, age) values ', \
    '(',39,'fedkin',39,', 10),', \
    '(',39,'hui',39,', 123)', 0
    select_all_query db 'select * from asdf', 0
    
section '.code' executable
entry _main

_main:
; ######################################
; OPEN CONNECTION
; ######################################
    sub rsp, 40 ; Shadow space
    call begin
; ######################################
; CREATE TABLE
; ######################################
    push create_table_query ; push command
    call prepare            ; prepare command
    add rsp, 8              ; restore stack after push command
    call step               ; execute statement
    call destroy            ; destroy statement object
; ######################################
; DO SOME INSERTS
; ######################################
    mov r14, 10
    l:  push insert_query       ; push command
        call prepare            ; prepare command
        add rsp, 8              ; restore stack
        call step               ; execute statement
        call destroy            ; destroy statement object
        dec r14
        cmp r14, 0
        jnz l
; ######################################
; SELECT *
; ######################################
    push select_all_query ; push command
    call prepare            ; prepare command
    add rsp, 8              ; restore stack
    call step_scalar        ; execute statement
    call destroy            ; destroy statement object
; ######################################
; CLOSE CONNECTION
; ######################################
    call ending
exit:
    invoke ExitProcess, 0


step_scalar:
    sub rsp, 40

;int sqlite3_step(sqlite3_stmt*);  
    mov rcx, [statement]
    call [sqlite_step]
    
    mov rcx, text_step_return
    mov rdx, rax
    call [printf]
    
    add rsp, 40
    ret

destroy:
    sub rsp, 40
    
;int sqlite3_finalize(sqlite3_stmt *pStmt);
    mov rcx, [statement]
    call [sqlite_finalize]
    
    mov rcx, text_destroy_return
    mov rdx, rax
    call [printf]
    
    add rsp, 40
    ret

step:
    sub rsp, 40

;int sqlite3_step(sqlite3_stmt*);  
    mov rcx, [statement]
    call [sqlite_step]
    
    mov rcx, text_step_return
    mov rdx, rax
    call [printf]
    
    add rsp, 40
    ret

prepare:
    mov r13, [rsp+8] ; 8 bytes for [call prepare] instruction pointer
    sub rsp, 40

;int sqlite3_prepare_v2(
; connection
;     sqlite3 *db,            /* Database handle */
; statement string in UTF-8
;     const char *zSql,       /* SQL statement, UTF-8 encoded */
; If the nByte argument is negative, 
; then zSql is read up to the first zero terminator
;     int nByte,              /* Maximum length of zSql in bytes. */
;     sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
;     const char **pzTail     /* OUT: Pointer to unused portion of zSql */
;);
    mov rcx, text_prapare_begin
    mov rdx, r13
    call [printf]

    mov rcx, [sql_connection]
    mov rdx, r13
    xor r8, r8
    dec r8 ; r8 = -1 so negative nByte
    mov r9, statement
    push qword 0 ; **pzTail = null
    call [sqlite_prepare]
    
    mov rcx, text_prapare_end
    call [printf]
    
    add rsp, 48 ; + 8 for push qword 0
    ret


begin:
    sub rsp, 40
    
    mov rcx, db_file_name
    mov rdx, sql_connection
    call [sqlite_open]
    
    mov rcx, text_begin
    call [printf]
    
    add rsp, 40
    ret
    
ending:
    sub rsp, 40
   
    mov rcx, [sql_connection]
    call [sqlite_close]
    
    mov rcx, text_end
    call [printf]
    
    add rsp, 40
    ret
    
section '.idata' import readable writeable
    library kernel32, 'kernel32', msvcrt, 'msvcrt', sqlite, 'sqlite3'
    
    import kernel32, ExitProcess, 'ExitProcess'
    import msvcrt, printf, 'printf'
    import sqlite, \
        sqlite_open, 'sqlite3_open', \
        sqlite_close, 'sqlite3_close', \
        sqlite_prepare, 'sqlite3_prepare_v2', \
        sqlite_step, 'sqlite3_step', \
        sqlite_finalize, 'sqlite3_finalize'
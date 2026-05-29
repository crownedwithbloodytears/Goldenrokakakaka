#MaxThreadsPerHotkey 2

f1::
    Toggle := !Toggle
    Loop {
        If (!Toggle)
            Break
        SendInput, {Space}
        Sleep, 0.1   ; Задержка 1 мс (можешь увеличить, чтобы реже спамило)
    }
Return

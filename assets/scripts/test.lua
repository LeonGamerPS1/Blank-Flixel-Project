function opponentNoteHitPre(time, data, length, type)
    if type == "Alt Note" then
        print(os.date())
        return Function_Stop
    end
end

#Requires AutoHotkey v2.0-beta


Class MoveQueue {
    moveList := 0

    ;If an array of moves is passed in, moveList will be set to a clone of it
    __New(moveList := []) {
        this.moveList := []
        if (moveList.Length > 0) {
            this.moveList := moveList.Clone()
        }
    }

    addMove(direction) {
        this.moveList.Push(direction)
    }

    isMoveAnUndo(direction) {
        return direction = getOppositeDirection(this.getLastMove())
    }

    getLastMove() {
        if (this.moveList.Length = 0) {
            return false
        }

        return this.moveList[-1]
    }

    getMoveCount() {
        return this.moveList.Length
    }

    printMoves() {
        MsgBox(addArrayToStr(this.moveList, ""))
    }
}
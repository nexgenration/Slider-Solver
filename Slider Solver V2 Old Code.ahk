

    solveBoardFirstAttempt(visitedBoards := {}, currentDepth := 0, maxDepth := 200, moveList := MoveQueue()) {

        ;check that the depth isnt over the max
        if (currentDepth >= maxDepth) {
            return false
        }

        ;build the current board string, check if it already exists, then add it to the list if it doesnt
        boardString := this.buildBoardString()
        if (visitedBoards.HasOwnProp(boardString)) {
            return false
        }
        visitedBoards.boardString := currentDepth

        ;check if board is solved
        if (this.isBoardSolved()) {
            return moveList
        }

        ;attempt to move in each direction
        possibleMoves := this.getPossibleMoves(moveList.getLastMove())
        for direction in possibleMoves {

            ;try to perform a move using a clone of the move list
            ;the clone is for the sake of going back to this move list to search for different paths
            newMoveList := moveList.Clone()
            if (this.move(direction, newMoveList)) {

                ;recursively call solveBoard with the new move list and an incremented depth and store the result
                result := this.solveBoard(visitedBoards, currentDepth + 1, maxDepth, newMoveList)

                ;result will be true if it found a solution
                if (result) {

                    ;check if the solution is shorter than the current shortest solution. if so, set the new max allowed depth
                    if (result.currentDepth < maxDepth) {
                        maxDepth := result.currentDepth
                    }

                    ;check if the current depth is equal to the current max depth (which it should be if the above statement passed)
                    if (result.currentDepth = currentDepth + 1) {
                        return result
                    }
                }

                ;undo the last move
                this.move(getOppositeDirection(direction), newMoveList)
            }
        }
        return false
    }

    undo(moveList) {
        if (moveList.moveList.Length = 0) {
            return false
        }

        moveList.undoDirection := moveList.getLastMove()
        moveList.moveList.Pop()

        moveBackTo := this.getTileNeighbor(this.blankTile, getOppositeDirection(moveList.undoDirection))
        moveBackTo.moveTile(moveList.undoDirection)
        this.blankTile.moveTile(getOppositeDirection(moveList.undoDirection))

        return moveList.undoDirection
    }
#Requires AutoHotkey v2.0-beta



search(depthLimit, depth, path, closed, width, lastMove) {
    boardArray := path[path.Length]
    outerManhattanResults := getOuterManhattan(boardArray, width)
    outerManhattanValue := outerManhattanResults[1]
    outerTilesToBeMoved := outerManhattanResults[2]

    boardManhattanValue := 0
    heuristicValue := 0

    if (outerManhattanValue > 0) {
        heuristicValue := depth + outerManhattanValue
        depthLimitTemp := 0
        if (depth = 0) {
            depthLimitTemp := outerManhattanValue
        }

    }

    boardManhattanValue := getBoardManhattan(boardArray, width)
    if (boardManhattanValue = 0) {
        return path
    }
    heuristicValue := depth + boardManhattanValue

    if (heuristicValue > depthLimit) {
        return false
    }

    for i, direction in getPossibleMoves(boardArray, width, lastMove) {
        newBoard := boardArray.Clone()
        if (!applyMove(newBoard, width, direction)) {
            continue
        }

        boardString := createBoardString(newBoard)

        if (!closed.HasOwnProp(boardString)) {
            path.Push(newBoard)
            closed.%boardString% := true

            if (search(depthLimit, depth + 1, path, closed, width, direction)) {
                return true
            }
            path.Pop()
        }
    }
    return false
}

searchOuter(depthLimit, depth, path, closed, width, lastMove) {
    boardArray := path[path.Length]
    outerManhattanResults := getOuterManhattan(boardArray, width)
    outerManhattanValue := outerManhattanResults[1]
    outerTilesToBeMoved := outerManhattanResults[2]
    heuristicValue := depth + outerManhattanValue

    if (outerManhattanValue = 0) {
        return path
    }

    if (heuristicValue > depthLimit) {
        return false
    }

    for i, tile in outerTilesToBeMoved{
        for i, direction in getPossibleMoves(boardArray, width, lastMove, tile, true) {
            newBoard := boardArray.Clone()
            if (!applyMove(newBoard, width, direction)) {
                continue
            }
    
            boardString := createBoardString(newBoard)
    
            if (!closed.HasOwnProp(boardString)) {
                path.Push(newBoard)
                closed.%boardString% := true
    
                if (searchOuter(depthLimit, depth + 1, path, closed, width, direction)) {
                    return true
                }
                path.Pop()
            }
        }
    }
    return false
}
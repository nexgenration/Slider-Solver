#Requires AutoHotkey v2.0-beta


search(depthLimit, depth, path, closed, width, lastMove, &bestPath) {
    boardArray := path[path.Length]
    boardManhattanValue := getBoardManhattan(boardArray, width)
    if (boardManhattanValue = 0) {
        return path
    }
/*
    outerManhattanResults := getOuterManhattan(boardArray, width)
    outerManhattanValue := outerManhattanResults[1]
    outerManhattanTileIndexes := outerManhattanResults[2]

    if (outerManhattanValue > 0) {
        shortTermGoals := getShortTermGoals(boardArray, width, outerManhattanTileIndexes)
        closedBackup := closed.Clone()
        for i, destination in shortTermGoals {
            closed := closedBackup.Clone()
            if (!pathFindSearch(depthLimit, depth, path, closed, width, lastMove, destination[1], destination[2])) {
                continue
            }

            direction := getOppositeDirection(destination[3])
            newBoard := boardArray.Clone()
            applyMove(newBoard, width, direction)
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

        blankTileIndex := getTileIndex(boardArray, boardArray.Length)
        for i, direction in [UP_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, RIGHT_DIRECTION] {
            adjacentTileIndex := getAdjacentTileIndex(width, boardArray.Length, blankTileIndex, direction)
            for j, outerTileIndex in outerManhattanTileIndexes {
                if (
                    adjacentTileIndex = outerTileIndex
                    && isMoveDesired(width, boardArray[adjacentTileIndex], adjacentTileIndex, getOppositeDirection(direction))
                ) {
                    newBoard := boardArray.Clone()
                    applyMove(newBoard, width, direction)
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
            }
        }
    }
*/
    heuristicValue := depth + boardManhattanValue

    if (heuristicValue > depthLimit) {
        if(bestPath.Length = 0 || getBoardManhattan(bestPath[-1], width) > boardManhattanValue){
            bestPath := clonePath(path)
        }

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

            if (search(depthLimit, depth + 1, path, closed, width, direction, &bestPath)) {
                return true
            }
            path.Pop()
        }
    }
    return false
}

searchOuter(depthLimit, depth, path, closed, width, lastMove) {
    boardArray := path[path.Length]
    boardManhattanValue := getBoardManhattan(boardArray, width)
    outerManhattanResults := getOuterManhattan(boardArray, width)
    outerManhattanValue := outerManhattanResults[1]
    outerTileIndexesToBeMoved := outerManhattanResults[2]
    heuristicValue := depth + outerManhattanValue
    blankTileIndex := getTileIndex(boardArray, boardArray.Length)

    if (outerManhattanValue = 0) {
        return path
    }

    if (heuristicValue > depthLimit) {
        return false
    }

    for i, tileIndex in outerTileIndexesToBeMoved {
        for j, direction in getPossibleMoves(boardArray, width, lastMove, tile, false) {
            destination := getAdjacentTileIndex(width, boardArray.Length, tileIndex, direction)
            newBoard := boardArray.Clone()

            if (blankTileIndex != destination) {
                depthLimitTemp := boardManhattanValue
                pathFindingDepth := 0
                while (depth + pathFindingDepth < depthLimit) {
                    closedTemp := closed.Clone()
                    pathTemp := path.Clone()
                    if (pathFindSearch(depthLimitTemp, depth, pathTemp, closedTemp, width, lastMove, tileIndex, destination)) {
                        return path
                    }
                    depthLimitTemp++
                    pathFindingDepth++
                }
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

pathFindSearch(depthLimit, depth, path, closed, width, lastMove, tileIndexToAvoid, destination) {
    boardArray := path[path.Length]
    blankTileIndex := getTileIndex(boardArray, boardArray.Length)
    if (blankTileIndex = destination) {
        return path
    }

    boardManhattanValue := getBoardManhattan(boardArray, width)
    heuristicValue := depth + boardManhattanValue
    if (heuristicValue > depthLimit) {
        return false
    }

    for i, direction in getPossibleMoves(boardArray, width, lastMove, tileIndexToAvoid) {
        newBoard := boardArray.Clone()
        if (!applyMove(newBoard, width, direction)) {
            continue
        }

        boardString := createBoardString(newBoard)
        if (!closed.HasOwnProp(boardString)) {
            path.Push(newBoard)
            if (depthLimit > 70) {
                printBoard(path[-1], width, "Move")
            }
            closed.%boardString% := true

            if (pathFindSearch(depthLimit, depth + 1, path, closed, width, direction, tileIndexToAvoid, destination)) {
                return path
            }
            path.Pop()
            if (depthLimit > 70) {
                printBoard(path[-1], width, "Pop")
            }
        }
    }
    return false
}

solveFirstTile(depthLimit, depth, path, closed, width, lastMove) {
    boardArray := path[path.Length]
    firstTileIndex := getTileIndex(boardArray, 1)
    if (boardArray[1] = 1) {
        return path
    }

    boardManhattanValue := getBoardManhattan(boardArray, width)
    heuristicValue := depth + boardManhattanValue
    if (heuristicValue > depthLimit) {
        return false
    }

    closedBackup := closed.Clone()
    for i, direction in [UP_DIRECTION, LEFT_DIRECTION] {
        adjacentTileIndex := getAdjacentTileIndex(width, boardArray.Length, firstTileIndex, direction)
        if (!adjacentTileIndex) {
            continue
        }

        closed := closedBackup.Clone()
        if (!pathFindSearch(depthLimit, depth, path, closed, width, lastMove, firstTileIndex, adjacentTileIndex)) {
            continue
        }

        newBoard := path[-1].Clone()
        applyMove(newBoard, width, getOppositeDirection(direction))
        boardString := createBoardString(newBoard)

        if (!closed.HasOwnProp(boardString)) {
            path.Push(newBoard)
            closed.%boardString% := true

            if (solveFirstTile(depthLimit, depth + 1, path, closed, width, direction)) {
                return true
            }
            path.Pop()
        }
    }
}
;#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
;SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Include Tile.ahk
#Include MoveQueue.ahk
#Include Board.ahk
#Include Screen Scanner.ahk
#Include Board Array.ahk
#Include SearchFunctions.ahk

global UP_DIRECTION := "UP"
global DOWN_DIRECTION := "DOWN"
global LEFT_DIRECTION := "LEFT"
global RIGHT_DIRECTION := "RIGHT"

global SOLVEDBOARD := Board(5, 5)
global SOLVEDBOARDSTRING := SOLVEDBOARD.toString()
global INVALID_BOARD := Board(1, 1, [0], true)

global searchX1 := 800
global searchX2 := 1111
global searchY1 := 280
global searchY2 := 620


solve5x5() {
    moveQueue := []
    strBuffer := ""
    obstacles := []
    boardFound := false
    currentBoard := 0

    possibleBoards := ["Archers", "Bloodveld", "Castle", "Citadel", "Duck", "Elves", "Greg", "Helwyr", "Nomad", "Nymora", "Pharaoh"
        , "Rax", "Strykewyrm", "swordOfEdicts", "Traveler", "Tree", "Troll", "Tuska", "V", "Vyre", "Werewolf", "Wizard", "Wyvern"]

    for i, boardName in possibleBoards {
        currentBoard := getBoardFromScreen(boardName)
        if (!currentBoard.invalidFlag) {
            strBuffer .= boardName " board found and successfully mapped"
            MsgBox(strBuffer)
            Break
        }
    }

    if (!currentBoard) {
        strBuffer := "No valid board found.`nBoards checked:`n"
        addArrayToStr(possibleBoards, strBuffer)
        MsgBox(strBuffer)
        return
    }

    currentBoard.printBoard()
    currentBoard.solveBoard()
    currentBoard.printBoard()
    ; solveRow(1, obstacles)
    ; solveRow(2, obstacles)
    ; solveRow(3, obstacles)
    ; solveBottom(obstacles)
    ; spin()
    ; cleanMoveQueue()

    ; if (isBoardSolved()) {
    ;     strBuffer .= "`nBoard solved in " moveQueue.Length() " moves"
    ; } else {
    ;     strBuffer .= "`nBoard was not solved correctly!!!!"
    ; }
    ; ToolTip, %strBuffer
    ; Sleep 3000
    ; ToolTip, %""
}

solvePuzzle(boardArray, width)
{
    depthLimit := getBoardManhattan(boardArray, width)
    while (true) {
        closed := {}
        path := [boardArray]
        if (solveFirstTile(depthLimit, 0, path, closed, width, 0)) {
            break
        }
        depthLimit++
    }
    /*
        depth_limit := getOuterManhattan(boardArray, width)[1]
        while (true) {
            closed := {}
            path := [boardArray]
            if (searchOuter(depth_limit, 0, path, closed, width, 0)) {
                return path
            }
            depth_limit++
        }
    */
    boardArray := path[-1]
    depthLimit := getBoardManhattan(boardArray, width)
    depthLimitIncreases := 0
    pathCheckpoint := clonePath(path)
    while (true) {
        bestPath := []
        closed := {}
        path := clonePath(pathCheckpoint)
        boardArray := path[-1]
        solutionFound := search(depthLimit, 0, path, closed, width, 0, &bestPath)
        if (solutionFound) {
            return path
        }

        if(depthLimitIncreases = 10){
            pathCheckpoint := clonePath(bestPath)
            depthLimit := getBoardManhattan(path[-1], width)
            depthLimitIncreases := 0
            continue
        }
        depthLimitIncreases++
        depthLimit++
    }
    return []
}

;tile is the tile being moved, direction is the oposite direction the tile is being moved in (as if blank tile is moving in the given direction)
isMoveAMistake(tile, direction) {
    if (direction = UP_DIRECTION && tile.row >= tile.desiredRow) {
        return true
    } else if (direction = DOWN_DIRECTION && tile.row <= tile.desiredRow) {
        return true
    } else if (direction = LEFT_DIRECTION && tile.col >= tile.desiredCol) {
        return true
    } else if (direction = RIGHT_DIRECTION && tile.col <= tile.desiredCol) {
        return true
    }
    return false
}

/**Moves the blank tile to a destination while avoiding the movement of a single tile.
 * 
 * Tries to always move tiles closer to their destination rather than further away.
 **/
pathFind(pathToRow, pathToCol, &moveList, &boardObj, obstacle) {
    ;make a queue, a board string, a progress modifier, and a current best path
    ;set the progress modifier in the best path to a number it should never naturally reach
    boardStateQueue := []
    initialBoardString := boardObj.buildBoardString()
    mistakesCount := 0
    currentBestPath := { board: boardObj, moves: moveList, mistakes: boardObj.width * boardObj.height }

    ;add current board state to the queue
    boardStateQueue.Push({ board: boardObj, moves: moveList, mistakes: mistakesCount })

    ;loop through each board state on a first-in-first-out basis. this ensures the shortest path is always found
    while (boardStateQueue.Length > 0) {

        ;grab the first board state on the queue and remove it from the queue
        currentState := boardStateQueue[1]
        boardStateQueue.RemoveAt(1)
        currentBoard := currentState.board
        currentMoves := currentState.moves
        currentMistakesCount := currentState.mistakes

        ;set a few bools that will help with checking the board state for various properties
        upFromDest := currentBoard.blankTile.row < pathToRow
        downFromDest := currentBoard.blankTile.row > pathToRow
        leftFromDest := currentBoard.blankTile.col < pathToCol
        rightFromDest := currentBoard.blankTile.col > pathToCol
        inDestRow := currentBoard.blankTile.row = pathToRow
        inDestCol := currentBoard.blankTile.col = pathToCol

        upFromObstacle := currentBoard.blankTile.row < obstacle.row
        downFromObstacle := currentBoard.blankTile.row > obstacle.row
        leftFromObstacle := currentBoard.blankTile.col < obstacle.col
        rightFromObstacle := currentBoard.blankTile.col > obstacle.col
        inObstacleRow := currentBoard.blankTile.row = obstacle.row
        inObstacleCol := currentBoard.blankTile.col = obstacle.col

        destUpFromObstacle := pathToRow < obstacle.row
        destDownFromObstacle := pathToRow > obstacle.row
        destLeftFromObstacle := pathToCol < obstacle.col
        destRightFromObstacle := pathToCol > obstacle.col

        ;check if the blank tile in the board state that was just grabbed is in the destination slot
        if (inDestRow && inDestCol) {
            if (currentMistakesCount < currentBestPath.mistakes) {
                currentBestPath := { board: currentBoard, moves: currentMoves, mistakes: currentMistakesCount }
            }
            continue
        }

        ;loop through each direction, only attempting to make a move if it makes progress towards the destination
        for direction in [UP_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, RIGHT_DIRECTION] {
            neighbor := currentBoard.getTileNeighbor(currentBoard.blankTile, direction)
            newMistakesCount := currentMistakesCount

            ;make sure it isnt moving the obstacle tile and check that the direction is valid
            if (!neighbor || neighbor.num = obstacle.num) {
                continue
            }

            if (direction = UP_DIRECTION) {

                ;make sure it isnt above the destination
                if (upFromDest) {
                    continue
                }

                ;if in destination row, only allow it to move down when stuck behind obstacle
                if (inDestRow) {
                    if (!inObstacleRow) {
                        continue
                    }

                    if ((rightFromDest && rightFromObstacle && destRightFromObstacle) || (leftFromDest && leftFromObstacle && destLeftFromObstacle)) {
                        continue
                    }
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.row = pathToRow + 1 &&
                    ((leftFromDest && obstacle.col < pathToCol) ||
                        (rightFromDest && obstacle.col > pathToCol))) {
                    continue
                }
            } else if (direction = DOWN_DIRECTION) {

                ;make sure it isnt below the destination
                if (downFromDest) {
                    continue
                }

                ;if in destination row, only allow it to move down when stuck behind obstacle
                if (inDestRow) {
                    if (!inObstacleRow) {
                        continue
                    }

                    if ((rightFromDest && rightFromObstacle && destRightFromObstacle) || (leftFromDest && leftFromObstacle && destLeftFromObstacle)) {
                        continue
                    }
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.row = pathToRow - 1 &&
                    ((leftFromDest && obstacle.col < pathToCol) ||
                        (rightFromDest && obstacle.col > pathToCol))) {
                    continue
                }
            } else if (direction = LEFT_DIRECTION) {

                ;make sure it isnt left of the destination
                if (leftFromDest) {
                    continue
                }

                ;if in destination col, only allow it to move right when stuck behind obstacle
                if (inDestCol) {
                    if (!inObstacleCol) {
                        continue
                    }

                    if ((upFromDest && upFromObstacle && destUpFromObstacle) || (downFromDest && downFromObstacle && destDownFromObstacle)) {
                        continue
                    }
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.col = pathToCol + 1 &&
                    ((upFromDest && obstacle.row < pathToRow) ||
                        (downFromDest && obstacle.row > pathToRow))) {
                    continue
                }
            } else if (direction = RIGHT_DIRECTION) {

                ;make sure it isnt right of the destination
                if (rightFromDest) {
                    continue
                }

                ;if in destination col, only allow it to move right when stuck behind obstacle
                if (inDestCol) {
                    if (!inObstacleCol) {
                        continue
                    }

                    if ((upFromDest && upFromObstacle && destUpFromObstacle) || (downFromDest && downFromObstacle && destDownFromObstacle)) {
                        continue
                    }
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.col = pathToCol - 1 &&
                    ((upFromDest && obstacle.row < pathToRow) ||
                        (downFromDest && obstacle.row > pathToRow))) {
                    continue
                }
            }

            newMistakesCount += isMoveAMistake(neighbor, direction)

            ;clone both the board and moves list
            newBoard := currentBoard.makeCopy()
            newMoveList := MoveQueue(currentMoves.moveList)

            ;attempt to execute the move. if successful, then add it to the queue
            if (newBoard.move(direction, newMoveList)) {
                boardStateQueue.Push({ board: newBoard, moves: newMoveList, mistakes: newMistakesCount })
            }
        }
    }
    boardObj := currentBestPath.board
    moveList := currentBestPath.moves
    return currentBestPath.mistakes
}

getOppositeDirection(direction) {
    if (direction = UP_DIRECTION) {
        return DOWN_DIRECTION
    }

    if (direction = DOWN_DIRECTION) {
        return UP_DIRECTION
    }

    if (direction = LEFT_DIRECTION) {
        return RIGHT_DIRECTION
    }

    if (direction = RIGHT_DIRECTION) {
        return LEFT_DIRECTION
    }
}

;Takes a 2 board objects and returns true if they are identical board states
compareBoards(board1, board2) {
    for i, aTile in board1 {
        if (!aTile.compareToTile(board2.getTile(, , aTile.num))) {
            return false
        }
    }
    return true
}

;Takes a string and appends all the contents of an array to the end of it
addArrayToStr(myArray, str) {
    for i, v in myArray {
        str .= v "`n"
    }
    return str
}

F6:: {
    testBoard := Board(5, 5,
        [
        10, 21, 03, 11, 05,
        02, 06, 01, 07, 04,
        08, 20, 09, 16, 13,
        18, 17, 14, 24, 12,
        19, 22, 15, 23, 25
        ])
    strBuffer := ""

    testBoardArray := [
        10, 21, 03, 11, 05,
        02, 06, 01, 07, 04,
        08, 20, 09, 16, 13,
        18, 17, 14, 24, 12,
        19, 22, 15, 23, 25
    ]
    solvedBoardArray := createSolvedBoardArray(5, 5)

    ;MsgBox("starting")
    ;solution := testBoard.solveBoard()
    ;addArrayToStr(solution, strBuffer)
    solution := solvePuzzle(testBoardArray, 5)
    addArrayToStr(solution.moves, strBuffer)
    MsgBox(strBuffer)
    MsgBox("yes")
}
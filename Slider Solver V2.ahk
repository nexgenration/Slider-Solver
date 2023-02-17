;#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
;SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global UP_DIRECTION := "UP"
global DOWN_DIRECTION := "DOWN"
global LEFT_DIRECTION := "LEFT"
global RIGHT_DIRECTION := "RIGHT"

global mainBoard := Board(5, 5)
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

Class Board {
    height := 0
    width := 0
    tile := []
    blankTile := 0
    invalidFlag := false

    __New(height, width, boardArray := 0, invalidFlag := false) {
        this.height := height
        this.width := width
        this.invalidFlag := invalidFlag

        row := 1
        while (row <= height) {
            col := 1
            while (col <= width) {
                num := ((row - 1) * width) + col

                if (boardArray) {
                    num := boardArray[num]
                }

                desiredRow := Floor((num - 1) / width) + 1
                desiredCol := Mod(num, width)

                if (!desiredCol) {
                    desiredCol := width
                }

                this.tile.Push(Tile(row, col, num, desiredRow, desiredCol))
                col++
            }
            row++
        }

        if (this.isBoardValid()) {
            this.setBlankTile()
        }
    }

    /**Takes either a tile's coords or the tile number and returns the tile object accordingly.
     * 
     * Returns false if no tile is found
     **/
    getTile(row := 0, col := 0, num := 0) {
        for head in this.tile {
            if (head.num = num) {
                return head
            }

            if (head.row = row && head.col = col) {
                return head
            }
        }
        return false
    }

    ;Takes a tile number and returns its coords
    getTileCoords(num) {
        aTile := this.getTile(, , num)
        if (!aTile) {
            return false
        }

        return aTile.getCoords()
    }

    ;Sets the blankTile variable to a reference of the tile with the highest number (aka the botom-right-most tile)
    setBlankTile() {
        this.blankTile := this.getTile(, , this.height * this.width)
    }

    ;Returns true if tile number is present as well as a tile with each combination of row and col
    isBoardValid() {
        tileNum := 1
        while (tileNum <= this.height * this.width) {
            if (!this.getTile(, , tileNum)) {
                return false
            }
            tileNum++
        }

        row := 1
        while (row <= this.height) {
            col := 1
            while (col <= this.width) {
                if (!this.getTile(row, col)) {
                    return false
                }
                col++
            }
            row++
        }
        return true
    }

    ;Returns true if the board is completely solved
    isBoardSolved() {
        for i, atile in this.tile {
            if (i != atile.num) {
                return false
            }
            return true
        }
    }

    /**Takes a tile object and a direction and returns the tile object for the tile in that direction.
     * 
     * Returns false if neighboring tile is out of bounds.
     * **/
    getTileNeighbor(tile, direction) {
        if (direction = UP_DIRECTION) {
            if (tile.row = 1) {
                return false
            }
            return this.getTile(tile.row - 1, tile.col)
        }

        if (direction = DOWN_DIRECTION) {
            if (tile.row = this.height) {
                return false
            }
            return this.getTile(tile.row + 1, tile.col)
        }

        if (direction = LEFT_DIRECTION) {
            if (tile.col = 1) {
                return false
            }
            return this.getTile(tile.row, tile.col - 1)
        }

        if (direction = RIGHT_DIRECTION) {
            if (tile.col = this.width) {
                return false
            }
            return this.getTile(tile.row, tile.col + 1)
        }
    }

    ;Returns a prepared string that can be used to print the board on the screen or copy it to the clipboard
    buildBoardString() {
        strBuffer := ""
        row := 1
        while (row <= this.height) {

            col := 1
            while (col <= this.width) {

                tempTile := this.getTile(row, col)
                if (tempTile.num < 10) {
                    strBuffer .= 0
                }

                strBuffer .= tempTile.num
                if (col != this.height) {
                    strBuffer .= ", "
                } else {
                    strBuffer .= "`n"
                }
                col++
            }
            row++
        }

        return strBuffer
    }

    ;Prints the board into a messagebox. User can also copy the resulting board to the clipboard
    printBoard() {
        strBuffer := this.buildBoardString()
        strBuffer .= "`n`nCopy board array to clipboard?"
        result := MsgBox(strBuffer, , 4)

        if (result = "Yes") {
            A_Clipboard := this.buildBoardString()
        }
    }

    ;Takes a board object and returns true if it is an identical board state to `this`'s board state
    compareToBoard(otherBoard) {
        for i, aTile in this.tile {
            if (!aTile.compareToTile(otherBoard.getTile(, , aTile.num))) {
                return false
            }
        }
        return true
    }

    ;Returns a deep copy of `this`
    makeCopy() {
        height := this.height
        width := this.width
        boardArray := []
        boardArray.Length := width * height
        
        for head in this.tile{
            boardArray[head.col + ((head.row - 1) * width)] := head.num
        }

        return Board(height, width, boardArray)
    }

    /**Takes a direction and a MoveQueue object and moves the blank tile in the given direction,
     * 
     * moves its neighboir in the opposite direction, and adds the direction to the MoveQueue
     **/
    move(direction, moveList) {
        moveTo := this.getTileNeighbor(this.blankTile, direction)
        if (!moveTo || !moveList.canAddMove(direction)) {
            return false
        }

        moveTo.moveTile(getOppositeDirection(direction))
        this.blankTile.moveTile(direction)
        return moveList.addMove(direction)
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

    getPossibleMoves(lastMove) {
        possibleMoves := []
        blankTileCoords := this.blankTile.getCoords()
        blankTileRow := blankTileCoords[1]
        blankTilecol := blankTileCoords[2]

        if (blankTileRow > 1 && lastMove != DOWN_DIRECTION) {
            possibleMoves.Push(UP_DIRECTION)
        }
        if (blankTileRow < this.height && lastMove != UP_DIRECTION) {
            possibleMoves.Push(DOWN_DIRECTION)
        }
        if (blankTilecol > 1 && lastMove != RIGHT_DIRECTION) {
            possibleMoves.Push(LEFT_DIRECTION)
        }
        if (blankTilecol < this.width && lastMove != LEFT_DIRECTION) {
            possibleMoves.Push(RIGHT_DIRECTION)
        }

        return possibleMoves
    }

    solveBoard() {
        ;make a queue, list of visited board states, and a board string
        boardStateQueue := []
        visitedBoards := {}
        initialBoardString := this.buildBoardString()

        ;add current board state to the queue and list of visited board states
        boardStateQueue.Push({ board: this, moves: MoveQueue() })
        visitedBoards.initialBoardString := true

        ;loop through each board state on a first-in-first-out basis. this ensures the shortest path is always found
        while (boardStateQueue.Length > 0) {

            ;grab the first board state on the queue and remove it from the queue
            currentState := boardStateQueue[1]
            boardStateQueue.RemoveAt(1)
            currentBoard := currentState.board
            currentMoves := currentState.moves

            ;check if the board state that was just grabbed is solved
            if (currentBoard.isBoardSolved()) {
                return currentMoves
            }

            ;itterate through all the tiles that can be moved
            for singleTile in currentBoard.tile {

                ;skip the tile if it is the blank tile
                if (singleTile.num = currentBoard.blankTile.num) {
                    continue
                }

                ;skip the tile if it is in the correct spot
                if (singleTile.isTileSolved()) {
                    continue
                }

                ;iterate through all the possible moves that can be made from the board state that was just grabbed
                for direction in [RIGHT_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, UP_DIRECTION] {
                    neighborTile := currentBoard.getTileNeighbor(singleTile, direction)

                    ;skip the direction if neighboring tile is out of bounds
                    if (!neighborTile) {
                        continue
                    }

                    ;clone both the board and moves list
                    newBoard := currentBoard.makeCopy()
                    newMoveList := MoveQueue(currentMoves.moveList)

                    ;pathfind if blank tile isnt already in the destination.
                    if (neighborTile.num != newBoard.blankTile.num) {
                        pathFind(neighborTile.row, neighborTile.col, &newMoveList, &newBoard, singleTile)
                    }

                    ;move blanktile into singleTile. then check if the resulting board is on the list of visited board states.
                    ;if it isnt, then add it to both that list and the queue
                    newBoard.move(getOppositeDirection(direction), newMoveList)
                    newBoardString := newBoard.buildBoardString()
                    if (!visitedBoards.HasOwnProp(newBoardString)) {
                        visitedBoards.newBoardString := true
                        boardStateQueue.Push({ board: newBoard, moves: newMoveList })
                    }
                }
            }
        }
        return []
    }

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
}

Class Tile {
    row := 0
    col := 0
    num := 0
    desiredRow := 0
    desiredCol := 0

    __New(row, col, num, desiredRow, desiredCol) {
        this.row := row
        this.col := col
        this.num := num
        this.desiredRow := desiredRow
        this.desiredCol := desiredCol
    }

    getCoords() {
        return [this.row, this.col]
    }

    moveTile(direction) {
        if (direction = UP_DIRECTION) {
            this.row--
            return
        }

        if (direction = DOWN_DIRECTION) {
            this.row++
            return
        }

        if (direction = LEFT_DIRECTION) {
            this.col--
            return
        }

        if (direction = RIGHT_DIRECTION) {
            this.col++
            return
        }
    }

    printTile() {
        MsgBox(this.num ": " this.row ", " this.col)
    }

    compareToTile(otherTile) {
        return (this.row = otherTile.row && this.col = otherTile.col && this.num = otherTile.num)
    }

    isTileSolved() {
        if (this.row = this.desiredRow && this.col = this.desiredCol) {
            return true
        }
        return false
    }
}

Class MoveQueue {
    moveList := 0
    undoDirection := 0

    ;If an array of moves is passed in, moveList will be set to a clone of it
    __New(moveList := []) {
        this.moveList := []
        if (moveList.Length > 0) {
            this.moveList := moveList.Clone()
        }
    }

    addMove(direction) {
        if (!this.canAddMove(direction)) {
            return false
        }

        this.moveList.Push(direction)
        this.undoDirection := 0
        return true
    }

    canAddMove(direction) {
        if (direction = RIGHT_DIRECTION) {
            if (this.getLastMove() = LEFT_DIRECTION) {
                return false
            }
        }

        if (direction = DOWN_DIRECTION) {
            if (this.getLastMove() = UP_DIRECTION) {
                return false
            }
        }

        if (direction = LEFT_DIRECTION) {
            if (this.getLastMove() = RIGHT_DIRECTION) {
                return false
            }
        }

        if (direction = UP_DIRECTION) {
            if (this.getLastMove() = DOWN_DIRECTION) {
                return false
            }
        }

        return true
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

/**Moves the blank tile to a destination while avoiding the movement of a single tile.
 * 
 * Tries to always move tiles closer to their destination rather than further away.
 **/
pathFind(pathToRow, pathToCol, &moveList, &boardState, obstacle) {
    ;make a queue, a board string, a progress modifier, and a current best path
    ;set the progress modifier in the best path to a number it should never naturally reach
    boardStateQueue := []
    initialBoardString := boardState.buildBoardString()
    progressMod := 0
    currentBestPath := { board: boardState, moves: moveList, progress: boardState.width * boardState.height * -1 }

    ;add current board state to the queue
    boardStateQueue.Push({ board: boardState, moves: moveList, progress: progressMod })

    ;loop through each board state on a first-in-first-out basis. this ensures the shortest path is always found
    while (boardStateQueue.Length > 0) {

        ;grab the first board state on the queue and remove it from the queue
        currentState := boardStateQueue[1]
        boardStateQueue.RemoveAt(1)
        currentBoard := currentState.board
        currentMoves := currentState.moves
        currentProgressMod := currentState.progress

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

        ;check if the blank tile in the board state that was just grabbed is in the destination slot
        if (inDestRow && inDestCol) {
            if (currentProgressMod > currentBestPath.progress) {
                currentBestPath := { board: currentBoard, moves: currentMoves, progress: currentProgressMod }
            }
            continue
        }

        ;loop through each direction, only attempting to make a move if it makes progress towards the destination
        for direction in [UP_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, RIGHT_DIRECTION] {
            neighbor := currentBoard.getTileNeighbor(currentBoard.blankTile, direction)
            newProgressMod := currentProgressMod

            ;make sure it isnt moving the obstacle tile and check that the direction is valid
            if (!neighbor || neighbor.num = obstacle.num) {
                continue
            }

            if (direction = UP_DIRECTION) {

                ;make sure it isnt above the destination
                if (upFromDest) {
                    continue
                }

                ;make sure it isnt in the correct row and the correct side of the obstacle
                if (inDestRow && ((rightFromDest && rightFromObstacle) || (leftFromDest && leftFromObstacle))) {
                    continue
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.row = pathToRow + 1 &&
                    ((leftFromDest && obstacle.col < pathToCol) ||
                        (rightFromDest && obstacle.col > pathToCol))) {
                    continue
                }

                if (neighbor.row < neighbor.desiredRow) {
                    newProgressMod++
                } else {
                    newProgressMod--
                }
            } else if (direction = DOWN_DIRECTION) {

                ;make sure it isnt below the destination
                if (downFromDest) {
                    continue
                }

                ;make sure it isnt in the correct row and the correct side of the obstacle
                if (inDestRow && ((rightFromDest && rightFromObstacle) || (leftFromDest && leftFromObstacle))) {
                    continue
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.row = pathToRow - 1 &&
                    ((leftFromDest && obstacle.col < pathToCol) ||
                        (rightFromDest && obstacle.col > pathToCol))) {
                    continue
                }

                if (neighbor.row > neighbor.desiredRow) {
                    newProgressMod++
                } else {
                    newProgressMod--
                }
            } else if (direction = LEFT_DIRECTION) {

                ;make sure it isnt left of the destination
                if (leftFromDest) {
                    continue
                }

                ;make sure it isnt in the correct col and the correct vertical side of the obstacle
                if (inDestCol && ((upFromDest && upFromObstacle) || (downFromDest && downFromObstacle))) {
                    continue
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.col = pathToCol + 1 &&
                    ((upFromDest && obstacle.row < pathToRow) ||
                        (downFromDest && obstacle.row > pathToRow))) {
                    continue
                }

                if (neighbor.col < neighbor.desiredCol) {
                    newProgressMod++
                } else {
                    newProgressMod--
                }
            } else if (direction = RIGHT_DIRECTION) {

                ;make sure it isnt left of the destination
                if (rightFromDest) {
                    continue
                }

                ;make sure it isnt in the correct col and the correct vertical side of the obstacle
                if (inDestCol && ((upFromDest && upFromObstacle) || (downFromDest && downFromObstacle))) {
                    continue
                }

                ;make sure it doesnt try to move behind the obstacle tile
                if (currentBoard.blankTile.col = pathToCol - 1 &&
                    ((upFromDest && obstacle.row < pathToRow) ||
                        (downFromDest && obstacle.row > pathToRow))) {
                    continue
                }

                if (neighbor.col > neighbor.desiredCol) {
                    newProgressMod++
                } else {
                    newProgressMod--
                }
            }

            ;clone both the board and moves list
            newBoard := currentBoard.makeCopy()
            newMoveList := MoveQueue(currentMoves.moveList)

            ;attempt to execute the move. if successful, then add it to the queue
            if (newBoard.move(direction, newMoveList)) {
                boardStateQueue.Push({ board: newBoard, moves: newMoveList, progress: newProgressMod })
            }
        }
    }
    boardState := currentBestPath.board
    moveList := currentBestPath.moves
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

;Takes a string and appends all the contents of an array to the end of it
addArrayToStr(myArray, str) {
    for i, v in myArray {
        str .= v "`n"
    }
    return str
}

findTileFromImg(tileName, tileX, tileY, &foundX, &foundY) {
    filePath := "PuzzleImages\" tileName "\" tileName tileX "-" tileY ".png"
    if (!ImageSearch(&foundX, &foundY, searchX1, searchY1, searchX2, searchY2, filePath)) {
        return false
    }
    return true
}

getBoardFromScreen(puzzleName) {
    imgLocationX := 0
    imgLocationY := 0
    strBuffer := ""
    board := [
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25]]
    tileScreenLocationX := [
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25]]
    tileScreenLocationY := [
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25],
        [25, 25, 25, 25, 25]]

    for i, v in board {
        for j, w in v {
            if (i = 5 && j = 5) {
                Break
            }

            if (!findTileFromImg(puzzleName, i, j, &imgLocationX, &imgLocationY)) {
                ; if (Error = "Could not open file") {
                ;     MsgBox("Could not open file " puzzleName i "-" j ".png")
                ; }
                return INVALID_BOARD
            }

            ;imgLocation is the actual screen coords the ingame tile was found at
            ;tileScreenLocation is an array of those values linking both coords to the same slot in said array
            tileScreenLocationX[i][j] := imgLocationX
            tileScreenLocationY[i][j] := imgLocationY
        }
    }

    builtBoard := screenCoordsToBoard(tileScreenLocationX, tileScreenLocationY)

    if (!builtBoard.isBoardValid) {
        MsgBox("The " puzzleName " board was found but not validated.")
        builtBoard.printBoard()
        return false
    }
    return builtBoard
}

screenCoordsToBoard(imgLocationsX, imgLocationsY) {
    uniqueX := countUniques(imgLocationsX)
    uniqueY := countUniques(imgLocationsY)
    sortUniques(uniqueX)
    sortUniques(uniqueY)
    resultBoard := Board(5, 5)

    ;go through each tile
    imgSlotRow := 1
    while (imgSlotRow < 6) {
        imgSlotCol := 1
        while (imgSlotCol < 6) {

            ;if 5,5 skip because its blankTile and doesnt have an image
            if (imgSlotRow = 5 && imgSlotCol = 5) {
                Break
            }

            ;start boardCol at 1, then increase it until the unique with the index of boardCol matches the imgLocation value
            boardCol := 1
            while (imgLocationsX[imgSlotRow][imgSlotCol] != uniqueX[boardCol]) {
                boardCol++
            }

            ;same thing for boardTileY
            boardRow := 1
            while (imgLocationsY[imgSlotRow][imgSlotCol] != uniqueY[boardRow]) {
                boardRow++
            }

            imgNum := ((imgSlotRow - 1) * 5) + imgSlotCol
            resultBoard.getTile(boardRow, boardCol).num := imgNum
            imgSlotCol++
        }
        imgSlotRow++
    }

    return resultBoard
}

countUniques(myArray) {
    uniqueList := []
    for i, v in myArray {
        for j, w in v {
            found := false
            for k, z in uniqueList {
                if (w = z) {
                    found := true
                    Break
                }
            }
            if (!found && w != 25) {
                uniqueList.Push(w)
            }
        }
    }
    return uniqueList
}

sortUniques(uniques) {
    for i, v in uniques {
        head := i
        while (head > 1 && v < uniques[head - 1]) {
            uniques[head] := uniques[head - 1]
            uniques[head - 1] := v
            head--
        }
    }
}

addUniquesToStr(uX, uY, str) {
    str .= "X Uniques:`n"
    addArrayToStr(uX, str)
    str .= "Y Uniques:`n"
    addArrayToStr(uY, str)
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

    testMoves := MoveQueue()
    pathFind(3, 3, &testMoves, &testBoard, testBoard.getTile(4, 3))
    strBuffer := ""
    addArrayToStr(testMoves.moveList, strBuffer)
    MsgBox(strBuffer)


    ;solve5x5()
    testBoard2 := testBoard.Clone()
    testBoard.printBoard()

    MsgBox("starting")
    addArrayToStr(testBoard.solveBoard().moveList, strBuffer)
    MsgBox(strBuffer)
    if (testBoard.solveBoard()) {
        MsgBox("yes")
    } else {
        MsgBox("no")
    }
}
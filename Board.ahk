#Requires AutoHotkey v2.0-beta


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

    ;Returns true if all tiles are present somewhere on the board. Does not check if board is solved
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
        }
        return true
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

    ;Returns a deep copy of `this`
    makeCopy() {
        height := this.height
        width := this.width
        boardArray := []
        boardArray.Length := width * height

        for head in this.tile {
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
        if (!moveTo) {
            return false
        }

        moveTo.moveTile(getOppositeDirection(direction))
        this.blankTile.moveTile(direction)
        moveList.addMove(direction)
        return true
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

    getBoardManhattan() {
        total := 0
        for aTile in this.tile {
            total += Abs(aTile.row - aTile.desiredRow) + Abs(aTile.col - aTile.desiredCol)
        }
        return total
    }

    isTileMovable(aTile, direction := 0) {
        if (direction = 0) {
            if(aTile.desiredRow = 1 || aTile.desiredCol = 1){
                return true
            }

            if(this.isTileMovable(this.getTile(,,aTile.num - this.width), UP_DIRECTION)){
                return true
            }

            if(this.isTileMovable(this.getTile(,,aTile.num - 1), LEFT_DIRECTION)){
                return true
            }
        }

        if (!aTile.isTileSolved()) {
            return false
        }

        if (aTile.desiredRow = 1 || aTile.desiredCol = 1) {
            return true
        }

        if (direction = UP_DIRECTION) {
            return this.isTileMovable(this.getTileNeighbor(aTile, direction), UP_DIRECTION)
        }

        if (direction = LEFT_DIRECTION) {
            return this.isTileMovable(this.getTileNeighbor(aTile, direction), LEFT_DIRECTION)
        }
    }

    getHighestUnsolvedRow(){
        row := 1
        col := 1
        while (true){
            if(!this.getTile(row, col).isTileSolved()){
                row--
                break
            }
            col++

            if(col = this.width + 1){
                col := 1
                row++
            }
        }
        return row
    }

    getLeftmostUnsolvedCol(){
        row := 1
        col := 1
        while (true){
            if(!this.getTile(row, col).isTileSolved()){
                col--
                break
            }
            row++

            if(row = this.height + 1){
                row := 1
                col++
            }
        }
        return col
    }

    solveBoard() {
        ;make a queue, list of visited board states, and a board string
        boardStateQueue := []

        ;add current board state to the queue and list of visited board states
        boardStateQueue.Push({ board: this, moves: MoveQueue(), score: this.getBoardManhattan() })

        ;loop through each board state on a first-in-first-out basis. this ensures the shortest path is always found
        while (boardStateQueue.Length > 0) {

            ;grab the first board state on the queue and remove it from the queue
            currentState := boardStateQueue[1]
            boardStateQueue.RemoveAt(1)
            currentBoard := currentState.board
            currentMoves := currentState.moves
            currentScore := currentState.score

            ;check if the board state that was just grabbed is solved
            if (currentBoard.isBoardSolved()) {
                return currentMoves
            }

            for aTile in currentBoard.tile {

                if(!currentBoard.isTileMovable(aTile)){
                    continue
                }

                if(aTile.isTileSolved()){
                    if(aTile.row = currentBoard.getHighestUnsolvedRow()){
                        belowATile := currentBoard.getTileNeighbor(aTile, DOWN_DIRECTION)
                        if(aTile.compareToTile(currentBoard.getTile(,,aTile.num + currentBoard.width)))
                        snakeDiagLeft := currentBoard.getTileNeighbor(currentBoard.getTileNeighbor(aTile, LEFT_DIRECTION), DOWN_DIRECTION)
                        if(snakeDiagLeft){
                            snakeTargetLeft := currentBoard.getTileNeighbor(snakeDiagLeft, LEFT_DIRECTION)
                            snakeTargetDown := currentBoard.getTileNeighbor(snakeDiagLeft, DOWN_DIRECTION)
                        }
                    }

                    if(aTile.col = currentBoard.getLeftmostUnsolvedCol()){

                    }
                }

                for direction in [RIGHT_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, UP_DIRECTION] {

                    ;skip direction if it moves the tile away from its destination
                    if(isMoveAMistake(aTile, getOppositeDirection(direction))){
                        continue
                    }
                    
                    neighborTile := currentBoard.getTileNeighbor(aTile, direction)
                    skipPathFinding := false

                    ;skip the direction if neighboring tile is out of bounds
                    if (!neighborTile) {
                        continue
                    }

                    ;if blank tile is the neighbor in question
                    if (currentBoard.blankTile.compareToTile(neighborTile)) {
                        ;skip the direction if direction is the oposite of the last move's direction
                        if (direction = currentMoves.getLastMove()) {
                            continue
                        }

                        skipPathFinding := true
                    }

                    ;clone the elements of the current boardstate
                    newBoard := currentBoard.makeCopy()
                    newMoveList := MoveQueue(currentMoves.moveList)
                    newScore := currentScore

                    ;if not being skipped, pathfind next to tile
                    if (!skipPathFinding) {
                        pathFind(neighborTile.row, neighborTile.col, &newMoveList, &newBoard, aTile)
                    }
                    
                    ;make move
                    newBoard.move(getOppositeDirection(direction), newMoveList)
                    inserted := false
                    newScore := newBoard.getBoardManhattan() + newMoveList.getMoveCount()

                    if (newMoveList.getMoveCount() >= 200) {
                        continue
                    }

                    ;insert board state into queue at index dependant on how many mistakes were made
                    for index, boardState in boardStateQueue {
                        if (boardState.score >= newScore) {
                            ;if (boardState.moves.getMoveCount() <= newMoveList.getMoveCount()) {
                                boardStateQueue.InsertAt(index, { board: newBoard, moves: newMoveList, score: newScore })
                                inserted := true
                                break
                            ;}
                        }
                    }

                    if (!inserted) {
                        boardStateQueue.Push({ board: newBoard, moves: newMoveList, score: newScore })
                    }
                }
            }
        }
        return []
    }
}
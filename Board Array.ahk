#Requires AutoHotkey v2.0-beta

createSolvedBoardArray(width, height) {
    numOfTiles := width * height
    boardArray := []
    while (boardArray.Length < numOfTiles) {
        boardArray.Push(boardArray.Length + 1)
    }
    return boardArray
}

createBoardArray(boardString := "") {
    return StrSplit(boardString, ",")
}

createBoardString(boardArray) {
    strBuffer := ""
    for i, tile in boardArray {
        strBuffer .= tile
        if (i = boardArray.Length) {
            return strBuffer
        }
        strBuffer .= ","
    }
}

printBoard(boardArray, width, extraMsg := "") {
    strBuffer := ""
    height := boardArray.Length / width
    index := 1
    row := 1
    while (row <= height) {

        col := 1
        while (col <= width) {

            tempTile := boardArray[index]
            if (tempTile < 10) {
                strBuffer .= 0
            }

            if(tempTile = boardArray.Length){
                strBuffer .= "00"
            }else{
                strBuffer .= tempTile
            }

            if (col != width) {
                strBuffer .= ", "
            } else {
                strBuffer .= "`n"
            }

            index++
            col++
        }
        row++
    }
    strBuffer .= "`n" extraMsg

    result := MsgBox(strBuffer "`n`nCopy board array to clipboard?", , 4)

    if (result = "Yes") {
        A_Clipboard := strBuffer
    }
}

isBoardArraySolved(boardArray) {
    for i, tile in boardArray {
        if (tile != i) {
            return false
        }
    }
    return true
}

isIndexOutOfBounds(boardLength, tileIndex){
    if(tileIndex > 0 && tileIndex <= boardLength){
        return false
    }
    return true
}

isMoveDesired(width, tileNum, tileIndex, direction){
    tileCoords := getTileCoords(tileIndex, width)
    tileRow := tileCoords[1]
    tileCol := tileCoords[2]
    destinationCoords := getTileCoords(tileNum, width)
    destinationRow := destinationCoords[1]
    destinationCol := destinationCoords[2]
    
    if(direction = UP_DIRECTION && tileRow > destinationRow){
        return true
    }
    if(direction = DOWN_DIRECTION && tileRow < destinationRow){
        return true
    }
    if(direction = LEFT_DIRECTION && tileCol > destinationCol){
        return true
    }
    if(direction = RIGHT_DIRECTION && tileCol < destinationCol){
        return true
    }
    return false
}

getTileIndex(boardArray, tileNum) {
    for i, tile in boardArray {
        if (tile = tileNum) {
            return i
        }
    }
    return false
}

getTileCoords(tileIndex, width) {
    row := Ceil(tileIndex / width)
    col := Mod(tileIndex, width)

    if (col = 0) {
        col := width
    }

    return [row, col]
}

getAdjacentTileIndex(width, boardSize, sourceTileIndex, direction){
    sourceTileCoords := getTileCoords(sourceTileIndex, width)
    height := boardSize / width
    if (direction = UP_DIRECTION && sourceTileCoords[1] > 1) {
        return sourceTileIndex - width
    }
    if (direction = DOWN_DIRECTION && sourceTileCoords[1] < height) {
        return sourceTileIndex + width
    }
    if (direction = LEFT_DIRECTION && sourceTileCoords[2] > 1) {
        return sourceTileIndex - 1
    }
    if (direction = RIGHT_DIRECTION && sourceTileCoords[2] < width) {
        return sourceTileIndex + 1
    }
    return false
}

clonePath(path){
    return path.Clone()
}

isRowSolved(boardArray, width, row) {
    slot := 1 + ((row - 1) * width)
    while (slot <= width * row) {
        if (slot != boardArray[slot]) {
            return false
        }
        slot++
    }
    return true
}

getLowestSolvedRow(boardArray, width) {
    row := 1
    while (isRowSolved(boardArray, width, row)) {
        row++
    }
    return row - 1
}

isColSolved(boardArray, width, col) {
    slot := col
    while (slot <= boardArray.Length) {
        if (slot != boardArray[slot]) {
            return false
        }
        slot := slot + width
    }
}

getRightMostSolvedCol(boardArray, width) {
    col := 1
    while (isColSolved(boardArray, width, col)) {
        col++
    }
    return col - 1
}

getPossibleMoves(boardArray, width, lastMove, tileToAvoid := 0, isTileBlank := true) {
    possibleMoves := []
    height := boardArray.Length / width

    if (isTileBlank) {
        scanningTileIndex := getTileIndex(boardArray, boardArray.Length)
    } else {
        scanningTileIndex := getTileIndex(boardArray, tileToAvoid)
    }

    scanningTileCoords := getTileCoords(scanningTileIndex, width)
    scanningTileRow := scanningTileCoords[1]
    scanningTileCol := scanningTileCoords[2]
    lowestSolvedRow := getLowestSolvedRow(boardArray, width)
    rightMostSolvedCol := getRightMostSolvedCol(boardArray, width)

    if (scanningTileRow > 1
        && lastMove != DOWN_DIRECTION
        && scanningTileIndex - width != tileToAvoid
        && scanningTileRow > lowestSolvedRow + 1
    ) {
        possibleMoves.Push(UP_DIRECTION)
    }

    if (scanningTileRow < height
        && lastMove != UP_DIRECTION
        && scanningTileIndex + width != tileToAvoid
    ) {
        possibleMoves.Push(DOWN_DIRECTION)
    }

    if (scanningTileCol > 1
        && lastMove != RIGHT_DIRECTION
        && scanningTileIndex - 1 != tileToAvoid
        && scanningTileCol > rightMostSolvedCol + 1
    ) {
        possibleMoves.Push(LEFT_DIRECTION)
    }

    if (scanningTileCol < width
        && lastMove != LEFT_DIRECTION
        && scanningTileIndex + 1 != tileToAvoid
    ) {
        possibleMoves.Push(RIGHT_DIRECTION)
    }

    return possibleMoves
}

getBoardManhattan(boardArray, width) {
    total := 0
    for currentIndex, desiredIndex in boardArray {
        total += getSingleTileManhattan(width, currentIndex, desiredIndex)
    }
    return total
}

getOuterManhattan(boardArray, width) {
    total := 0
    tileLocations := []
    for currentIndex, desiredIndex in boardArray {
        if (!(desiredIndex <= width || Mod(desiredIndex, width) = 1)) {
            continue
        }

        if (currentIndex != desiredIndex) {
            tileLocations.Push(currentIndex)
        }

        total += getSingleTileManhattan(width, currentIndex, desiredIndex)
    }
    return [total, tileLocations]
}

;returns: [outerTileBeingMoved, destination, directionOuterTileIsMovingIn]
getShortTermGoals(boardArray, width, outerManhattanTileIndexes){
    shortTermGoals := []
    for i, outerTileIndex in outerManhattanTileIndexes{
        for j, direction in [UP_DIRECTION, DOWN_DIRECTION, LEFT_DIRECTION, RIGHT_DIRECTION]{
            adjacentTileIndex := getAdjacentTileIndex(width, boardArray.Length, outerTileIndex, direction)
            if (!adjacentTileIndex){
                continue
            }

            if(isMoveDesired(width, boardArray[outerTileIndex], outerTileIndex, direction)){
                shortTermGoals.Push([outerTileIndex, adjacentTileIndex, direction])
            }
        }
    }
    return shortTermGoals
}

getSingleTileManhattan(width, currentIndex, desiredIndex){
    currentCoords := getTileCoords(currentIndex, width)
    desiredCoords := getTileCoords(desiredIndex, width)
    return Abs(currentCoords[1] - desiredCoords[1]) + Abs(currentCoords[2] - desiredCoords[2])
}

applyMove(boardArray, width, direction) {
    blankTileIndex := getTileIndex(boardArray, boardArray.Length)
    blankTileCoords := getTileCoords(blankTileIndex, width)
    blankTileRow := blankTileCoords[1]
    blankTileCol := blankTileCoords[2]
    movingTileNum := 0
    movingTileIndex := 0

    if (direction = UP_DIRECTION) {
        destinationTileNum := boardArray[blankTileIndex - width]
        if (destinationTileNum <= width && !(blankTileRow > 2)) {
            return false
        }
        movingTileIndex := blankTileIndex - width
    }
    if (direction = DOWN_DIRECTION) {
        movingTileIndex := blankTileIndex + width
    }
    if (direction = LEFT_DIRECTION) {
        destinationTileNum := boardArray[blankTileIndex - 1]
        if (Mod(destinationTileNum, width) = 1 && !(blankTileCol > 2)) {
            return false
        }
        movingTileIndex := blankTileIndex - 1
    }
    if (direction = RIGHT_DIRECTION) {
        movingTileIndex := blankTileIndex + 1
    }

    boardArray[blankTileIndex] := boardArray[movingTileIndex]
    boardArray[movingTileIndex] := boardArray.Length
    return true
}
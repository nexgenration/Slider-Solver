#Requires AutoHotkey v2.0-beta

createSolvedBoardArray(width, height){
    numOfTiles := width * height
    boardArray := []
    while(boardArray.Length < numOfTiles){
        boardArray.Push(boardArray.Length + 1)
    }
    return boardArray
}

createBoardArray(boardString := ""){
    return StrSplit(boardString, ",")
}

createBoardString(boardArray){
    strBuffer := ""
    for i, tile in boardArray{
        strBuffer .= tile
        if(i = boardArray.Length){
            return strBuffer
        }
        strBuffer .= ","
    }
}

printBoard(boardArray, width) {
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

            strBuffer .= tempTile
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
    
    result := MsgBox(strBuffer "`n`nCopy board array to clipboard?", , 4)

    if (result = "Yes") {
        A_Clipboard := strBuffer
    }
}

isBoardArraySolved(boardArray){
    for i, tile in boardArray{
        if(tile != i){
            return false
        }
    }
    return true
}

getTileIndex(boardArray, tileNum){
    for i, tile in boardArray{
        if(tile = tileNum){
            return i
        }
    }
    return false
}

getTileCoords(tileIndex, width){
    row := Ceil(tileIndex / width)
    col := Mod(tileIndex, width)
    
    if(col = 0){
        col := width
    }

    return [row, col]
}

getPossibleMoves(boardArray, width, height, lastMove) {
    possibleMoves := []
    blankTileIndex := getTileIndex(boardArray, width * height)
    blankTileCoords := getTileCoords(blankTileIndex, width)
    blankTileRow := blankTileCoords[1]
    blankTileCol := blankTileCoords[2]

    if (blankTileRow > 1 && lastMove != DOWN_DIRECTION) {
        possibleMoves.Push(UP_DIRECTION)
    }
    if (blankTileRow < height && lastMove != UP_DIRECTION) {
        possibleMoves.Push(DOWN_DIRECTION)
    }
    if (blankTileCol > 1 && lastMove != RIGHT_DIRECTION) {
        possibleMoves.Push(LEFT_DIRECTION)
    }
    if (blankTileCol < width && lastMove != LEFT_DIRECTION) {
        possibleMoves.Push(RIGHT_DIRECTION)
    }

    return possibleMoves
}

getBoardManhattan(boardArray, width) {
    total := 0
    for currentIndex, desiredIndex in boardArray {
        currentCoords := getTileCoords(currentIndex, width)
        desiredCoords := getTileCoords(desiredIndex, width)
        total += Abs(currentCoords[1] - desiredCoords[1]) + Abs(currentCoords[2] - desiredCoords[2])
    }
    return total
}

applyMove(boardArray, width, direction){
    blankTileIndex := getTileIndex(boardArray, boardArray.Length)
    movingTileNum := 0
    movingTileIndex := 0

    if(direction = UP_DIRECTION){
        movingTileIndex := blankTileIndex - width
    }
    if(direction = DOWN_DIRECTION){
        movingTileIndex := blankTileIndex + width
    }
    if(direction = LEFT_DIRECTION){
        movingTileIndex := blankTileIndex - 1
    }
    if(direction = RIGHT_DIRECTION){
        movingTileIndex := blankTileIndex + 1
    }

    boardArray[blankTileIndex] := boardArray[movingTileIndex]
    boardArray[movingTileIndex] := boardArray.Length
}
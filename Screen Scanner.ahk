#Requires AutoHotkey v2.0-beta


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
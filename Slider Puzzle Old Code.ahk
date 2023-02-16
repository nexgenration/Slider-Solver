
buildRow(row, ByRef obstacles){
	blankTile := findBoardTile(25)
	startingPoint := ((row - 1) * 5) + 1
	currentTileNum := startingPoint + 3
	currentTile := findBoardTile(currentTileNum)
	obstacles.Push(currentTileNum)
	
	;figure out if row is already solved
	alreadySolved := true
	alreadySolvedTile := 1
	while(alreadySolvedTile < 6){
		if(board[row][alreadySolvedTile] != ((row - 1) * 5) + alreadySolvedTile){
			alreadySolved := false
			Break
		}
		alreadySolvedTile++
	}
	if(alreadySolved){
		return
	}
	
	;if the 4th tile isnt already in the 5th slot, move it there
	if(!compareTile(currentTile, [row, 5])){
		shoveTileUp(currentTileNum, obstacles)
		shoveTileRight(currentTileNum, obstacles)
	}
	
	;put 3rd tile to the left of the 4th
	currentTileNum--
	currentTile := findBoardTile(currentTileNum)
	obstacles.Push(currentTileNum)
	if(!compareTile(currentTile, [row,4])){
		if(currentTile[2] = 5){
			pathFind(getTileToLeft(currentTile), obstacles)
			moveRight([])
			currentTile := findBoardTile(currentTileNum)
		}
		shoveTileUp(currentTileNum, obstacles)
		shoveTileRight(currentTileNum, obstacles)
	}
	
	;put 2nd tile to the left of the 3rd
	currentTileNum--
	currentTile := findBoardTile(currentTileNum)
	obstacles.Push(currentTileNum)
	if(!compareTile(currentTile, [row,3])){
		while(currentTile[2] > 3){
			pathFind(getTileToLeft(currentTile), obstacles)
			moveRight([])
			currentTile := findBoardTile(currentTileNum)
		}
		shoveTileUp(currentTileNum, obstacles)
		shoveTileRight(currentTileNum, obstacles)
	}
	
	;if solving for row 3 and the 11 tile is in column 4 or 5, shove it all the way to the left 
	;so it never gets stuck under tile 15 when it is put into place
	if(row = 3 && findBoardTile(startingPoint)[2] > 3){
		shoveTileLeft(startingPoint, obstacles.Clone().Push(startingPoint))
	}
	
	;set new currentTileNum
	currentTileNum := startingPoint + 4
	currentTile := findBoardTile(currentTileNum)
	obstacles.Push(currentTileNum)
	
	;if currentTile isn't already in column 5 of the row below
	if(!compareTile(currentTile, [row + 1, 5])){
		
		;if currentTile is in the current row, move it down by 1 since it is being moved into the row below
		if(currentTile[1] = row){
			pathFind(getTileToDown(currentTile), obstacles)
			moveUp([])
			currentTile := findBoardTile(currentTileNum)
		}else{
			shoveTileUp(currentTileNum, obstacles)
		}
		shoveTileRight(currentTileNum, obstacles)
	}
	
	currentTileNum := startingPoint
	currentTile := findBoardTile(currentTileNum)
	obstacles.Push(currentTileNum)
	if(!compareTile(currentTile, [row,2])){
		while(currentTile[2] > 2){
			pathFind(getTileToLeft(currentTile), obstacles)
			moveRight([])
			currentTile := findBoardTile(currentTileNum)
		}
		shoveTileUp(currentTileNum, obstacles)
	}
	
	currentTile := findBoardTile(currentTileNum)
	if(currentTile[2] = 1){
		pathFind(getTileToRight(currentTile), obstacles)
	}else{
		pathFind(getTileToLeft(currentTile), obstacles)
	}
	
	
	moveRight([])
	moveRight([])
	moveRight([])
	moveRight([])
	moveDown([])
}


screenToBoardDebugMode(imgLocationsX, imgLocationsY){
	uniqueX := countUniques(imgLocationsX)
	uniqueY := countUniques(imgLocationsY)
	sortUniques(uniqueX)
	sortUniques(uniqueY)
	
	imgTileX := 1
	while(imgTileX < 6){
		imgTileY := 1
		while(imgTileY < 6){
			if(imgTileX = 5 && imgTileY = 5){
				Break
			}
;MsgBox % imgTileX ", " imgTileY
			boardTileX := 1
			while(imgLocationsX[imgTileX][imgTileY] != uniqueX[boardTileX]){
				strBuffer := "X uniques:`n"
				addArrayToStr(uniqueX, strBuffer)
				strBuffer .= "searching for X unique for " imgTileX "," imgTileY "`n"
				strBuffer .= "imgLocationsX = "imgLocationsX[imgTileX][imgTileY] "`n"
				strBuffer .= "checking against: " uniqueX[boardTileX] "`n"
				strBuffer .= "boardTileX = " boardTileX
				MsgBox % strBuffer
				
				boardTileX++
			}
			
			strBuffer := "X uniques:`n"
			addArrayToStr(uniqueX, strBuffer)
			strBuffer .= "found for X unique for " imgTileX "," imgTileY "`n"
			strBuffer .= "imgLocationsX = "imgLocationsX[imgTileX][imgTileY] "`n"
			strBuffer .= "matching unique: " uniqueX[boardTileX] "`n"
			strBuffer .= "boardTileX = " boardTileX
			MsgBox % strBuffer
			
			
			boardTileY := 1
			while(imgLocationsY[imgTileX][imgTileY] != uniqueY[boardTileY]){
				strBuffer := "Y uniques:`n"
				addArrayToStr(uniqueY, strBuffer)
				strBuffer .= "searching for Y unique for " imgTileX "," imgTileY "`n"
				strBuffer .= "imgLocationsY = "imgLocationsY[imgTileX][imgTileY] "`n"
				strBuffer .= "checking against: " uniqueY[boardTileY] "`n"
				strBuffer .= "boardTileY = " boardTileY
				MsgBox % strBuffer
				boardTileY++
			}
			
			strBuffer := "Y uniques:`n"
			addArrayToStr(uniqueY, strBuffer)
			strBuffer .= "found for Y unique for " imgTileX "," imgTileY "`n"
			strBuffer .= "imgLocationsY = "imgLocationsY[imgTileX][imgTileY] "`n"
			strBuffer .= "matching unique: " uniqueY[boardTileY] "`n"
			strBuffer .= "boardTileY = " boardTileY
			MsgBox % strBuffer
			
			MsgBox % "board location: " boardTileX "," boardTileY "`nnumber being placed: " (((imgTileX - 1) * 5) + imgTileY)
			
			board[boardTileY][boardTileX] := ((imgTileX - 1) * 5) + imgTileY
			printBoard()
			imgTileY++
		}
		imgTileX++
	}
}




		;if both tiles are in the two spaces below slot 4
if(compareTileToMultipleOR([row + 1, 4], [fourthTile, fithTile]) && compareTileToMultipleOR([row + 2, 4], [fourthTile, fithTile])){
	
			;if blankTile is left of col 4, pathFind below both tiles so blankTile doesnt get stuck
	if(blankTile[2] < 4){
		pathFind([row + 3, 4], obstacles)
	}
	
	pathFind([row, 4], obstacles)
	moveDown([])
	continue
}
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetDefaultMouseSpeed, 0
SetTitleMatchMode, 3



global board := [[1,2,3,4,5]
            ,[6,7,8,9,10]
            ,[11,12,13,14,15]
            ,[16,17,18,19,20]
            ,[21,22,23,24,25]]

global blankTile := findBoardTile(25)
global moveQueue := []

global searchX1 := 800
global searchX2 := 1111
global searchY1 := 300
global searchY2 := 620

global debugFlag := false
global faltyBoardFound := false

testSolver(){
	board := [[18, 20, 01, 14, 03]
            ,[05, 04, 08, 02, 24]
            ,[21, 06, 10, 13, 09]
            ,[17, 19, 07, 12, 16]
            ,[15, 11, 22, 23, 25]]
	moveQueue := []
	strBuffer := ""
	obstacles := []
	blankTile := findBoardTile(25)
	boardFound := false
	
	printBoard()
	solveRow(1, obstacles)
	printBoard()
	solveRow(2, obstacles)
	printBoard()
	solveRow(3, obstacles)
	printBoard()
	solveBottom(obstacles)
	printBoard()
	spin()
	printBoard()
	cleanMoveQueue()
	
	MsgBox % "Moves: " moveQueue.Length()
	addArrayToStr(moveQueue, strBuffer)
	MsgBox % strBuffer
}

solve5x5(){
	moveQueue := []
	strBuffer := ""
	obstacles := []
	boardFound := false
	
	possibleBoards := ["Archers", "Bloodveld", "Castle", "Citadel", "Duck", "Elves", "Greg", "Helwyr", "Nomad", "Nymora", "Pharaoh"
				, "Rax", "Strykewyrm", "swordOfEdicts", "Traveler", "Tree", "Troll", "Tuska", "V", "Vyre", "Werewolf", "Wizard", "Wyvern"]
	for i, v in possibleBoards{
		boardFound := getBoardState(possibleBoards[i])
		if(ErrorLevel = 0 && boardFound){
			strBuffer .= v " board found and successfully mapped"
			blankTile := findBoardTile(25)
			Break
		}
	}
	
	if(ErrorLevel = 1){
		strBuffer := "No valid board found.`nBoards checked:`n"
		addArrayToStr(possibleBoards, strBuffer)
		MsgBox % strBuffer
		return
	}
	
	if(boardFound){
		if(faltyBoardFound){
			printBoard()
		}
		
		solveRow(1, obstacles)
		solveRow(2, obstacles)
		solveRow(3, obstacles)
		solveBottom(obstacles)
		spin()
		cleanMoveQueue()
		
		if(isBoardSolved()){
			strBuffer .= "`nBoard solved in " moveQueue.Length() " moves"
		}else{
			strBuffer .= "`nBoard was not solved correctly!!!!"
		}
		ToolTip, % strBuffer
		Sleep 3000
		ToolTip, % ""
	}
}

executeMove(){
	if(moveQueue[1] = "Up"){
		Send {Up}
	}
	if(moveQueue[1] = "Down"){
		Send {Down}
	}
	if(moveQueue[1] = "Left"){
		Send {Left}
	}
	if(moveQueue[1] = "Right"){
		Send {Right}
	}
	moveQueue.RemoveAt(1)
}

solveRow(row, ByRef obstacles){
	;if row is already solved, add all tiles in row to list of obstacles
	if(isRowSolved(row)){
		Loop, 5{
			obstacles.Push(currentTileNum)
			currentTileNum++
		}
		return
	}
	
	blankTile := findBoardTile(25)
	startingPoint := ((row - 1) * 5) + 1
	currentTileNum := startingPoint
	
	;put the first 3 tiles where they belong
	Loop, 3{
		currentTile := findBoardTile(currentTileNum)
		obstacles.Push(currentTileNum)
		col := Mod(currentTileNum, 5)
		shoveTileToPos(currentTileNum, [row,col], obstacles)
		currentTileNum++
	}
	
	fourthTileNum := currentTileNum
	fithTileNum := currentTileNum + 1
	fourthTile := findBoardTile(fourthTileNum)
	fithTile := findBoardTile(fithTileNum)
	obstacles.Push(fourthTileNum)
	obstacles.Push(fithTileNum)
	
	;the folowing if statements are set up so each if statement will set up the board so that either the row is solved or a future if statement will then be triggered
	
	;while fourthTile and fithTile are not in the correct spot
	while(!isRowSolved(row)){
		fourthTile := findBoardTile(fourthTileNum)
		fithTile := findBoardTile(fithTileNum)
		
		;if the tiles are below slot 4 and in slot 5
		if(compareTilesToSlots([[row + 1, 4], [row,5]], [fourthTile, fithTile])){
			
			;if blankTile is stuck in [row,4], move either down if blankTile is above fourthTile or right otherwise
			if(compareTile([row,4], blankTile)){
				if(compareTile(getTileToDown(blankTile), fourthTile)){
					moveDown([])
					return
				}
				moveRight([])
				continue
			}
			
			;if fithTile is in slot 5, move fourthTile left. otherwise, the rest will be handled later
			if(compareTile([row,5], fithTile)){
				shoveTileToCol(fourthTileNum, 3, obstacles)
				continue
			}
		}
		
		;if both tiles are in the two slots directly below the final slots
		if(compareTilesToSlots([[row + 1, 4], [row + 1, 5]], [fourthTile, fithTile])){
			
			;if blankTile is stuck, move down
			;otherwise, slide the tile on the right to the right by 1
			if(blankTile[1] = row){
				moveDown([])
				continue
			}
			pathFind([row + 1,3], obstacles)
			moveRight([])
			continue
		}
		
		;if one of the tiles is below slot 4 and the other is two spaces below slot 5
		if(compareTilesToSlots([[row + 1, 4], [row + 2, 5]], [fourthTile, fithTile])){
			
			;if blankTile is stuck, move to [row,4] and move down.
			;otherwise, move the tile in [row + 1,4] to the side and move the other tile up into row
			if(compareTileToMultipleOR(blankTile, [[row,4], [row,5], [row + 1,5]])){
				pathFind([row,4], obstacles)
				moveDown([])
			}else{
				pathFind([row + 1,3], obstacles)
				moveRight([])
				moveRight([])
				moveDown([])
				moveLeft([])
				moveUp([])
				moveUp([])
				moveRight([])
				moveDown([])
			}
			continue
		}
		
		;if blankTile is stuck in [row,5] with both tiles below and to the left
		if(compareTile(blankTile, [row,5]) && compareTilesToSlots([[row,4], [row + 1, 5]], [fourthTile, fithTile])){
			
			;if blankTile is above fithTile and right of fourthTile, move down and return
			;otherwise, move left
			if(compareTile(getTileToDown(blankTile), fithTile)){
				moveDown([])
				return
			}
			moveLeft([])
			continue
		}
		
		;if both tiles are in the row but in the wrong spot
		if(board[row][4] = fithTileNum && board[row][5] = fourthTileNum){
			pathFind(getTileToDown(fourthTile), obstacles)
			moveUp([])
			moveLeft([])
			continue
		}
		
		;if neither tile is in col 5 and both tiles are touching horizontally (including diagonals)
		eitherTileInCol5 := (fourthTile[2] = 5) || (fithTile[2] = 5)
		bothTilesInAdjacentCol := (Abs(fourthTile[2] - fithTile[2]) < 2)
		tileInRow1Down := (fourthTile[1] = row + 1 || fithTile[1] = row + 1)
		tileInRow2Down := (fourthTile[1] = row + 2 || fithTile[1] = row + 2)
		if(!eitherTileInCol5 && bothTilesInAdjacentCol && tileInRow1Down && tileInRow2Down){
			
			;if blankTile is right of either tile or in row
			if(blankTile[2] > fourthTile[2] || blankTile[2] > fithTile[2] || blankTile[1] = row){
				
				;if one of the tiles is in [row + 1,4], move that tile up into row
				if(compareTileToMultipleOR([row + 1,4], [fourthTile, fithTile])){
					pathFind([row,4], obstacles)
					moveDown([])
					continue	
				}
				
				;if not, but one of the tiles is in the slot below it, shove it up into row
				if(compareTileToMultipleOR([row + 2,4], [fourthTile, fithTile])){
					pathFind([row + 1,4], obstacles)
					moveDown([])
					moveRight([])
					moveUp([])
					moveUp([])
					moveLeft([])
					moveDown([])
					continue
				}
				
				;otherwise, move next to the tile in row + 1, then move left
				if(fourthTile[1] = row + 1){
					pathFind(getTileToRight(fourthTile), obstacles)
				}else{
					pathFind(getTileToRight(fithTile), obstacles)
				}
				moveLeft([])
				
				;if the other tile is now below blankTile, move down
				if(compareTileToMultipleOR(getTileToDown(blankTile), [fourthTile, fithTile])){
					moveDown([])
				}
				continue
			}
			
			;store the tile that is is in row + 2 into a tempTile var
			tempTile :=
			if(fourthTile[1] = row + 2){
				tempTile := fourthTile
			}else{
				tempTile := fithTile
			}
			
			;pathFind to the tile below that tile if possible, then move right 1. otherwise, pathFind next to it and move right
			if(!pathFind(getTileToDown(tempTile), obstacles)){
				pathFind(getTileToLeft(tempTile), obstacles)
				moveRight([])
			}else{
				moveRight(obstacles)
			}
			continue
		}
		
		;if both tiles are in col 4 or 5
		if(fourthTile[2] > 3 && fithTile[2] > 3){
			
			;if both tiles are next to eachother, move the left tile to the left and the other tile up
			if(fourthTile[1] = fithTile[1]){
				pathFind([fourthTile[1],3], obstacles)
				moveRight([])
				moveUp([])
				moveRight([])
				moveDown([])
				fourthTile := findBoardTile(fourthTileNum)
				fithTile := findBoardTile(fithTileNum)
			}
			
			if(tileInRow1Down && tileInRow2Down){
				if(compareTile(getTileToDown(fourthTile), fithTile)){
					pathFind(getTileToDown(fithTile), obstacles)
				}else{
					pathFind(getTileToDown(fourthTile), obstacles)
				}
			}
			
			;if fourthTile is higher than fithTile, shove fourthTile up
			;otherwise, shove fithTile up
			if(fourthTile[1] < fithTile[1]){
				shoveTileToRow(fourthTileNum, row, obstacles)
				fourthTile := findBoardTile(fourthTileNum)
			}else{
				shoveTileToRow(fithTileNum, row, obstacles)
				fithTile := findBoardTile(fithTileNum)
			}
		}
		
		;if neither tile is in row
		if(fourthTile[1] > row && fithTile[1] > row){
			
			;if blankTile is trapped below 1/2/3, left of one of the tiles, and above the other, just move down
			if(compareTileToMultipleOR(blankTile, [[row + 1,1], [row + 1,2], [row + 1,3]])){
				if(compareTileToMultipleOR(getTileToDown(blankTile), [fourthTile, fithTile])){
					if(compareTileToMultipleOR(getTileToRight(blankTile), [fourthTile, fithTile])){
						moveDown([])
						continue
					}
				}
			}
			
			;if fourthTile is right of or in the same col as fithTile, move it into row
			;otherwise, move fithTile into row
			if(fourthTile[2] >= fithTile[2]){
				
				;if fourthTile is left of col 4, move it to col 4
				if(fourthTile[2] < 4){
					
					;if fourthTile is in row and fithTile is right above it, move fourthTile right 1 and fithTile down to get blankTile unstuck
					if(fourthTile[1] = 5 && compareTile(getTileToUp(fourthTile), fithTile)){
						pathFind(getTileToRight(fourthTile), obstacles)
						moveLeft([])
						moveUp([])
					}
					shoveTileToCol(fourthTileNum, 4, obstacles)
				}
				shoveTileToRow(fourthTileNum, row, obstacles)
				fourthTile := findBoardTile(fourthTileNum)
			}else{
				
				;if fithTile is left of col 4, move it to col 4
				if(fithTile[2] < 4){
					shoveTileToCol(fithTileNum, 4, obstacles)
				}
				shoveTileToRow(fithTileNum, row, obstacles)
				fithTile := findBoardTile(fithTileNum)
			}
		}
		
		;if fithTile is in the final spot
		if(areTilesSolved([fithTileNum])){
			
			;if fourthTile is right below fithTile
			if(compareTile(getTileToDown(fithTile), fourthTile)){
				pathFind(getTileToDown(fourthTile), obstacles)
				moveUp([])
				fourthTile := findBoardTile(fourthTileNum)
			}
			pathFind(getTileToLeft(fithTile), obstacles)
			moveRight([])
			fithTile := findBoardTile(fithTileNum)
		}
		
		;if fourthTile is in the final spot
		if(areTilesSolved([fourthTileNum])){
			
			;if fithTile is right below fourthTile
			if(compareTile(getTileToDown(fourthTile), fithTile)){
				pathFind(getTileToDown(fithTile), obstacles)
				moveUp([])
				fithTile := findBoardTile(fithTileNum)
			}
			
			;if fithTile is below its final spot
			if(compareTile(getTileToDown([row,5]), fithTile)){
				pathFind(getTileToDown(fithTile), obstacles)
				moveUp([])
				fithTile := findBoardTile(fithTileNum)
			}
			
			pathFind(getTileToRight(fourthTile), obstacles)
			moveLeft([])
			fourthTile := findBoardTile(fourthTileNum)
		}
		
		;if fourthTile is in row and not in final spot, move fithTile below it
		;otherwise, fithTile should logically be in row and not in final spot, so move fourthTile below it
		if(compareTile([row,5], fourthTile)){
			shoveTileToPos(fithTileNum, getTileToDown(fourthTile), obstacles)
			fithTile := findBoardTile(fithTileNum)
			pathFind(getTileToLeft(fourthTile), obstacles)
			moveRight([])
			moveDown([])
		}else{
			shoveTileToPos(fourthTileNum, getTileToDown(fithTile), obstacles)
			fourthTile := findBoardTile(fourthTileNum)
			pathFind(getTileToRight(fithTile), obstacles)
			moveLeft([])
			moveDown([])
		}
	}
}

solveBottom(ByRef obstacles){
	upperTileNum := 16
	lowerTileNum := 21
	
	col := 1
	while(col < 4){
		upperTile := findBoardTile(upperTileNum)
		lowerTile := findBoardTile(lowerTileNum)
		obstacles.Push(upperTileNum)
		obstacles.Push(lowerTileNum)
		
		;if both of the two tiles aren't already where they are supposed to be
		if(!areTilesSolved([upperTileNum, lowerTileNum])){
			
			;if one of the tiles is in the right spot
			if((areTilesSolved([lowerTileNum]) || areTilesSolved([upperTileNum]))){
				
				;if both tiles are next to eachother
				if(compareTile(getTileToLeft(upperTile), lowerTile)){
					flipBothTilesRowNoLeftSpace(lowerTileNum, upperTileNum, col, obstacles)
					shoveTogetherAndSlide(upperTileNum, lowerTileNum, col, false, obstacles)
					upperTileNum++
					lowerTileNum++
					upperTile := findBoardTile(upperTileNum)
					lowerTile := findBoardTile(lowerTileNum)
					col++
					Continue
					
				}else if(compareTile(getTileToRight(upperTile), lowerTile)){
					flipBothTilesRowNoLeftSpace(upperTileNum, lowerTileNum, col, obstacles)
					shoveTogetherAndSlide(lowerTileNum, upperTileNum, col, false, obstacles)
					upperTileNum++
					lowerTileNum++
					upperTile := findBoardTile(upperTileNum)
					lowerTile := findBoardTile(lowerTileNum)
					col++
					Continue
				}
				
				;if blankTile is in col
				if(blankTile[2] = col){
					
					;if blankTile is next to the remaining tile
					if(compareTileToMultipleOR(getTileToRight(blankTile), [upperTile, lowerTile])){
						moveRight([])
						upperTileNum++
						lowerTileNum++
						upperTile := findBoardTile(upperTileNum)
						lowerTile := findBoardTile(lowerTileNum)
						col++
						Continue
						
					}else{
						;if trying to move down fails, then move up. moveDown is first because otherwise it can move up into solved rows
						if(moveDown([])){
							shoveTogetherAndSlide(upperTileNum, lowerTileNum, col, false, obstacles)
						}else{
							moveUp([])
							shoveTogetherAndSlide(lowerTileNum, upperTileNum, col, false, obstacles)
						}
					}
				}else{
					
					;shoveTogetherAndSlide based on what tile is in the correct col
					if(compareTile(upperTile, [4,col])){
						shoveTogetherAndSlide(lowerTileNum, upperTileNum, col, true, obstacles)
					}else{
						shoveTogetherAndSlide(upperTileNum, lowerTileNum, col, true, obstacles)
					}
				}
				
				upperTileNum++
				lowerTileNum++
				upperTile := findBoardTile(upperTileNum)
				lowerTile := findBoardTile(lowerTileNum)
				col++
				Continue
				
			;if neither tile is in the correct spot
			}else{
				;if blankTile is stuck above/below one of the tiles with the other right next to it
				if(compareTileToMultipleOR(getTileToDown(blankTile), [upperTile, lowerTile]) || compareTileToMultipleOR(getTileToUp(blankTile), [upperTile, lowerTile])){
					if(compareTileToMultipleOR(getTileToRight(blankTile), [upperTile, lowerTile]) || compareTileToMultipleOR(getTileToLeft(blankTile), [upperTile, lowerTile])){
						if(!moveDown([])){
							moveUp([])
						}
					}
				}
				
				upperTile := findBoardTile(upperTileNum)
				lowerTile := findBoardTile(lowerTileNum)
				
				;if one tile is above the directly other
				if(lowerTile[2] = upperTile[2]){
					
					;figure out what side blankTile is on and move both tiles next to eachother
					if(blankTile[2] > upperTile[2]){
						pathFind(getTileToRight(upperTile), obstacles)
						moveLeft([])
					}else{
						pathFind(getTileToLeft(upperTile), obstacles)
						moveRight([])
					}
					
					if(!moveDown([])){
						moveUp([])
					}
					upperTile := findBoardTile(upperTileNum)
					lowerTile := findBoardTile(lowerTileNum)
				}
				
				;if both tiles are next to eachother
				if(compareTile(getTileToLeft(upperTile), lowerTile) || compareTile(getTileToRight(upperTile), lowerTile)){
					
					;if the tiles are shoved left, perform the "no space" row flip
					if(compareTile(lowerTile, [5,col])){
						flipBothTilesRowNoLeftSpace(lowerTileNum, upperTileNum, col, obstacles)
					}else if(compareTile(upperTile, [4,col])){
						flipBothTilesRowNoLeftSpace(upperTileNum, lowerTileNum, col, obstacles)
					}
					
					;flip tile rows if needed
					upperTile := findBoardTile(upperTileNum)
					lowerTile := findBoardTile(lowerTileNum)
					if(upperTile[2] > lowerTile[2] && upperTile[1] = 5){
						pathFind(getTileToLeft(lowerTile), obstacles)
						moveRight([])
						flipTileRow(lowerTileNum, obstacles)
						flipTileRow(upperTileNum, obstacles)
						
					}else if(upperTile[2] < lowerTile[2] && upperTile[1] = 4){
						pathFind(getTileToLeft(upperTile), obstacles)
						moveRight([])
						flipTileRow(lowerTileNum, obstacles)
						flipTileRow(upperTileNum, obstacles)
					}
				}
				upperTile := findBoardTile(upperTileNum)
				lowerTile := findBoardTile(lowerTileNum)
				
				;if upperTile is diagonal up/dpwn left of the other with blankTile to the left (nesting ifs just for readability)
				if(compareTile(getTileToDown(getTileToLeft(upperTile)), lowerTile) || compareTile(getTileToUp(getTileToLeft(upperTile)), lowerTile)){
					if(blankTile[2] < upperTile[2]){
						pathFind(getTileToLeft(lowerTile), obstacles)
						moveRight([])
							;continue so the board state can be re-evaluated
						Continue
					}
				}
				
				;if lowerTile is diagonal up/dpwn left of the other with blankTile to the left (nesting ifs just for readability)
				if(compareTile(getTileToDown(getTileToLeft(lowerTile)), upperTile) || compareTile(getTileToUp(getTileToLeft(lowerTile)), upperTile)){
					if(blankTile[2] < lowerTile[2]){
						pathFind(getTileToLeft(upperTile), obstacles)
						moveRight([])
							;continue so the board state can be re-evaluated
						Continue
					}
				}
				
				;if upperTile is to the left of lowerTile
				if(upperTile[2] < lowerTile[2]){
					
					;if upperTile is on row 5
					if(upperTile[1] = 5){
						shoveTogetherAndSlide(lowerTileNum, upperTileNum, col, false, obstacles)
						
					;if upperTile is on row 4
					}else{
						shoveTogetherAndSlide(lowerTileNum, upperTileNum, col, true, obstacles)
					}
					
				;if upperTile is to the right of lowerTile
				}else{
					
					;if lowerTile is on row 4
					if(lowerTile[1] = 4){
						shoveTogetherAndSlide(upperTileNum, lowerTileNum, col, false, obstacles)
						
					;if lowerTile is on row 5
					}else{
						shoveTogetherAndSlide(upperTileNum, lowerTileNum, col, true, obstacles)
					}
				}
			}
		}
		upperTileNum++
		lowerTileNum++
		upperTile := findBoardTile(upperTileNum)
		lowerTile := findBoardTile(lowerTileNum)
		col++
		Continue
	}
}

spin(){
	blankTile := findBoardTile(25)
	corner := board[5][5]
	
	if(compareTile(blankTile, [4,4])){
		if(corner = 20){
			moveRight([])
			moveDown([])
		}else if(corner = 24){
			moveDown([])
			moveRight([])
		}else{
			moveRight([])
			moveDown([])
			moveLeft([])
			moveUp([])
			moveRight([])
			moveDown([])
		}
	}else if(compareTile(blankTile, [5,4])){
		if(corner = 20){
			moveUp([])
			moveRight([])
			moveDown([])
		}else if(corner = 24){
			moveRight([])
		}else{
			moveRight([])
			moveUp([])
			moveLeft([])
			moveDown([])
			moveRight([])
		}
	}else if(compareTile(blankTile, [4,5])){
		if(corner = 20){
			moveDown([])
		}else if(corner = 24){
			moveLeft([])
			moveDown([])
			moveRight([])
		}else{
			moveDown([])
			moveLeft([])
			moveUp([])
			moveRight([])
			moveDown([])
		}
	}
}

cleanMoveQueue(){
	for i, v in moveQueue{
		if((v = "Up" && moveQueue[i + 1] = "Down") || (v = "Down" && moveQueue[i + 1] = "Up") || (v = "Right" && moveQueue[i + 1] = "Left") || (v = "Left" && moveQueue[i + 1] = "Right")){
			moveQueue.RemoveAt(i)
			moveQueue.RemoveAt(i)
		}
	}
}

pathFind(destination, obstacles){
	
	;sits here purely for debugging purposes. set debugFlag to true before calling 
	;pathFind and slide this if statement up and down through the function
	if(debugFlag){
		printBoard()
	}
	
	if(destination == false || !canMoveHere(destination, obstacles)){
		return false
	}
	
	while(!compareTile(blankTile, destination)){
		while(blankTile[2] > destination[2]){
			if(!moveLeft(obstacles)){
				if(blankTile[1] <= destination[1]){
					if(!moveDown(obstacles)){
						moveUp(obstacles)
					}
				}else{
					if(!moveUp(obstacles)){
						moveDown(obstacles)
					}
				}
			}
		}
		
		while(blankTile[1] > destination[1]){
			if(!moveUp(obstacles)){
				if(blankTile[2] <= destination[2]){
					if(!moveRight(obstacles)){
						
						;if all the tiles above and to the left of blankTile are obstacles, go down and around the tile to the right
						if(isObstacleChain(getTileToUp(blankTile), [getTileToUp(blankTile)[1],1], obstacles)){
							moveDown(obstacles)
							moveRight(obstacles)
							Break
						}
						
						if(!moveLeft(obstacles)){
							moveDown(obstacles)
							if(!moveRight(obstacles)){
								moveLeft(obstacles)
							}
						}
					}
				}else{
					if(!moveLeft(obstacles)){
						moveRight(obstacles)
					}
				}
			}
		}
		
		while(blankTile[1] < destination[1]){
			if(!moveDown(obstacles)){
				if(blankTile[2] >= destination[2]){
					moveLeft(obstacles)
				}else{
					if(!moveRight(obstacles)){
						moveLeft(obstacles)
					}
				}
			}
		}
		
		while(blankTile[2] < destination[2]){
			if(!moveRight(obstacles)){
				if(blankTile[1] <= destination[1]){
					if(!moveDown(obstacles)){
						moveUp(obstacles)
					}
				}else{
					if(!moveUp(obstacles)){
						moveDown(obstacles)
					}
				}
			}
		}
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Shoves
shoveTileRight(shovingTileNum, obstacles){
	shoveTo := Mod(shovingTileNum, 5) + 1
	if(shoveTo = 1){
		shoveTo := 5
	}
	shovingTile := findBoardTile(shovingTileNum)
	pathTo := getTileToRight(shovingTile)
	
;path to tile right from target and then move target right by one, but only if target is left from where it needs to be
	if(shovingTile[2] < shoveTo){
		pathFind(pathTo, obstacles)
		moveLeft([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
;repeatedly move target tile right until at the target position
	while(shovingTile[2] < shoveTo){
		wentDown := true
		if(!moveDown(obstacles)){
			moveUp(obstacles)
			wentDown := false
		}
		moveRight(obstacles)
		moveRight(obstacles)
		if(wentDown){
			moveUp(obstacles)
		}else{
			moveDown(obstacles)
		}
		moveLeft([])
		shovingTile := findBoardTile(shovingTileNum)
	}
}

shoveTileUp(shovingTileNum, obstacles){
	shoveTo := Ceil((shovingTileNum + 1) / 5)
	shovingTile := findBoardTile(shovingTileNum)
	pathTo := getTileToUp(shovingTile)
	
;path to tile up from target and then move target up by one, but only if target is below where it needs to be
	if(shovingTile[1] > shoveTo){
		pathFind(pathTo, obstacles)
		moveDown([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
;repeatedly move target tile up until at the target position
	while(shovingTile[1] > shoveTo){
		wentLeft := true
		if(!moveLeft(obstacles)){
			moveRight(obstacles)
			wentLeft := false
		}
		moveUp(obstacles)
		moveUp(obstacles)
		if(wentLeft){
			moveRight(obstacles)
		}else{
			moveLeft(obstacles)
		}
		moveDown([])
		shovingTile := findBoardTile(shovingTileNum)
	}
}

shoveTileLeft(shovingTileNum, obstacles){
	shoveTo := Mod(shovingTileNum, 5) + 1
	shovingTile := findBoardTile(shovingTileNum)
	pathTo := getTileToLeft(shovingTile)
	
;path to tile left from target and then move target up by one, but only if target is right from where it needs to be
	if(shovingTile[2] > shoveTo){
		pathFind(pathTo, obstacles)
		moveRight([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
;repeatedly move target tile left until at the target position
	while(shovingTile[2] > shoveTo){
		wentDown := true
		if(!moveDown(obstacles)){
			moveUp(obstacles)
			wentDown := false
		}
		moveLeft(obstacles)
		moveLeft(obstacles)
		if(wentDown){
			moveUp(obstacles)
		}else{
			moveDown(obstacles)
		}
		moveRight([])
		shovingTile := findBoardTile(shovingTileNum)
	}
}

shoveTileToCol(shovingTileNum, shoveToCol, obstacles){
	shovingTile := findBoardTile(shovingTileNum)
	
;path to tile right from target and then move target right by one, but only if target is left from where it needs to be.
;repeat as needed
	while(shovingTile[2] < shoveToCol){
		pathFind(getTileToRight(shovingTile), obstacles)
		moveLeft([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
;same thing, but now to the left
	while(shovingTile[2] > shoveToCol){
		pathFind(getTileToLeft(shovingTile), obstacles)
		moveRight([])
		shovingTile := findBoardTile(shovingTileNum)
	}
}

shoveTileToRow(shovingTileNum, shoveToRow, obstacles){
	shovingTile := findBoardTile(shovingTileNum)
	
	;path to tile up from target and then move target up by one, but only if target is down from where it needs to be.
	;repeat as needed
	while(shovingTile[1] > shoveToRow){
		pathFind(getTileToUp(shovingTile), obstacles)
		moveDown([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
	;same thing, but now down
	while(shovingTile[1] < shoveToRow){
		pathFind(getTileToDown(shovingTile), obstacles)
		moveUp([])
		shovingTile := findBoardTile(shovingTileNum)
	}
}

shoveTileToPos(shovingTileNum, shoveTo, obstacles){
	shoveTileToCol(shovingTileNum, shoveTo[2], obstacles)
	shoveTileToRow(shovingTileNum, shoveTo[1], obstacles)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Special menuvers for solving bottom 2 rows
shoveTogetherAndSlide(shovingTileNum, baseTileNum, col, baseTileInWrongRow, obstacles){
	shovingTile := findBoardTile(shovingTileNum)
	baseTile := findBoardTile(baseTileNum)
	
	if(baseTileInWrongRow && Abs(blankTile[2] - baseTile[2]) < Abs(blankTile[2] - shovingTile[2])){
		flipTileRow(baseTileNum, obstacles)
		baseTileInWrongRow := false
	}
	
	;move shovingTile 2 spaces away from baseTile if it is at least than 3 spaces to the left
	while(shovingTile[2] > baseTile[2] + 1){
		if(baseTileInWrongRow && shovingTile[2] = baseTile[2] + 2){
			flipTileRow(baseTileNum, obstacles)
			baseTileInWrongRow := false
		}
		pathFind(getTileToLeft(shovingTile), obstacles)
		moveRight([])
		shovingTile[2]--
	}
	shovingTile := findBoardTile(shovingTileNum)
	baseTile := findBoardTile(baseTileNum)
	
	;if baseTile still needs to be flipped and shovingTile is one col to the right, move shovingTile right by 1 and flip baseTile
	if(baseTileInWrongRow && shovingTile[2] = baseTile[2] + 1){
		pathFind(getTileToRight(shovingTile), obstacles)
		moveLeft([])
		shovingTile := findBoardTile(shovingTileNum)
		flipTileRow(baseTileNum, obstacles)
		baseTileInWrongRow := false
		shovingTile := findBoardTile(shovingTileNum)
		baseTile := findBoardTile(baseTileNum)
	}
	
	;make sure both tiles are on the same row
	if(baseTile[1] != shovingTile[1]){
		flipTileRow(shovingTileNum, obstacles)
		shovingTile := findBoardTile(shovingTileNum)
		baseTile := findBoardTile(baseTileNum)
	}
	
	;move shovingTile next to baseTile
	while(!compareTile(getTileToRight(baseTile), shovingTile)){
		pathFind(getTileToLeft(shovingTile), obstacles)
		moveRight([])
		shovingTile := findBoardTile(shovingTileNum)
	}
	
	slideIntoLeftCol(baseTileNum, col, obstacles)
}

slideIntoLeftCol(leftTileNum, col, obstacles){
	leftTile := findBoardTile(leftTileNum)
	
	;slide both tiles to the proper column
	while(leftTile[2] > col){
		pathFind(getTileToLeft(leftTile), obstacles)
		Loop, 2{
			moveRight([])
		}
		leftTile := findBoardTile(leftTileNum)
	}
	
	;final rotation of both tiles
	flipTileRow(leftTileNum, obstacles)
	moveRight([])
}

flipTileRow(flippingTileNum, obstacles){
	flippingTile := findBoardTile(flippingTileNum)
	
	if(flippingTile[1] = 5){
		pathFind(getTileToUp(flippingTile), obstacles)
		moveDown([])
	}else{
		pathFind(getTileToDown(flippingTile), obstacles)
		moveUp([])
	}
}

flipBothTilesRowNoLeftSpace(leftTileNum, rightTileNum, col, obstacles){
	rightTile := findBoardTile(rightTileNum)
	leftTile := findBoardTile(leftTileNum)
	
	;flip rightTile and move it over to give space to move to leftTile
	flipTileRow(rightTileNum, obstacles)
	rightTile := findBoardTile(rightTileNum)
	pathFind(getTileToRight(rightTile), obstacles)
	moveLeft([])
	
	;then flip leftTile
	flipTileRow(leftTileNum, obstacles)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Get Neighbor Tiles
getTileToRight(sourceTile){
	if(sourceTile[2] != 5){
		return [sourceTile[1], sourceTile[2] + 1]
	}else{
		return false
	}
}

getTileToLeft(sourceTile){
	if(sourceTile[2] != 1){
		return [sourceTile[1], sourceTile[2] - 1]
	}else{
		return false
	}
}

getTileToUp(sourceTile){
	if(sourceTile[1] != 1){
		return [sourceTile[1] - 1, sourceTile[2]]
	}else{
		return false
	}
}

getTileToDown(sourceTile){
	if(sourceTile[1] != 5){
		return [sourceTile[1] + 1, sourceTile[2]]
	}else{
		return false
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Board/Tile Checking
findBoardTile(slot){
	for i, v in board{
		for j, w in v{
			if(w = slot){
				return [i,j]
			}
		}
	}
	return "Not Found"
}

validateBoard(){
	tileNum := 1
	while(tileNum < 26){
		if(findBoardTile(tileNum) = "Not Found"){
			return false
		}
		tileNum++
	}
	return true
}

areTilesSolved(tileNumList){
	for i, v in tileNumList{
		x := Floor((v - 1) / 5) + 1
		y := Mod(v, 5)
		if(y = 0){
			y := 5
		}
		
		if(!compareTile([x,y], findBoardTile(v))){
			return false
		}
	}
	return true
}

isRowSolved(row){
	currentTileNum := ((row - 1) * 5) + 1
	tileNumList := []
	
	Loop, 5{
		tileNumList.Push(currentTileNum)
		currentTileNum++
	}
	
	return areTilesSolved(tileNumList)
}

isBoardSolved(){
	tileNum := 1
	tileNumList := []
	while(tileNum < 25){
		tileNumList.Push(tileNum)
		tileNum++
	}
	return areTilesSolved(tileNumList)
}

canMoveHere(tileToCheck, obstacles){
	for i, v in obstacles{
		if(compareTile(tileToCheck, findBoardTile(v))){
			return false
		}
	}
	return true
}

isObstacleChain(startingTile, endingTile, obstacles){
	currentTile := startingTile
	while(!compareTile(endingTile, currentTile)){
		if(canMoveHere(currentTile, obstacles)){
			return false
		}
		currentTile := getTileToLeft(currentTile)
	}
	
	if(canMoveHere(currentTile, obstacles)){
		return false
	}
	
	return true
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Moves
moveUp(obstacles){
	if(blankTile[1] > 1){
		if(canMoveHere(getTileToUp(blankTile), obstacles)){
			moveQueue.Push("Up")
			board[blankTile[1]][blankTile[2]] := board[blankTile[1] - 1][blankTile[2]]
			board[blankTile[1] - 1][blankTile[2]] := 25
			blankTile[1]--
			return true
		}
	}
	return false
}

moveDown(obstacles){
	if(blankTile[1] < 5){
		if(canMoveHere(getTileToDown(blankTile), obstacles)){
			moveQueue.Push("Down")
			board[blankTile[1]][blankTile[2]] := board[blankTile[1] + 1][blankTile[2]]
			board[blankTile[1] + 1][blankTile[2]] := 25
			blankTile[1]++
			return true
		}
	}
	return false
}

moveLeft(obstacles){
	if(blankTile[2] > 1){
		if(canMoveHere(getTileToLeft(blankTile), obstacles)){
			moveQueue.Push("Left")
			board[blankTile[1]][blankTile[2]] := board[blankTile[1]][blankTile[2] - 1]
			board[blankTile[1]][blankTile[2] - 1] := 25
			blankTile[2]--
			return true
		}
	}
	return false
}

moveRight(obstacles){
	if(blankTile[2] < 5){
		if(canMoveHere(getTileToRight(blankTile), obstacles)){
			moveQueue.Push("Right")
			board[blankTile[1]][blankTile[2]] := board[blankTile[1]][blankTile[2] + 1]
			board[blankTile[1]][blankTile[2] + 1] := 25
			blankTile[2]++
			return true
		}
	}
	return false
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Printers/String Handlers and Data Manipulators/Checkers
printBoard(){
	strBuffer := ""
;i = x, j = y
	for i, v in board{
		for j, w in v{
			if(w < 10){
				strBuffer .= 0
			}
			strBuffer .= w
			if(j != 5){
				strBuffer .= ", "
			}else{
				strBuffer .= "`n"
			}
		}
	}
	MsgBox % strBuffer
}

addArrayToStr(myArray, ByRef str){
	for i, v in myArray{
		str .= v "`n"
	}
}

printStr(myArray){
	strBuffer := ""
	for i, v in myArray{
		strBuffer .= v "`n"
	}
	
	MsgBox % strBuffer
}

compareTile(arr1, arr2) {
	if(!arr1 || !arr2){
		return false
	}
	for i, v in arr1 {
		if (arr2[i] != v) {
			return False
		}
	}
	return True
}

compareTileToMultipleOR(arrToCompare, compareToList){
	for i, v in compareToList{
		if(compareTile(arrToCompare, v)){
			return true
		}
	}
	return false
}

compareTilesToSlots(listOfTiles, listOfSlots){
	for i, v in listOfSlots{
		if(!compareTileToMultipleOR(v, listOfTiles)){
			return false
		}
	}
	return true
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Capturing/Processing Screen Data
findTileFromImg(tileName, tileX, tileY, ByRef foundX, ByRef foundY){
	filePath := "PuzzleImages\" tileName "\" tileName tileX "-" tileY ".png"
	ImageSearch, foundX, foundY, searchX1, searchY1, searchX2, searchY2, % filePath
}

getBoardState(puzzleName){
	imgLocationX := 0
	imgLocationY := 0
	strBuffer := ""
	board := [[25,25,25,25,25]
			,[25,25,25,25,25]
			,[25,25,25,25,25]
			,[25,25,25,25,25]
			,[25,25,25,25,25]]
	tileScreenLocationX := [[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]]
	tileScreenLocationY := [[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]
					  ,[25,25,25,25,25]]
	;i = x, j = y
	for i, v in board{
		for j, w in v{
			if(i = 5 && j = 5){
				Break
			}
			findTileFromImg(puzzleName, i, j, imgLocationX, imgLocationY)
			if(ErrorLevel = 1){
				;MsgBox % puzzleName i "-" j ".png not found"
				return false
			}else if(ErrorLevel = 2){
				MsgBox % "Could not open file " puzzleName i "-" j ".png"
				return false
			}
			
			;imgLocation is the actual screen coords the ingame tile was found at
			;tileScreenLocation is an array of those values linking both coords to the same slot in said array
			tileScreenLocationX[i][j] := imgLocationX
			tileScreenLocationY[i][j] := imgLocationY
		}
	}
	
	screenToBoard(tileScreenLocationX, tileScreenLocationY)
	
	if(!validateBoard()){
		MsgBox % "The " puzzleName " board was found but not validated."
		printBoard()
		return false
	}
	return true
}

screenToBoard(imgLocationsX, imgLocationsY){
	uniqueX := countUniques(imgLocationsX)
	uniqueY := countUniques(imgLocationsY)
	sortUniques(uniqueX)
	sortUniques(uniqueY)
	
;go through each tile
	imgTileX := 1
	while(imgTileX < 6){
		imgTileY := 1
		while(imgTileY < 6){
			
		;if 5,5 skip because its blankTile and doesnt have an image
			if(imgTileX = 5 && imgTileY = 5){
				Break
			}
			
		;start boardTileX at 1, then increase it until the unique with the index of boardTileX matches the imgLocation value
			boardTileX := 1
			while(imgLocationsX[imgTileX][imgTileY] != uniqueX[boardTileX]){
				boardTileX++
			}
			
		;same thing for boardTileY
			boardTileY := 1
			while(imgLocationsY[imgTileX][imgTileY] != uniqueY[boardTileY]){
				boardTileY++
			}
			
		;yes, y then x, that is not a bug
			board[boardTileY][boardTileX] := ((imgTileX - 1) * 5) + imgTileY
			imgTileY++
		}
		imgTileX++
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Unique Processors
countUniques(myArray){
	uniqueList := []
	for i, v in myArray{
		for j, w in v{
			found := false
			for k, z in uniqueList{
				if(w = z){
					found := true
					Break
				}
			}
			if(!found && w != 25){
				uniqueList.Push(w)
			}
		}
	}
	return uniqueList
}

sortUniques(ByRef uniques){
	for i, v in uniques{
		head := i
		while(head > 1 && v < uniques[head - 1]){
			uniques[head] := uniques[head - 1]
			uniques[head - 1] := v
			head--
		}
	}
}

addUniquesToStr(uX, uY, ByRef str){
	str .= "X Uniques:`n"
	addArrayToStr(uX, str)
	str .= "Y Uniques:`n"
	addArrayToStr(uY, str)
}


#IfWinActive RuneScape

F6::
solve5x5()
return

F7::
F8::
executeMove()
return

#IfWinActive

;F2::
;MouseGetPos, xpos, ypos
;MouseClickDrag, Left, xpos, ypos, xpos + 385, ypos + 385
;return

F9::
testSolver()
return

F10::
if(faltyBoardFound){
	MsgBox % "Debugging has been disabled"
	faltyBoardFound := false
}else{
	MsgBox % "Debugging Initiated. Board will now be printed on runtime."
	faltyBoardFound := true
}
return
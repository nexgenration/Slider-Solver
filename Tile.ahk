#Requires AutoHotkey v2.0-beta


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
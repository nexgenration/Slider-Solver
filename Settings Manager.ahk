;#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode("Input")  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir(A_ScriptDir)  ; Ensures a consistent starting directory.

Class SettingsUI extends Gui {

	;constructor
	__New() {
	   super.__New(, "Settings")
	   this.MakeFontNicer().DarkMode()
	   this.loadSettings() ;!!!needs to be moved out of class if setScanCoordsButton closes GUI and then creates a new instance
	   
	   this.gcSetScanCoordsButton := this.AddButton(, "Set scan coordinates...")
	   this.gcSetScanCoordsButton.OnEvent("Click", this.foSetScanCoordsButton)

	   this.gcDebugToggleButton := this.AddButton(, "Toggle Debug Mode")
	   this.gcDebugToggleButton.OnEvent("Click", this.foDebugToggleButton)

	   this.gcSaveButton := this.AddButton(, "Apply and Exit")
	   this.gcSaveButton.OnEvent("Click", this.foSaveButton)
	   
	   this.Show("AutoSize")
	}

	loadSettings(){
		;!!!load settings from file
	}

	foSetScanCoordsButton := this.foSetScanCoordsButton.Bind(this)
	setScanCoordsButton(*){
		;!!!do something
	}

	foDebugToggleButton := this.foDebugToggleButton.Bind(this)
	debugToggleButton(*){
		;!!!toggle debug varable
		MsgBox("Debug Mode is now turned ") ;!!!add debug variable
	}
	
	foSaveButton := this.SaveButton.Bind(this)
	SaveButton(*) {
	   ;!!!do something
	   this.Destroy()
	}
	
	Destroy() {
	   this.Minimize()
	   super.Destroy()
	}

	DarkMode(guiObj) {
		guiObj.BackColor := "171717"
		return guiObj
	}

	;Gui.Prototype.DefineProp("DarkMode", {Call: DarkMode})
	 
	MakeFontNicer(guiObj, fontSize := 20) {
		guiObj.SetFont("s" fontSize " cC5C5C5", "Consolas")
		return guiObj
	}
	
	;Gui.Prototype.DefineProp("MakeFontNicer", {Call: MakeFontNicer})
}

SettingsUI()

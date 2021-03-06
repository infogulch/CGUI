/*
Class: CControl
Basic control class from which all controls extend.
*/
Class CControl ;Never created directly
{
	__New(Name, Options, Text, GUINum) ;Basic constructor for all controls. The control is created in CGUI.AddControl()
	{
		this.Insert("Name", Name)
		this.Insert("Options", Options)
		this.Insert("Content", Text)
		this.Insert("GUINum", GUINum) ;Store link to gui for GuiControl purposes (and possibly others later
		this.Insert("_", {}) ;Create proxy object to enable __Get and __Set calls for existing keys (like ClassNN which stores a cached value in the proxy)
		this.Insert("Font", new CFont(GUINum))
		this._.Insert("RegisteredEvents", {})
	}
	PostCreate()
	{
		this.Font._.hwnd := this.hwnd
	}
	/*
	Function: Show
	Shows the control if it was previously hidden.
	*/
	Show()
	{
		if(CGUI.GUIList[this.GUINum].IsDestroyed)
			return
		GuiControl, % this.GUINum ":Show",% this.hwnd
	}
	
	/*
	Function: Hide
	Hides the control if it was previously visible.
	*/
	Hide()
	{
		if(CGUI.GUIList[this.GUINum].IsDestroyed)
			return
		GuiControl, % this.GUINum ":Hide",% this.hwnd
	}
	
	/*
	Function: Enable
	Enables the control if it was previously diisabled.
	*/
	Enable()
	{
		GuiControl, % this.GUINum ":Enable",% this.hwnd
	}
	
	/*
	Function: Disable
	Disables the control if it was previously enabled.
	*/
	Disable()
	{
		GuiControl, % this.GUINum ":Disable",% this.hwnd
	}
	
	/*
	Function: Focus
	Sets the focus to this control.
	*/
	Focus()
	{
		if(CGUI.GUIList[this.GUINum].IsDestroyed)
			return
		ControlFocus,,% "ahk_id " this.hwnd
	}
	;~ Font(Options, Font="")
	;~ {
		;~ if(CGUI.GUIList[this.GUINum].IsDestroyed)
			;~ return
		;~ Gui, % this.GUINum ":Font", %Options%, %Font%
		;~ GuiControl, % this.GUINum ":Font", % this.ClassNN
		;~ Gui, % this.GUINum ":Font", % CGUI.GUIList[this.GUINum].Font.Options, % CGUI.GUIList[this.GUINum].Font.Font ;Restore current font
	;~ }
	
	
	/*
	Validates the text value of this control by calling a <Control.Validate> event function which needs to return the validated (or same) value.
	This value is then used as text for the control if it differs.
	*/
	Validate()
	{
		output := this.CallEvent("Validate", this.Text)
		if(output.Handled && output.Result != this.Text)
			this.Text := output.result
	}
	/*
	Function: RegisterEvent
	Assigns (or unassigns) a function to a specific event of this control so that the function will be called when the event occurs.
	This is normally not necessary because functions in the GUI class with the name ControlName_EventName()
	will be called automatically without needing to be registered. However this can be useful if you want to handle
	multiple events with a single function, e.g. for a group of radio controls. Right now only one registered function per event
	is supported, let me know if you need more.
	
	Parameters:
		Type - The event name for which the function should be registered. If a control normally calls "GUI.ControlName_TextChanged()", specify "TextChanged" here.
		FunctionName - The name of the function specified in the window class that is supposed to handle the event. Specify only the name of the function, skip the class.
	*/
	RegisterEvent(Type, FunctionName)
	{
		if(FunctionName)
		{
			;Make sure function name is valid (or tell the developer about it)
			if(CGUI_Assert(IsFunc(this[FunctionName]) || IsFunc( (CGUI.GUIList[this.GUINum])[FunctionName]), "Invalid function name passed to CControl.RegisterEvent()"), -2)
				this._.RegisteredEvents[Type] := FunctionName
		}
		else
			this._.RegisteredEvents.Remove(Type)
	}
	
	/*
	Calls an event with a specified name by looking up a possibly registered event handling function or calling the function with the default name.
	Returns an object with Handled and Result keys, where Handled indicates if the function was successfully called and Result is the return value of the function.
	*/
	CallEvent(Name, Params*)
	{
		if(CGUI.GUIList[this.GUINum].IsDestroyed)
			return
		if(this._.RegisteredEvents.HasKey(Name))
		{
			if(IsFunc(this[this._.RegisteredEvents[Name]]))
				return {Handled : true, Result : this[this._.RegisteredEvents[Name]](CGUI.GUIList[this.GUINum], Params*)}
			else if(IsFunc( (CGUI.GUIList[this.GUINum])[this._.RegisteredEvents[Name]]))
				return {Handled : true, Result : (CGUI.GUIList[this.GUINum])[this._.RegisteredEvents[Name]](Params*)}
		}
		else if(IsFunc(this[Name]))
			return {Handled : true, Result : this[Name](CGUI.GUIList[this.GUINum], Params*)}
		else if(IsFunc((CGUI.GUIList[this.GUINum])[this.Name "_" Name]))
			return {Handled : true, Result : (CGUI.GUIList[this.GUINum])[this.Name "_" Name](Params*)}
		else
			return {Handled : false}
	}
	/*
	Changes the state of controls assigned to an item of another control, making them (in)visible or (de)activating them.
	The parameters are the previously selected item object (containing a controls array of controls assigned to it and the new selected item object.
	*/
	ProcessSubControlState(From, To)
	{
		if(From != To && !CGUI.GUIList[this.GUINum].IsDestroyed)
		{
			if(From)
				for index, Control in From.Controls
				{
					if(Control._.UseEnabledState)
						Control.Disable()
					else
						Control.Hide()
				}
			if(To)
			{
				for index, Control in To.Controls
					if(Control._.UseEnabledState)
						Control.Enable()
					else
						Control.Show()
			}
		}
	}
	
	IsValidatableControlType()
	{
		return CGUI_IndexOf(["Edit", "ComboBox"], this.Type)
	}
	/*
	Property: x
	x-Position of the control.
	
	Property: y
	y-Position of the control.
	
	Property: width
	Width of the control.
	
	Property: height
	Height of the control.
	
	Property: Position
	An object containing the x and y values. They can not be set separately through this object, only both at once.
	
	Property: Size
	An object containing the width and height values. They can not be set separately through this object, only both at once.
	
	Property: Text
	The text of the control. Some controls don't support this property.
	
	Property: ClassNN
	The control class together with a number identify the control.
	
	Property: Enabled
	Determines wether this control can be interacted with.
	
	Property: Visible
	Determines wether this control is currently visible.
	
	Property: Style
	The style of the control.
	
	Property: ExStyle
	The extended style of the control.
	
	Property: Focused
	True if the control currently has the focus. It's also possible to focus it by setting this value to true.
	
	Property: Tooltip
	If a text is set for this value, this control will show a tooltip when the mouse hovers over it.
	Text and Picture controls require that you define a g-label for them to make this work.
	
	Property: Menu
	If this variable contains an instance of <CMenu> and there is no ContextMenu() event handler for this control, this menu will be shown when the user right clicks on this control or presses the AppsKey while this control has focus.
	
	Property: Left
	The control left-aligns its text. This is the default setting.
	
	Property: Center
	The control center-aligns its text.
	
	Property: Right
	The control right-aligns its text.
	
	Property: TabStop
	If set to false, this control will not receive the focus when pressing tab to cycle through all controls.
	
	Property: Wrap
	If enabled, the control will use word-wrapping for its text.
	
	Property: HScroll
	Provides a horizontal scroll bar for this control if appropriate.
	
	Property: VScroll
	Provides a vertical scroll bar for this control if appropriate.
	
	Property: BackgroundTrans
	Uses a transparent background, which allows any control that lies behind a Text, Picture, or GroupBox control to show through.
	
	Property: Background
	If disable, the control uses the standard background color rather than the one set by the CGUI.Color() function.
	
	Property: Border
	Provides a thin-line border around the control.
	
	Property: hParentControl
	If this control is a subcontrol of another control, this variable contains the window handle of the parent control.
	
	Property: DisableNotifications
	If true, this control will not call any of its notification functions. This is useful when the controls of a window are first created and change handlers should not be called.
	*/
	__Get(Name, Params*)
    {
        if(this.__GetEx(Result, Name, Params*) )
            return Result
    }
	
	__GetEx(ByRef Result, Name, Params*)
    {
		Handled := false
		if Name not in base,_,GUINum
			if(!CGUI.GUIList[this.GUINum].IsDestroyed)
			{
				DetectHidden := A_DetectHiddenWindows
				DetectHiddenWindows, On
				Handled := true
				if(Name = "Text")
					GuiControlGet, Result,% this.GuiNum ":", % this.ClassNN
					;~ ControlGetText, Result,, % "ahk_id " this.hwnd
				else if(Name = "GUI")
					Result := CGUI.GUIList[this.GUINum]
				else if(Name = "x" || Name = "y"  || Name = "width" || Name = "height")
				{
					ControlGetPos, x,y,width,height,,% "ahk_id " this.hwnd
					Result := %Name%
				}
				else if(Name = "Position")
				{
					ControlGetPos, x,y,,,,% "ahk_id " this.hwnd
					Result := {x:x, y:y}
				}
				else if(Name = "Size")
				{
					ControlGetPos,,,width,height,,% "ahk_id " this.hwnd
					Result := {width:width, height:height}
				}
				else if(Name = "ClassNN")
				{
					if(this._.ClassNN != "" && this.hwnd && WinExist("ahk_class " this._.ClassNN) = this.hwnd) ;Check for cached Result first
						return this._.ClassNN
					else
					{
						win := DllCall("GetParent", "PTR", this.hwnd, "PTR")
						WinGet ctrlList, ControlList, ahk_id %win%
						Loop Parse, ctrlList, `n
						{
							ControlGet hwnd, Hwnd, , %A_LoopField%, ahk_id %win%
							if(hwnd=this.hwnd)
							{
								Result := A_LoopField
								break
							}
						}
						this._.ClassNN := Result
					}
				}
				else if(Name = "Enabled")
					ControlGet, Result, Enabled,,,% "ahk_id " this.hwnd
				else if(Name = "Visible")
					ControlGet, Result, Visible,,,% "ahk_id " this.hwnd
				else if(Name = "Style")
					ControlGet, Result, Style,,,% "ahk_id " this.hwnd
				else if(Name = "ExStyle")
					ControlGet, Result, ExStyle,,,% "ahk_id " this.hwnd
				else if(Name = "Focused")
				{
					ControlGetFocus, Result, % "ahk_id " CGUI.GUIList[this.GUINum].hwnd
					ControlGet, Result, Hwnd,, %Result%, % "ahk_id " CGUI.GUIList[this.GUINum].hwnd
					Result := Result = this.hwnd
				}
				else if(key := {Left : "Left", Center : "Center", Right : "Right", TabStop : "TabStop", Wrap : "Wrap", HScroll : "HScroll", VScroll : "VScroll", BackgroundTrans : "BackgroundTrans", Background : "Background", Border : "Border"}[Name])
					GuiControl, % this.GUINum ":", (Result ? "+" : "-") key
				else if(Name = "Color")
					GuiControl, % this.GUINum ":", "+c" Result
				else if(this._.HasKey("ControlStyles") && Style := this._.ControlStyles[Name])
				{
					if(SubStr(Style, 1,1) = "-")
					{
						Negate := true
						Style := SubStr(Style, 2)
					}
					ControlGet, Result, Style,,,% "ahk_id " this.hwnd
					Result := Result & Style > 0
					if(Negate)
						Result := !Result
				}
				else if(this._.HasKey("ControlExStyles") && ExStyle := this._.ControlExStyles[Name])
				{
					if(SubStr(ExStyle, 1,1) = "-")
					{
						Negate := true
						ExStyle := SubStr(ExStyle, 2)
					}
					ControlGet, Result, ExStyle,,,% "ahk_id " this.hwnd
					Result := Result & ExStyle > 0
					if(Negate)
						Result := !Result
				}
				else if(Name = "Tooltip")
					Result := this._.Tooltip
				else
					Handled := false
				if(!DetectHidden)
					DetectHiddenWindows, Off
			}
		return Handled
    }
	
    __Set(Name, Params*)
    {
		if(Name != "_" && !CGUI.GUIList[this.GUINum].IsDestroyed)
		{
			;Fix completely weird __Set behavior. If one tries to assign a value to a sub item, it doesn't call __Get for each sub item but __Set with the subitems as parameters.
			Value := Params.Remove()
			if(Params.MaxIndex())
			{
				Params.Insert(1, Name)
				Name := Params.Remove()
				return (this[Params*])[Name] := Value
			}
			DetectHidden := A_DetectHiddenWindows
			DetectHiddenWindows, On
			Handled := true
			if(Name = "Text")
				GuiControl, % this.GUINum ":",% this.ClassNN, %Value% ;Use GuiControl because of line endings
			else if(Name = "x" || Name = "y"  || Name = "width" || Name = "height")
				ControlMove,, % (Name = "x" ? Value : ""),% (Name = "y" ? Value : ""),% (Name = "width" ? Value : ""),% (Name = "height" ? Value : ""),% "ahk_id " this.hwnd
			else if(Name = "Position")
				ControlMove,, % Value.x,% Value.y,,,% "ahk_id " this.hwnd
			else if(Name = "Size")
				ControlMove,, % Value.width,% Value.height,% "ahk_id " this.hwnd
			else if(Name = "Enabled" && Value)
				this.Enable()
			else if(Name = "Enabled" && !Value)
				this.Disable()
			else if(Name = "Visible" && Value)
				this.Show()
			else if(Name = "Visible" && !Value)
				this.Hide()
			else if(Name = "Style")
				Control, Style, %Value%,,,% "ahk_id " this.hwnd
			else if(Name = "ExStyle")
				Control, ExStyle, %Value%,,,% "ahk_id " this.hwnd
			else if(Name = "DisableNotifications")
				GuiControl, % this.GUINum (Value ? ":-g" : ":+gCGUI_HandleEvent" ), % this.hwnd
			else if(Name = "_") ;Prohibit setting the proxy object
				Handled := true
			else if(this._.HasKey("ControlMessageStyles") && IsObject(Style := this._.ControlMessageStyles[Name]))
			{
				State := Value ? "On" : "Off"
				SendMessage, % Style.Message, % Style[State].W, % Style[State].L, , % "ahk_id" this.hwnd
			}
			else if(this._.HasKey("ControlStyles") && Style := this._.ControlStyles[Name]) ;Generic control styles which are only of boolean type can be handled simply by a list of name<->value assignments. Prepending "-" to a value in such a list inverts the behaviour here.
			{
				if(SubStr(Style, 1,1) = "-")
				{
					Value := !Value
					Style := SubStr(Style, 2)
				}
				Style := (Value ? "+" : "-") Style
				Control, Style, %Style%,, % "ahk_id " this.hwnd
			}
			else if(this._.HasKey("ControlExStyles") && ExStyle := this._.ControlExStyles[Name])
			{
				if(SubStr(ExStyle, 1,1) = "-")
				{
					Value := !Value
					ExStyle := SubStr(ExStyle, 2)
				}
				ExStyle := (Value ? "+" : "-") ExStyle
				Control, ExStyle, %ExStyle%,, % "ahk_id " this.hwnd
			}
			else if(Name = "Tooltip") ;Thanks art http://www.autohotkey.com/forum/viewtopic.php?p=452514#452514
			{
				TThwnd := CGUI.GUIList[this.GUINum]._.TThwnd
				Guihwnd := CGUI.GUIList[this.GUINum].hwnd
				Controlhwnd := [this.hwnd]
				if(this.type = "ComboBox") ;'ComboBox' = Drop-Down button + Edit
				{
					VarSetCapacity(CBBINFO, 52, 0)
					NumPut(52, CBBINFO,0, "UINT")
					result := DllCall("GetComboBoxInfo", "UInt", Controlhwnd[1], "PTR", &CBBINFO)
					Controlhwnd.Insert(Numget(CBBINFO,44))
				}
				else if(this.type = "ListView")
					Controlhwnd.Insert(DllCall("SendMessage", "UInt", Controlhwnd[1], "UInt", 0x101f, "PTR", 0, "PTR", 0))
				; - 'Text' and 'Picture' Controls requires a g-label to be defined.
				if(!TThwnd){
					; - 'ListView' = ListView + Header       (Get hWnd of the 'Header' control using "ControlGet" command).
					TThwnd := CGUI.GUIList[this.GUINum]._.TThwnd := DllCall("CreateWindowEx","Uint",0,"Str","TOOLTIPS_CLASS32","Uint",0,"Uint",2147483648 | 3,"Uint",-2147483648
									,"Uint",-2147483648,"Uint",-2147483648,"Uint",-2147483648,"Ptr",GuiHwnd,"Uint",0,"Uint",0,"Uint",0, "PTR")
					DllCall("uxtheme\SetWindowTheme","Ptr",TThwnd,"Ptr",0,"UintP",0)   ; TTM_SETWINDOWTHEME
				}
				for index, chwnd in Controlhwnd
				{
					Varsetcapacity(TInfo,44,0), Numput(44,TInfo), Numput(1|16,TInfo,4), Numput(GuiHwnd,TInfo,8), Numput(chwnd,TInfo,12), Numput(&Value,TInfo,36)
					!this._.Tooltip   ? (DllCall("SendMessage",Ptr,TThwnd,"Uint",1028,Ptr,0,Ptr,&TInfo,Ptr))         ; TTM_ADDTOOL = 1028 (used to add a tool, and assign it to a control)
					. (DllCall("SendMessage",Ptr,TThwnd,"Uint",1048,Ptr,0,Ptr,A_ScreenWidth))      ; TTM_SETMAXTIPWIDTH = 1048 (This one allows the use of multiline tooltips)
					DllCall("SendMessage",Ptr,TThwnd,"UInt",(A_IsUnicode ? 0x439 : 0x40c),Ptr,0,Ptr,&TInfo,Ptr)   ; TTM_UPDATETIPTEXT (OLD_MSG=1036) (used to adjust the text of a tip)
				}
			}
			else
				Handled := false
			if(!DetectHidden)
				DetectHiddenWindows, Off
			if(Handled)
				return Value
		}
    }
	
	/*
	Event: Introduction
	To handle control events you need to create a function with this naming scheme in your window class: ControlName_EventName(params)
	The parameters depend on the event and there may not be params at all in some cases.
	Additionally it is required to create a label with this naming scheme: GUIName_ControlName
	GUIName is the name of the window class that extends CGUI. The label simply needs to call CGUI.HandleEvent().
	For better readability labels may be chained since they all execute the same code.
	Instead of using ControlName_EventName() you may also call <CControl.RegisterEvent> on a control instance to register a different event function name.
	
	Event: FocusEnter
	Invoked when the control receives keyboard focus. This event does not require that the control has a matching g-label since it is implemented through window messages.
	This event is not supported for all input-capable controls unfortunately.
	
	Event: FocusLeave
	Invoked when the control loses keyboard focus. This event does not require that the control has a matching g-label since it is implemented through window messages.
	This event is not supported for all input-capable controls unfortunately.
	
	Event: ContextMenu
	Invoked when the user right clicks on the control or presses the AppsKey while this control has focus. If this event is not handled a static context menu can be shown by setting the Menu variable of this control to an instance of <CMenu>.
	
	Event: Validate
	Invoked when the control is asked to validate its (textual) contents. This event is only valid for controls containing text, which are only Edit and ComboBox controls as of now.
	
	Parameters:
		Text - The current text of the control that should be validated. The function can return this value if it is valid or another valid value.
	*/
	
	/*
	Class: CImageListManager
	This class is used internally to manage the ImageLists of ListView/TreeView/Tab controls. Does not need to be used directly.
	*/
	Class CImageListManager
	{
		__New(GUINum, hwnd)
		{
			this.Insert("_", {})
			this._.GUINum := GUINum
			this._.hwnd := hwnd
			this._.IconList := {}
		}
		SetIcon(ID, PathOrhBitmap, IconNumber)
		{
			GUI := CGUI.GUIList[this._.GUINum]
			Control := GUI.Controls[this._.hwnd]
			GUI, % this._.GUINum ":Default"
			if(Control.Type = "ListView")
				GUI, ListView, % Control.ClassNN
			else if(Control.Type = "TreeView")
				Gui, TreeView, % Control.ClassNN
			if(!this._.IconList.SmallIL_ID)
			{
				if(Control.Type = "ListView") ;Listview also has large icons
				{
					this._.IconList.LargeIL_ID := IL_Create(5,5,1)
					LV_SetImageList(this._.IconList.LargeIL_ID)
				}
				this._.IconList.SmallIL_ID := IL_Create(5,5,0)
				if(Control.Type = "ListView")
					LV_SetImageList(this._.IconList.SmallIL_ID)
				else if(Control.Type = "TreeView")
				{
					SendMessage, 0x1109, 0, this._.IconList.SmallIL_ID, % Control.ClassNN, % "ahk_id " GUI.hwnd  ; 0x1109 is TVM_SETIMAGELIST
					if ErrorLevel  ; The TreeView had a previous ImageList.
						IL_Destroy(ErrorLevel)
				}
				else if(Control.Type = "Tab")
				{
					SendMessage, 0x1303, 0, this._.IconList.SmallIL_ID, % Control.ClassNN, % "ahk_id " GUI.hwnd  ; 0x1109 is TVM_SETIMAGELIST
				}
			}
			if(FileExist(PathorhBitmap))
			{
				Loop % this._.IconList.MaxIndex() ;IDs and paths and whatnot are identical in both lists so one is enough here
					if(this._.IconList[A_Index].Path = PathorhBitmap && this._.IconList[A_Index].IconNumber = IconNumber)
					{
						Icon := this._.IconList[A_Index]
						break
					}
				
				if(!Icon)
				{
					IID := IL_Add(this._.IconList.SmallIL_ID, PathorhBitmap, IconNumber, 1)
					if(Control.Type = "ListView")
						IID := IL_Add(this._.IconList.LargeIL_ID, PathorhBitmap, IconNumber, 1)
					this._.IconList.Insert(Icon := {Path : PathorhBitmap, IconNumber : IconNumber, ID : IID})
				}
			}
			else
			{
				Loop % this._.IconList.MaxIndex() ;IDs and paths and whatnot are identical in both lists so one is enough here
					if(this._.IconList[A_Index].Path = PathorhBitmap && this._.IconList[A_Index].IconNumber = IconNumber)
					{
						Icon := this._.IconList[A_Index]
						break
					}
				if(!Icon)
				{
					IID := DllCall("ImageList_ReplaceIcon", "Ptr", this._.IconList.SmallIL_ID, Int, -1, "Ptr", PathorhBitmap) + 1
					if(Control.Type = "ListView")
						IID := DllCall("ImageList_ReplaceIcon", "Ptr", this._.IconList.LargeIL_ID, Int, -1, "Ptr", PathorhBitmap) + 1
					this._.IconList.Insert(Icon := {Path : PathorhBitmap, IconNumber : 1, ID : IID})
				}
			}
			if(Control.Type = "ListView")
				LV_Modify(ID, "Icon" (Icon ? Icon.ID : -1))
			else if(Control.Type = "TreeView")
				TV_Modify(ID, "Icon" (Icon ? Icon.ID : -1))
			else if(Control.Type = "Tab")
			{
				VarSetCapacity(TCITEM, 20 + 2 * A_PtrSize, 0)
				NumPut(2, TCITEM, 0, "UInt") ;State mask TCIF_IMAGE
				NumPut(Icon.ID - 1, TCITEM, 16 + A_PtrSize, "UInt") ;ID of icon in image list
				SendMessage, 0x1306, ID-1, &TCITEM, % Control.ClassNN, % "ahk_id " GUI.hwnd ;TCM_SETITEM
			}
		}
	}
}

#include <CTextControl>
#include <CEditControl>
#include <CButtonControl>
#include <CCheckboxControl>
#include <CChoiceControl>
#include <CListViewControl>
#include <CPictureControl>
#include <CGroupBoxControl>
#include <CStatusBarControl>
#include <CTreeViewControl>
#include <CTabControl>
#include <CProgressControl>
#include <CSliderControl>
#include <CHotkeyControl>
#include <CActiveXControl>
#include <CSysLinkControl>
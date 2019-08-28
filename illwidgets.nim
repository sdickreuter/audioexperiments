import illwill
import strutils

## Function for padding a string with whitespace on both sides
proc generate_centered_string[T](thing: T, width: int): string =
  var 
    s: string = $thing
  if len(s) < width:
    result = $thing
    result = result & spaces(int(width/2) - int(len(result)/2)+1)
    result = align(result, width )
  else:
    result = s

type
  ## Basic Object 
  UIObject = ref object of RootObj
    x,y,width: int
    focus: bool

## Set Focus to UIObject, changes appearance and relay key input to this object
proc setFocus*(obj: UIObject, focus: bool) =
  obj.focus = focus

## Handle key input
method handleinput*(obj: UIObject, key: Key) {.base.} =
  quit("please overwrite method handleinput")

## Draw UIObject
method draw(obj:UIObject, tb: var TerminalBuffer) {.base.} =
  quit("please overwrite method draw")

type
  ## Widget for setting an integer with the left/right keys 
  ## and displaying a nice slider as indication
  Slider* = ref object of UIObject
    min*, max*, value*: int
    step* : int
    label* : string 
    onchange* : proc(slider: Slider)

## Dummy onchange function
proc onchange(slider: Slider) =
  discard

proc newSlider*(min, max, step, value: int; x,y,width: int,label=""): Slider =
  result = new(Slider)
  result.min = min
  result.max = max
  result.step = step
  result.value = value
  result.x = x
  result.y = y
  result. width = width
  result.label = label
  result.focus = false
  ## Change this to your own proc after newSlider if you want
  result.onchange = onchange

proc inc*(slider: Slider) =
  slider.value += slider.step
  if slider.value > slider.max:
    slider.value = slider.max

proc dec*(slider: Slider) =
  slider.value -= slider.step
  if slider.value < slider.min:
    slider.value = slider.min

method handleinput*(slider: Slider, key: Key) =
  case key  
  of Key.Right:
    slider.inc()
    slider.onchange(slider)
  of Key.Left:
    slider.dec()
    slider.onchange(slider)
  else:
    discard

method draw*(slider:Slider, tb: var TerminalBuffer) =
  var 
    pos: int
    numberstr: string

  tb.setBackgroundColor(bgBlack)
  tb.setForegroundColor(fgWhite, true)
  tb.drawRect(slider.x, slider.y, slider.x+slider.width+1, slider.y+2,doubleStyle=true)
  pos = int( ( (slider.value - slider.min) / (slider.max - slider.min) ) * float(slider.width))
  tb.setForegroundColor(fgNone)
  
  numberstr = generate_centered_string(slider.value,slider.width)

  if slider.focus:
    tb.setBackgroundColor(bgBlue)
  else:
    tb.setBackgroundColor(bgYellow)
 
  for i in 0..<pos:
    tb.write(slider.x+1+i, slider.y+1,$numberstr[i]) #█░
  
  tb.setBackgroundColor(bgBlack)
  tb.setForegroundColor(fgWhite)
  for i in pos..<slider.width:
    tb.write(slider.x+1+i, slider.y+1,$numberstr[i])

  tb.setBackgroundColor(bgBlack)
  tb.setForegroundColor(fgWhite)
  tb.write(slider.x+1, slider.y,slider.label)


type
  ToggleButton* = ref object of UIObject
    toggled*: bool
    label* : string 
    ontoggle* : proc(but: ToggleButton)

proc ontoggle(but: ToggleButton) =
  discard


proc newToggleButton*(toggled: bool; x,y,width: int; label=""): ToggleButton =
  result = new(ToggleButton)
  result.toggled = toggled
  result.x = x
  result.y = y
  result. width = width
  result.label = label
  result.focus = false
  result.ontoggle = ontoggle

proc toggle*(but: ToggleButton) =
  if but.toggled:
    but.toggled = false
  else:
    but.toggled = true
  but.ontoggle(but)

method handleinput*(but: ToggleButton, key: Key) =
  case key  
  of Key.Enter:
    but.toggle()
  else:
    discard

method draw*(but: ToggleButton, tb: var TerminalBuffer) =
  var 
    labelstr: string

  tb.setBackgroundColor(bgBlack)
  tb.setForegroundColor(fgWhite, true)
  tb.drawRect(but.x, but.y, but.x+but.width+1, but.y+2,doubleStyle=true)

  labelstr = generate_centered_string(but.label,but.width)

  if but.toggled:
    tb.setForegroundColor(fgGreen)
  else:
    tb.setForegroundColor(fgWhite)
   

  if but.focus:
    tb.setBackgroundColor(bgBlue)
  else:
    tb.setBackgroundColor(bgBlack)
 
  for i in 0..<but.width:
    tb.write(but.x+1+i, but.y+1,$labelstr[i])





type
  Button* = ref object of UIObject
    label* : string 
    onpress* : proc(but: Button)

proc onpress(but: Button) =
  discard


proc newButton*(x,y,width: int; label=""): Button =
  result = new(Button)
  result.x = x
  result.y = y
  result. width = width
  result.label = label
  result.focus = false
  result.onpress = onpress

method handleinput*(but: Button, key: Key) =
  case key  
  of Key.Enter:
    but.onpress(but)
  else:
    discard

method draw*(but: Button, tb: var TerminalBuffer) =
  var 
    labelstr: string

  tb.setBackgroundColor(bgBlack)
  tb.setForegroundColor(fgWhite, true)
  tb.drawRect(but.x, but.y, but.x+but.width+1, but.y+2,doubleStyle=true)

  labelstr = generate_centered_string(but.label,but.width)

  tb.setForegroundColor(fgWhite)

  if but.focus:
    tb.setBackgroundColor(bgBlue)
  else:
    tb.setBackgroundColor(bgBlack)
 
  for i in 0..<but.width:
    tb.write(but.x+1+i, but.y+1,$labelstr[i])



  

type
  UIGroup* = ref object
    members : seq[UIObject]
    focus_index: int

proc newUIGroup*(): UIGroup =
  result = new(UIGroup)
  result.members = @[]
  result.focus_index = 0

proc add*(g: UIGroup, obj: UIObject) =
  g.members.add(obj)

proc unfocusall*(g: UIGroup) =
  for obj in g.members:
    obj.setFocus(false)

proc setFocusto*(g: UIGroup, index: int) =
  if index >= low(g.members) and index <= high(g.members):
    g.unfocusall()
    g.members[index].setFocus(true)
    g.focus_index = index

proc incFocus*(g: UIGroup) =
  var index: int
  index = g.focus_index + 1
  if index > high(g.members):
    index = low(g.members) 
  g.unfocusall()
  g.members[index].setFocus(true)
  g.focus_index = index

proc decFocus*(g: UIGroup) =
  var index: int  
  index = g.focus_index - 1
  if index < low(g.members):
    index = high(g.members)
  g.unfocusall()
  g.members[index].setFocus(true)
  g.focus_index = index

proc handleinput*(g: UIGroup, key: Key) =
  case key 
  of Key.Up:
    g.decFocus()
  of Key.Down:
    g.incFocus()
  else:
    for obj in g.members:
      if obj.focus:
        obj.handleinput(key)

proc draw*(tb: var TerminalBuffer, g: UIGroup) =
  for obj in g.members:
    obj.draw(tb)

# Test & show the new high level wrapper

import ui
import audiotypes
import audiogenerator
import audioplayer


proc main*() =
  var mainwin: Window

  
  mainwin = newWindow("Binaural Audio Generator", 640, 480, true)
  mainwin.margined = true
  
  mainwin.onClosing = (proc (): bool = return true)

  let box = newVerticalBox(true)
  mainwin.setChild(box)
  let hbox = newHorizontalBox(true)
  box.add(hbox, true)
  var group = newGroup("Basic Controls")
  group.margined = true
  hbox.add(group, false)
  var inner = newVerticalBox(true)
  group.child = inner
  inner.add newButton("Button")
  inner.add newCheckbox("Checkbox")
  add(inner, newEntry("Entry"))
  add(inner, newLabel("Label"))
  inner.add newHorizontalSeparator()
  #inner.add newDatePicker()
  #inner.add newTimePicker()
  #inner.add newDateTimePicker()
  #inner.add newFontButton()
  #inner.add newColorButton()
  var inner2 = newVerticalBox()
  inner2.padded = true
  hbox.add inner2
  group = newGroup("Numbers", true)
  inner2.add group
  inner = newVerticalBox(true)
  group.child = inner


  var spinbox: Spinbox
  var slider: Slider
  var progressbar: ProgressBar

  proc update(value: int) =
    spinbox.value = value
    slider.value = value
    progressBar.value = value

  spinbox = newSpinbox(0, 100, update)
  inner.add spinbox
  slider = newSlider(0, 100, update)
  inner.add slider
  progressbar = newProgressBar()
  inner.add progressbar

  group = newGroup("Lists")
  group.margined = true
  inner2.add group

  inner = newVerticalBox()
  inner.padded = true
  group.child = inner
  var cbox = newCombobox()
  cbox.add "Combobox Item 1"
  cbox.add "Combobox Item 2"
  cbox.add "Combobox Item 3"
  inner.add cbox
  var ecbox = newEditableCombobox()
  ecbox.add "Editable Item 1"
  ecbox.add "Editable Item 2"
  ecbox.add "Editable Item 3"
  inner.add ecbox
  var rb = newRadioButtons()
  rb.add "Radio ButtoIn 1"
  rb.add "Radio Button 2"
  rb.add "Radio Button 3"
  inner.add rb, true
  var tab = newTab()
  tab.add "Page 1", newHorizontalBox()
  tab.add "Page 2", newHorizontalBox()
  tab.add "Page 3", newHorizontalBox()
  inner2.add tab, true
  show(mainwin)
  mainLoop()

init()
main()

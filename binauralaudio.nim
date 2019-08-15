# Test & show the new high level wrapper

import ui, os
import audiotypes
import audiogenerator
import audioplayer


proc main*() =
  var mainwin: Window

  
  mainwin = newWindow("Binaural Audio Generator", 300, 180, false)
  mainwin.margined = true

  mainwin.onClosing = (proc (): bool = 
    stopThread()
    #terminateThread()
    terminatestream()
    return true)

  initstream()
  startThread()
  startstream()


  let box = newVerticalBox(true)
  mainwin.setChild(box)
  

  let buttonbox = newHorizontalBox(true)
  box.add(buttonbox)
  

  proc onstartbutton() =
    echo("start pressed")
    #startThread()
    var msg = ControlMessage(kind: setactive)
    controlchannel.send(msg)

  let startbutton = newButton("Start",onstartbutton)
  buttonbox.add(startbutton)

  proc onstopbutton() =
    echo("stop pressed")
    #stopThread()
    var msg = ControlMessage(kind: setinactive)
    controlchannel.send(msg)

  let stopbutton = newButton("Stop",onstopbutton)
  buttonbox.add(stopbutton)



  let freqbox = newHorizontalBox(true)
  box.add(freqbox)

  var freqspinbox: Spinbox
  var detunespinbox: Spinbox

  proc updatefreqs() = 
    var msg = ControlMessage(kind: rightfreq)
    msg.rfreq = float(freqspinbox.value)
    controlchannel.send(msg)
    msg = ControlMessage(kind: leftfreq)
    msg.lfreq = float(freqspinbox.value+detunespinbox.value)
    controlchannel.send(msg)


  proc update_freqspinbox(value: int) =
    freqspinbox.value = value
    updatefreqs()

  freqspinbox = newSpinbox(10, 5000, update_freqspinbox)
  freqspinbox.value = 440
  freqbox.add(newLabel("frequency:"))
  freqbox.add(freqspinbox)

  let detunebox = newHorizontalBox(true)
  box.add(detunebox)


  proc update_detunespinbox(value: int) =
    detunespinbox.value = value
    updatefreqs()

  detunespinbox = newSpinbox(-100, 100, update_detunespinbox)
  detunespinbox.value = 0
  detunebox.add(newLabel("detune:"))
  detunebox.add(detunespinbox)



  let volumebox = newHorizontalBox(false)
  box.add(volumebox)

  var volslider: Slider

  proc update_volslider(value: int) =
    volslider.value = value
    var msg = ControlMessage(kind: rightvol)
    msg.rvol = float(volslider.value)/100
    controlchannel.send(msg)
    msg = ControlMessage(kind: leftvol)
    msg.lvol = float(volslider.value)/100
    controlchannel.send(msg)

  volslider = newSlider(0, 100, update_volslider)
  volslider.value = 30
  volumebox.add(newLabel("volume:"))
  volumebox.add(volslider,true)


  # let hbox = newHorizontalBox(true)
  # box.add(hbox, true)
  # var group = newGroup("Basic Controls")
  # group.margined = true
  # hbox.add(group, false)
  # var inner = newVerticalBox(true)
  # group.child = inner
  # inner.add newButton("Button")
  # inner.add newCheckbox("Checkbox")
  # add(inner, newEntry("Entry"))
  # add(inner, newLabel("Label"))
  # inner.add newHorizontalSeparator()
  # #inner.add newDatePicker()
  # #inner.add newTimePicker()
  # #inner.add newDateTimePicker()
  # #inner.add newFontButton()
  # #inner.add newColorButton()
  # var inner2 = newVerticalBox()
  # inner2.padded = true
  # hbox.add inner2
  # group = newGroup("Numbers", true)
  # inner2.add group
  # inner = newVerticalBox(true)
  # group.child = inner


  # var spinbox: Spinbox
  # var slider: Slider
  # var progressbar: ProgressBar

  # proc update(value: int) =
  #   spinbox.value = value
  #   slider.value = value
  #   progressBar.value = value

  # spinbox = newSpinbox(0, 100, update)
  # inner.add spinbox
  # slider = newSlider(0, 100, update)
  # inner.add slider
  # progressbar = newProgressBar()
  # inner.add progressbar

  # group = newGroup("Lists")
  # group.margined = true
  # inner2.add group

  # inner = newVerticalBox()
  # inner.padded = true
  # group.child = inner
  # var cbox = newCombobox()
  # cbox.add "Combobox Item 1"
  # cbox.add "Combobox Item 2"
  # cbox.add "Combobox Item 3"
  # inner.add cbox
  # var ecbox = newEditableCombobox()
  # ecbox.add "Editable Item 1"
  # ecbox.add "Editable Item 2"
  # ecbox.add "Editable Item 3"
  # inner.add ecbox
  # var rb = newRadioButtons()
  # rb.add "Radio ButtoIn 1"
  # rb.add "Radio Button 2"
  # rb.add "Radio Button 3"
  # inner.add rb, true
  # var tab = newTab()
  # tab.add "Page 1", newHorizontalBox()
  # tab.add "Page 2", newHorizontalBox()
  # tab.add "Page 3", newHorizontalBox()
  # inner2.add tab, true
  show(mainwin)
  mainLoop()

init()
main()

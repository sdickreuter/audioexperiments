## Module for generating binaural audio in a separate thread an feeding 
## it through a channel to audioplayer.nim
##

import audiotypes
import math


var
  ## Thread for generating audio
  generatorthread: Thread[void]

## 
proc runthread {.thread.} =
  var 
    ## buffer for left channel
    leftdata : array[framesPerBuffer, float32]
    ## buffer for right channel
    rightdata : array[framesPerBuffer, float32]
    ## variable for checking of success of received control message
    success: bool
    ## variable for storing control message
    msg : ControlMessage 
    ## if thread is generating audio data or just silence
    active: bool = false
    ## special object for holding parameters for audio generation
    params: GeneratorParams
    ## x-variables for the sinus functions for sound generation
    lx, rx: float32 = 0


  ## init params
  params = newGeneratorParams(leftfreq=440,rightfreq=440,leftvol=0.1,rightvol=0.1)

  ## main loop
  while true:
    (success, msg)= controlchannel.tryRecv()
    if success:
      case msg.kind
      of leftfreq:
        params.leftfreq.set(msg.lfreq)
      of rightfreq:
        params.rightfreq.set(msg.rfreq)
      of leftvol:
        params.leftvol.set(msg.lvol)
      of rightvol:
        params.rightvol.set(msg.rvol)
      of setactive:
        active = true
        params.fade.set(1.0)
      of setinactive:
        #active = false
        params.fade.set(0.0)
      of terminate:
        audiochannel.send(AudioMessage(kind: amstop))
        break
    
    if audiochannel.peek() < numberofBuffers:
      if active:

        for i in 0..<framesPerBuffer: 
          ## iterate params to get updated values for the parameters
          params.iterateParams(1/float32(sampleRate))

          ## calculate new x-value
          lx += ( params.leftfreq.get()/float32(sampleRate) ) * (2*PI)
          lx = lx mod (2*PI)
          ## calculate amplitude for left channel
          leftdata[i] = sin(lx) * params.leftvol.get()*params.fade.get()

          rx += ( params.rightfreq.get()/float32(sampleRate) ) * (2*PI)
          rx = rx mod (2*PI)
          rightdata[i] = sin(rx) * params.rightvol.get()*params.fade.get()
     
        ## check for end of fade-out and disable sound generation
        if params.fade.get() < 0.000001:
          active = false

        ## send audio data to audioplayer.nim
        var msg = AudioMessage(kind: amaudio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)

      else:
        ## send silence to audioplayer.nim
        var msg = AudioMessage(kind: amsilent)
        audiochannel.send(msg)


proc stopThread* {.noconv.} =
  controlchannel.send(ControlMessage(kind: terminate))
  joinThread(generatorthread)

  
proc startThread* {.noconv.} =
  generatorthread.createThread(runthread)


# Sound test
when isMainModule:
  import audioplayer_sdl2
  import os
  
  addQuitProc(stopThread)

  InitSDL()
  echo("Audio initiated")
  startThread()
  echo("thread started")
  sleep(100)
  startAudio()
  echo("Audio started")
  sleep(50)
  controlchannel.send(ControlMessage(kind: setactive))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: leftfreq, lfreq: 880))
  sleep(3000)
  controlchannel.send(ControlMessage(kind: rightfreq, rfreq: 220))
  sleep(1000) 

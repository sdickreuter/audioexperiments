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
    x,xnu,y: float32 = 0


  ## init params
  params = newGeneratorParams(f0=440,nu=5,deltaf=20,vol=0.1)

  ## main loop
  while true:
    (success, msg)= controlchannel.tryRecv()
    if success:
      case msg.kind
      of cmf0:
        params.f0.set(msg.f0)
      of cmnu:
        params.nu.set(msg.nu)
      of cmdeltaf:
        params.deltaf.set(msg.deltaf)
      of cmvol:
        params.vol.set(msg.vol)
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

          ## calculate x-value of modulation
          xnu += params.nu.get() / float32(sampleRate) * (2*PI)
          xnu = xnu mod (2*PI)

          ## calculate new x-value
          x += ( (params.f0.get() + params.deltaf.get()*sin(xnu) ) / float32(sampleRate) ) * (2*PI)
          x = x mod (2*PI)
          
          y = sin(x) * params.vol.get()*params.fade.get()
          
          leftdata[i] = y
          rightdata[i] = y
     
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

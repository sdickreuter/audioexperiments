import audiotypes
import math

# modified from https://github.com/jlp765/seqmath
proc linspace(start, stop: int, endpoint = true): array[framesPerBuffer, float32] =
  var 
    step = float(start)
    diff: float
  if endpoint == true:
    diff = float(stop - start) / float(framesPerBuffer - 1)
  else:
    diff = float(stop - start) / float(framesPerBuffer)
  if diff < 0:
    # in case start is bigger than stop, return an empty sequence
    return 
  else:
    for i in 0..<framesPerBuffer:
      result[i] = step
      # for every element calculate new value for next iteration
      step += diff


var
  generatorthread: Thread[void]
  currentframe: int = 0


proc runthread {.thread.} =
  var 
    #t : array[framesPerBuffer, float32]
    leftdata : array[framesPerBuffer, float32]
    rightdata : array[framesPerBuffer, float32]
    success: bool
    msg : ControlMessage 
    active: bool = false
    params: GeneratorParams
    lx, rx: float32 = 0


  params = newGeneratorParams(leftfreq=440,rightfreq=440,leftvol=0.1,rightvol=0.1)


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
        currentframe = 0
        active = true
        params.fade.set(1.0)
      of setinactive:
        #active = false
        params.fade.set(0.0)
      of terminate:
        audiochannel.send(AudioMessage(kind: stop))
        break
    
    if audiochannel.peek() < numberofBuffers:
      if active:
        #t = linspace(currentframe, currentframe + int(framesPerBuffer))
        #for i in 0..<framesPerBuffer: 
        #  t[i] /= float32(sampleRate)

        for i in 0..<framesPerBuffer: 
          params.iterateParams(1/float32(sampleRate))

          lx += ( params.leftfreq.get()/float32(sampleRate) ) * (2*PI)
          lx = lx mod (2*PI)
          leftdata[i] = sin(lx) * params.leftvol.get()*params.fade.get()

          rx = ( params.rightfreq.get()/float32(sampleRate) ) * (2*PI)
          rx = rx mod (2*PI)
          rightdata[i] = sin(rx) * params.rightvol.get()*params.fade.get()

          #echo( $leftdata[i] & "  " & $rightdata[i])
          #echo( $params.leftfreq.get() & "  " & $params.rightfreq.get())
          #echo( params.leftfreq.get()*(2*PI) )
          #echo( $(lfreq) & "  " & $(rfreq))
          

        if params.fade.get() < 0.000001:
          active = false

        var msg = AudioMessage(kind: audio)
        msg.left = leftdata
        msg.right = rightdata
        audiochannel.send(msg)
        currentframe += int(framesPerBuffer)

      else:
        var msg = AudioMessage(kind: silent)
        audiochannel.send(msg)


proc stopThread* {.noconv.} =
  controlchannel.send(ControlMessage(kind: terminate))
  joinThread(generatorthread)
  #sleep(200)

  #close(audiochannel)
  
proc startThread* {.noconv.} =
  generatorthread.createThread(runthread)


# Initialize module
#addQuitProc(stopThread)
audiochannel.open()
controlchannel.open()

when isMainModule:
  import audioplayer
  import os

  initstream()
  echo("stream initiated")
  startThread()
  echo("thread started")
  startstream()
  echo("stream started")
  sleep(50)
  controlchannel.send(ControlMessage(kind: setactive))
  sleep(1000)
  controlchannel.send(ControlMessage(kind: leftfreq, lfreq: 880))
  sleep(3000)
  controlchannel.send(ControlMessage(kind: rightfreq, rfreq: 220))
  sleep(1000) 

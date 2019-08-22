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
    t : array[framesPerBuffer, float32]
    leftdata : array[framesPerBuffer, float32]
    rightdata : array[framesPerBuffer, float32]
    success: bool
    msg : ControlMessage 
    active: bool = false
    params: GeneratorParams
    lfreq: float32 = 0
    rfreq: float32 = 0
    lphase: float32 = 0
    rphase: float32 = 0
    lphase2: float32 = 0
    rphase2: float32 = 0
    lx, rx: float32 = 0


  params = newGeneratorParams(leftfreq=440,rightfreq=440,leftvol=0.1,rightvol=0.1)
  #lfreq = params.leftfreq.get()/float32(sampleRate)
  #rfreq = params.rightfreq.get()/float32(sampleRate)


  while true:
    (success, msg)= controlchannel.tryRecv()
    if success:
      case msg.kind
      of leftfreq:
        lfreq = 0
        params.leftfreq.set(msg.lfreq)
      of rightfreq:
        rfreq = 0
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
        t = linspace(currentframe, currentframe + int(framesPerBuffer))
        for i in 0..<framesPerBuffer: 
          t[i] /= float32(sampleRate)

        for i in 0..<framesPerBuffer: 
          params.iterateParams(1/float32(sampleRate))

          if params.leftfreq.fading:
            lfreq += params.leftfreq.get()/float32(sampleRate)
            lx = lfreq*(2*PI)+lphase2
            leftdata[i] = sin(lx) * params.leftvol.get()*params.fade.get()
            lphase = lx
            #if i > 1.uint64:
            #  if leftdata[i-1] > leftdata[i]:
            #    lphase = lphase+PI
            #else:
            #  if leftdata[framesPerBuffer-1] > leftdata[0]:
            #    lphase = lphase+PI
          else:
            lx = params.leftfreq.get()*(2*PI)*t[i]+lphase
            leftdata[i] = sin(lx) * params.leftvol.get()*params.fade.get()
            lphase2 = lx mod (params.leftfreq.get()*2*PI)
            #lphase2 = lx
            #if i > 1.uint64:
            #  if leftdata[i-1] > leftdata[i]:
            #    lphase2 = lphase2+PI
            #else:
            #  if leftdata[framesPerBuffer-1] > leftdata[0]:
            #    lphase2 = lphase2+PI
              

          if params.rightfreq.fading:
            rfreq += params.rightfreq.get()/float32(sampleRate)
            rx = rfreq*(2*PI)+rphase2
            rightdata[i] = sin(rx) * params.rightvol.get()*params.fade.get()
            rphase = rx
            #if i > 1.uint64:
            #  if rightdata[i-1] > rightdata[i]:
            #    rphase = rphase + PI
            #else:
            #  if rightdata[framesPerBuffer-1] > rightdata[0]:
            #    rphase = rphase + PI
          else:
            rx = params.rightfreq.get()*(2*PI)*t[i]+rphase
            rightdata[i] = sin(rx) * params.rightvol.get()*params.fade.get()
            rphase2 = rx mod (params.rightfreq.get()*2*PI)
            #if i > 1.uint64:
            #  if rightdata[i-1] > rightdata[i]:
            #    rphase2 = rphase2 + PI
            #else:
            #  if rightdata[framesPerBuffer-1] > rightdata[0]:
            #    rphase2 = rphase2 + PI

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
  sleep(100)
  controlchannel.send(ControlMessage(kind: leftfreq, lfreq: 444))
  sleep(100)
  controlchannel.send(ControlMessage(kind: rightfreq, rfreq: 880))
  sleep(100) 

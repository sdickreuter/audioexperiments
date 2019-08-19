## Author: Erik Johansson Andersson
## This file is in the public domain
## See COPYING.txt in project root for details

import portaudio as PA
import audiotypes
import audiogenerator
import locks

var
  stream: PStream


proc check(err: TError|TErrorCode) =
  if cast[TErrorCode](err) != PA.NoError:
    raise newException(Exception, $PA.GetErrorText(err))

proc terminatestream*() =
  check(PA.StopStream(stream))
  check(PA.CloseStream(stream))
  check(PA.Terminate())
  #joinThread(receiverthread)


proc stopstream*() =
  check(PA.StopStream(stream))
  #joinThread(receiverthread)

type
  TPhase = tuple[left, right: float32]


var
  phase = (left: 0.cfloat, right: 0.cfloat)

  receiverthread: Thread[void]
  L : Lock
  leftdata {.guard: L, gcsafe.} : seq[float32]
  rightdata {.guard: L, gcsafe.} : seq[float32]
  consumed : bool = false

L.initLock()

proc runthread {.thread, gcsafe.} =
  var
    running : bool = true

  while true:
        
    if consumed:
      let msg: AudioMessage = recv(audiochannel)
    #echo(msg.kind)

      case msg.kind
      of audio:
        {.locks: [L].}:
          for i in 0 ..< framesPerBuffer:
            leftdata.add(msg.left[i])
            rightdata.add(msg.right[i])
        consumed = false
      of silent:
        {.locks: [L].}:
          for i in 0 ..< framesPerBuffer:
            leftdata.add(0)
            rightdata.add(0)
        consumed = false
      of stop:
        echo("stopaudio")
        stopstream()
        break
  
var streamCallback = proc(
    inBuf, outBuf: pointer,
    framesPerBuf: culong,
    timeInfo: ptr TStreamCallbackTimeInfo,
    statusFlags: TStreamCallbackFlags,
    userData: pointer): cint {.cdecl, thread.} =
  var
    outBuf = cast[ptr array[0xffffffff, TPhase]](outBuf)
    phase = cast[ptr TPhase](userData)

  {.locks: [L].}:
    for i in 0 ..< framesPerBuf.int:
      outBuf[i] = phase[]
      phase.left = leftdata[i]
      phase.right = rightdata[i]
  consumed = true
  
  scrContinue.cint

proc initstream*() = 
  check(PA.Initialize())
  check(PA.OpenDefaultStream(cast[PStream](stream.addr),
                             numInputChannels = 0,
                             numOutputChannels = 2,
                             sampleFormat = sfFloat32,
                             sampleRate = sampleRate,
                             framesPerBuffer = framesPerBuffer,
                             streamCallback = streamCallback,
                             userData = cast[pointer](phase.addr)))

proc startstream*() =
  check(PA.StartStream(stream))
  receiverthread.createThread(runthread)
  #PA.Sleep(2000)



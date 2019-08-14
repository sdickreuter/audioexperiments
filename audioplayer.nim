## Author: Erik Johansson Andersson
## This file is in the public domain
## See COPYING.txt in project root for details

import portaudio as PA
import audiotypes
import audiogenerator


proc check(err: TError|TErrorCode) =
  if cast[TErrorCode](err) != PA.NoError:
    raise newException(Exception, $PA.GetErrorText(err))


type
  TPhase = tuple[left, right: float32]


var
  phase = (left: 0.float32, right: 0.float32)
  stream: PStream


proc terminatestream*() =
  check(PA.StopStream(stream))
  check(PA.CloseStream(stream))
  check(PA.Terminate())

proc stopstream*() =
  check(PA.StopStream(stream))


#[
var streamCallback = proc(
    inBuf, outBuf: pointer,
    framesPerBuf: culong,
    timeInfo: ptr TStreamCallbackTimeInfo,
    statusFlags: TStreamCallbackFlags,
    userData: pointer): cint {.cdecl.} =
  var
    outBuf = cast[ptr array[0xffffffff, TPhase]](outBuf)
    phase = cast[ptr TPhase](userData)
    msg : AudioMessage 
    A: array[framesPerBuffer, float32]

  msg = audiochannel.recv()
  case msg.kind
    of audio:
      #echo("got data")
      A = msg.left
      for i in 0 ..< framesPerBuf.int:
        outBuf[i] = phase[]
        phase.left = A[i]
        #phase.left = msg.left[i]
        #phase.right = msg.right[i]
    of silent:
      for i in 0 ..< framesPerBuf.int:
        outBuf[i] = phase[]

        phase.left = 0
        phase.right = 0
    of stop:
      echo("stopaudio")
      stopstream()
  
  scrContinue.cint
]#


proc streamCallback(inBuf, outBuf: pointer, framesPerBuf: culong, timeInfo: ptr TStreamCallbackTimeInfo,
    statusFlags: TStreamCallbackFlags, userData: pointer): cint {.cdecl.} =

  var
    outBuf = cast[ptr array[0xffffffff, TPhase]](outBuf)
    inBuf = cast[ptr array[0xffffffff, TPhase]](inBuf)
    phase = cast[ptr TPhase](userData)
    msg : AudioMessage 

  msg = audiochannel.recv()
  case msg.kind
    of audio:
      #echo("got data")
      for i in 0 ..< framesPerBuf.int:
        outBuf[i] = phase[]
        phase.left = msg.left[i]
        phase.right = msg.right[i]
    of silent:
      for i in 0 ..< framesPerBuf.int:
        outBuf[i] = phase[]

        phase.left = 0
        phase.right = 0
    of stop:
      echo("stopaudio")
      stopstream()

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
  #PA.Sleep(2000)



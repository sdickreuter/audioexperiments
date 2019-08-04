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
  phase = (left: 0.cfloat, right: 0.cfloat)
  stream: PStream


proc terminateaudio*() =
  check(PA.StopStream(stream))
  check(PA.CloseStream(stream))
  check(PA.Terminate())

proc stopaudio*() =
  check(PA.StopStream(stream))


var streamCallback = proc(
    inBuf, outBuf: pointer,
    framesPerBuf: culong,
    timeInfo: ptr TStreamCallbackTimeInfo,
    statusFlags: TStreamCallbackFlags,
    userData: pointer): cint {.cdecl.} =
  var
    outBuf = cast[ptr array[0xffffffff, TPhase]](outBuf)
    phase = cast[ptr TPhase](userData)
    success : bool

  var msg : AudioMessage 
  msg = audiochannel.recv()
  case msg.kind
    of audio:
      #echo("got data")
      for i in 0 ..< framesPerBuf.int:
        outBuf[i] = phase[]

        phase.left = msg.left[i]
        phase.right = msg.right[i]
    of stop:
      echo("stopaudio")
      stopaudio()
  
  scrContinue.cint

proc initaudio*() = 
  check(PA.Initialize())
  check(PA.OpenDefaultStream(cast[PStream](stream.addr),
                             numInputChannels = 0,
                             numOutputChannels = 2,
                             sampleFormat = sfFloat32,
                             sampleRate = sampleRate,
                             framesPerBuffer = framesPerBuffer,
                             streamCallback = streamCallback,
                             userData = cast[pointer](phase.addr)))

proc startaudio*() =
  check(PA.StartStream(stream))
  #PA.Sleep(2000)



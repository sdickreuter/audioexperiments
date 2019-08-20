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
  
  #from https://forum.nim-lang.org/t/3896
  sblock: Lock
  leftbuff {.guard: sblock.}: seq[float32] = newSeq[float32](50)
  ptrleftbuff {.guard: sblock.}: ptr seq[float32] = addr(leftbuff)
  rightbuff {.guard: sblock.}: seq[float32] = newSeq[float32](50)
  ptrrightbuff {.guard: sblock.}: ptr seq[float32] = addr(rightbuff)
  consumed {.guard: sblock.}: bool = true


leftbuff.add(0) # init seq
discard leftbuff.pop()
rightbuff.add(0) # init seq
discard rightbuff.pop()
initLock(sblock)


proc runthread {.thread.} =
  var
    running : bool = true

  while true:
        
    {.locks: [sblock].}: 
      if consumed:
        let msg: AudioMessage = recv(audiochannel)
        echo(msg.kind)

        case msg.kind
        of audio:
            for i in 0 ..< framesPerBuffer:
              ptrleftbuff[].add(msg.left[i])
              ptrrightbuff[].add(msg.right[i])
            consumed = false
        of silent:
            for i in 0 ..< framesPerBuffer:
              ptrleftbuff[].add(0)
              ptrrightbuff[].add(0)
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

  {.locks: [sblock].}:
    for i in 0 ..< framesPerBuf.int:
      outBuf[i] = phase[]
      phase.left = ptrleftbuff[].pop()#ptrleftbuff[][i]
      phase.right = ptrrightbuff[].pop()#ptrrightbuff[][i]
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
  echo("starting receiver")
  receiverthread.createThread(runthread)
  echo("receiver started")
  #PA.Sleep(2000)



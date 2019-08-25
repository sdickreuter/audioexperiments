
#const sampleRate* : cdouble = 44100
#const framesPerBuffer* : culong = 2048
#const numberofBuffers* : int = 5

const sampleRate* = 44100
const framesPerBuffer* = 2048
const numberofBuffers* = 5

type
  AudioMessageKind* = enum
    amaudio, amsilent, amstop

  AudioMessage* = object
    case kind*: AudioMessageKind
    of amaudio:
      left*: array[framesPerBuffer, float32]
      right*: array[framesPerBuffer, float32]
    of amsilent:
      nil
    of amstop:
      nil

  ControlMessageKind* = enum
    leftfreq, rightfreq, leftvol, rightvol, setactive, setinactive, terminate

  ControlMessage* = object
    case kind*: ControlMessageKind
    of leftfreq:
      lfreq*: float32
    of rightfreq:
      rfreq*: float32
    of leftvol:
      lvol*: float32
    of rightvol:
      rvol*: float32
    of setactive:
      nil
    of setinactive:
      nil
    of terminate:
      nil

  ## Fades a value to a target linearly over time
  ParamFader = object
    value: float32
    target: float32
    t1: float32 # time to fade
    t: float32 # actual time

  ## Holds different ParamFaders for different audio generation parameters
  GeneratorParams* = object
    leftfreq*: ParamFader
    rightfreq*: ParamFader
    leftvol*: ParamFader
    rightvol*: ParamFader
    fade*: ParamFader


proc newParamFader*(value: float32, t1: float32): ParamFader =
  result.value = value
  result.target = value
  result.t1 = t1
  result.t = 0

## Update value, calculates fade speed and fades value closer to target
proc iterate*(p: var ParamFader, dt: float32) =
  var
    tdiff: float32 = p.t1 - p.t 
    diff: float32 = p.target - p.value

  if tdiff > 0:
      p.value +=  dt*diff/tdiff
      p.t += dt
  else:
      p.value = p.target

## Set new target
proc set*(p: var ParamFader, value: float32) =
  p.target = value
  p.t = 0

proc get*(p: ParamFader): float32 =
  result = p.value


proc newGeneratorParams*(leftfreq, rightfreq, leftvol, rightvol: float32): GeneratorParams =
  result.leftfreq = newParamFader(leftfreq, 0.01)
  result.rightfreq = newParamFader(rightfreq, 0.01)
  result.leftvol = newParamFader(leftvol, 0.01)
  result.rightvol = newParamFader(rightvol, 0.01)
  result.fade = newParamFader(0, 0.01)


proc iterateParams*(p: var GeneratorParams, dt: float32) =
  p.leftfreq.iterate(dt)
  p.rightfreq.iterate(dt)
  p.leftvol.iterate(dt)
  p.rightvol.iterate(dt)
  p.fade.iterate(dt)

var 
 ## Channel used to get audio data from audiogenerator.nim to audioplayer.nim
 audiochannel*: Channel[AudioMessage]
 ## Channel used control audio generation thread in audiogenerator.nim
 controlchannel*: Channel[ControlMessage]

## Init Channels
controlchannel.open()
audiochannel.open()

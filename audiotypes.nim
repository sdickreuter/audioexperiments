
const sampleRate* : cdouble = 44100
const framesPerBuffer* : culong = 2048
const numberofBuffers* : int = 5


type
  AudioMessageKind* = enum
    audio, silent, stop

  AudioMessage* = object
    case kind*: AudioMessageKind
    of audio:
      left*: array[framesPerBuffer, float32]
      right*: array[framesPerBuffer, float32]
    of silent:
      nil
    of stop:
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


  ParamFader = object
    value: float32
    target: float32
    t1: float32
    t: float32
    fading*: bool


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
  result.fading = false

proc iterate*(p: var ParamFader, dt: float32) =
  var
    tdiff: float32 = p.t1 - p.t 
    diff: float32 = p.target - p.value

  if tdiff > 0:
      p.value +=  dt*diff/tdiff
      p.t += dt
  else:
      p.value = p.target
      p.fading = false

proc set*(p: var ParamFader, value: float32) =
  p.target = value
  p.t = 0
  p.fading = true

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


var audiochannel*: Channel[AudioMessage]
var controlchannel*: Channel[ControlMessage]

controlchannel.open()
audiochannel.open()

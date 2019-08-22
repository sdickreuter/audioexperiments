
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
    dt: int64
    t0: int64
    t: int64


  GeneratorParams* = object
    leftfreq*: ParamFader
    rightfreq*: ParamFader
    leftvol*: ParamFader
    rightvol*: ParamFader
    fade*: ParamFader


proc newParamFader*(value: float32, dt: int64): ParamFader =
  result.value = value
  result.target = value
  result.dt = dt
  result.t0 = 0
  result.t = 0

proc iterate*(p: var ParamFader) =
  var
    tdiff: int64 = p.dt - (p.t - p.t0) 
    diff: float32

  if tdiff > 0:
    diff = p.target - p.value
    if diff > 0.0001:
      p.value +=  (p.target - p.value)/float(tdiff)
      p.t += 1
    else:
      p.value = p.target


proc set*(p: var ParamFader, value: float32) =
  p.target = value
  p.t0 = p.t


proc get*(p: ParamFader): float32 =
  result = p.value


proc newGeneratorParams*(leftfreq, rightfreq, leftvol, rightvol: float32): GeneratorParams =
  result.leftfreq = newParamFader(leftfreq, int64(sampleRate*0.3))
  result.rightfreq = newParamFader(rightfreq, int64(sampleRate*0.3))
  result.leftvol = newParamFader(leftvol, int64(sampleRate*0.1))
  result.rightvol = newParamFader(rightvol, int64(sampleRate*0.1))
  result.fade = newParamFader(0, int64(sampleRate*0.1))


proc iterateParams*(p: var GeneratorParams) =
  p.leftfreq.iterate()
  p.rightfreq.iterate()
  p.leftvol.iterate()
  p.rightvol.iterate()
  p.fade.iterate()


var audiochannel*: Channel[AudioMessage]
var controlchannel*: Channel[ControlMessage]

controlchannel.open()
audiochannel.open()

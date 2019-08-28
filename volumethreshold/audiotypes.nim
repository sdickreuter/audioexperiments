
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
    cmf0, cmdeltavol, cmvol, setactive, setinactive, terminate

  ControlMessage* = object
    case kind*: ControlMessageKind
    of cmf0:
      f0*: float32
    of cmdeltavol:
      deltavol*: float32
    of cmvol:
      vol*: float32
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
    f0*: ParamFader
    deltavol*: ParamFader
    vol*: ParamFader
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


proc newGeneratorParams*(f0, deltavol, vol: float32): GeneratorParams =
  result.f0 = newParamFader(f0, 0.01)
  result.deltavol = newParamFader(deltaf, 0.01)
  result.vol = newParamFader(vol, 0.01)
  result.fade = newParamFader(0.0, 0.01)


proc iterateParams*(p: var GeneratorParams, dt: float32) =
  p.f0.iterate(dt)
  p.deltavol.iterate(dt)
  p.vol.iterate(dt)
  p.fade.iterate(dt)

var 
 ## Channel used to get audio data from audiogenerator.nim to audioplayer.nim
 audiochannel*: Channel[AudioMessage]
 ## Channel used control audio generation thread in audiogenerator.nim
 controlchannel*: Channel[ControlMessage]

## Init Channels
controlchannel.open()
audiochannel.open()

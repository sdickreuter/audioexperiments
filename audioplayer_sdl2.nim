# the following is based on:
# https://github.com/nim-lang/sdl2/blob/master/examples/sdl_audio_callback.nim

import sdl2
import sdl2/audio

import audiotypes

# Audio settings requested:
const RQBytesPerSample = 4 #2 # 16 bit PCM
const RQBufferSizeInBytes = framesPerBuffer * RQBytesPerSample


var 
  buffer: array[RQBufferSizeInBytes*16*2, float32] # Allocate a safe amount of memory
  obtained: AudioSpec # Actual audio parameters SDL returns
   

proc stopAudio*() =
  pauseAudio(1)

proc startAudio*() =
  pauseAudio(0)

proc AudioCallback(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl, thread.} =
  var 
    msg : AudioMessage
    rcount : int = 0
    lcount : int = 0

  msg = audiochannel.recv()
  case msg.kind
    of amaudio:
      for i in 0..int(obtained.samples*2)-1:
        if i mod 2 == 0:
          buffer[i] = msg.left[lcount]
          lcount += 1
        else:
          buffer[i] = msg.right[rcount]
          rcount += 1
    of amsilent: 
      for i in 0..int(obtained.samples*2)-1:
        buffer[i] = 0.0
    of amstop:
      stopAudio()

  for i in 0..int(obtained.samples*2-1):
    (cast[ptr float32](cast[int](stream) + i * RQBytesPerSample ))[] = 0 
  mixAudio(stream, cast[ptr uint8](addr(buffer[0])), uint32(RQBytesPerSample*int(obtained.samples*2)), SDL_MIX_MAXVOLUME)


proc InitSDL*() = 
   # Init audio playback
  if init(INIT_AUDIO) != SdlSuccess:
    echo("Couldn't initialize SDL\n")
    return
  var audioSpec: AudioSpec
  audioSpec.freq = sampleRate
  audioSpec.format = AUDIO_F32
  audioSpec.channels = 2
  audioSpec.samples = framesPerBuffer*2
  audioSpec.padding = 0
  audioSpec.callback = AudioCallback
  audioSpec.userdata = nil
  if openAudio(addr(audioSpec), addr(obtained)) != 0:
    echo("Couldn't open audio device. " & $getError() & "\n")
    return
  echo("frequency: ", obtained.freq)
  echo("format: ", obtained.format)
  echo("channels: ", obtained.channels)
  echo("samples: ", obtained.samples)
  echo("padding: ", obtained.padding)
  if obtained.format != AUDIO_F32:
    echo("Couldn't open 32-bit float audio channel.")
    return 


#proc main() =
#  Initsdl()
#  # Playback audio for 2 seconds
#  startaudio()
#  delay(2000)
#
#main()
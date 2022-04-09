import ./wrapper

let plugin = newAudioPlugin(
  version = 0,
  programCount = 0,
  parameterCount = 0,
  inputCount = 2,
  outputCount = 2,
)

plugin.processBlock = proc(plugin: AudioPlugin, inputs, outputs: HostAudioBuffer, channelCount, blockSize: int) =
  for c in 0 ..< channelCount:
    for s in 0 ..< blockSize:
      outputs[c][s] = inputs[c][s] * 0.5

exportAudioPlugin plugin
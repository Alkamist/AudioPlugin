import pkg/nimengine
import ./wrapper

# forwardDeclareReaperFunctions()

var ShowConsoleMsg: proc(msg: cstring) {.cdecl.}

var window: Window

proc openEditor(plugin: AudioPlugin, parent: pointer) =
  window = newWindow(
    width = 300,
    height = 200,
    parentHandle = cast[int](parent),
  )

  window.onPaint = proc(window: Window) =
    window.gfxCtx.setBackgroundColor(1.0, 0.1, 0.1, 1.0)
    window.gfxCtx.swapBuffers()

proc closeEditor(plugin: AudioPlugin) =
  window.close()

proc processBlock(plugin: AudioPlugin, inputs, outputs: HostAudioBuffer, channelCount, blockSize: int) =
  for c in 0 ..< channelCount:
    for s in 0 ..< blockSize:
      outputs[c][s] = inputs[c][s] * 0.5

let plugin = newAudioPlugin(
  version = 0,
  programCount = 0,
  parameterCount = 0,
  inputCount = 2,
  outputCount = 2,
)

plugin.openEditor = openEditor
plugin.closeEditor = closeEditor
plugin.processBlock = processBlock

# exportAudioPlugin plugin

proc VSTPluginMain(vstHostCallback: audioMasterCallback): ptr AEffect {.exportc, dynlib.} =
  let pluginRef = plugin
  GC_ref(pluginRef)

  ShowConsoleMsg = cast[proc(msg: cstring) {.cdecl.}](vstHostCallback(nil, 0xdeadbeef'i32, 0xdeadf00d'i32, 0, cast[pointer](cstring"ShowConsoleMsg"), 0.cfloat))

  return pluginRef.effect.addr
import std/strutils

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

const aeffectHeader = currentSourceDir() & "/vst2/aeffect.h"
# const aeffectxHeader = currentSourceDir() & "/vst2/aeffectx.h"

type
  VstAEffectFlags* = enum
    effFlagsHasEditor = 1 shl 0
    effFlagsHasClip = 1 shl 1 # Deprecated.
    effFlagsHasVu = 1 shl 2 # Deprecated.
    effFlagsCanMono = 1 shl 3 # Deprecated.
    effFlagsCanReplacing = 1 shl 4
    effFlagsProgramChunks = 1 shl 5
    effFlagsIsSynth = 1 shl 8
    effFlagsNoSoundInStop = 1 shl 9
    effFlagsExtIsAsync = 1 shl 10 # Deprecated.
    effFlagsExtHasBuffer = 1 shl 11 # Deprecated.
    effFlagsCanDoubleReplacing = 1 shl 12

  AEffectOpcodes* = enum
    effOpen
    effClose
    effSetProgram
    effGetProgram
    effSetProgramName
    effGetProgramName
    effGetParamLabel
    effGetParamDisplay
    effGetParamName
    effGetVu # Deprecated.
    effSetSampleRate
    effSetBlockSize
    effMainsChanged
    effEditGetRect
    effEditOpen
    effEditClose
    effEditDraw # Deprecated.
    effEditMouse # Deprecated.
    effEditKey # Deprecated.
    effEditIdle
    effEditTop # Deprecated.
    effEditSleep # Deprecated.
    effIdentify # Deprecated.
    effGetChunk
    effSetChunk

  AEffectXOpcodes* = enum
    effProcessEvents = effSetChunk.int32 + 1
    effCanBeAutomated
    effString2Parameter
    effGetNumProgramCategories # Deprecated.
    effGetProgramNameIndexed
    effCopyProgram # Deprecated.
    effConnectInput # Deprecated.
    effConnectOutput # Deprecated.
    effGetInputProperties
    effGetOutputProperties
    effGetPlugCategory
    effGetCurrentPosition # Deprecated.
    effGetDestinationBuffer # Deprecated.
    effOfflineNotify
    effOfflinePrepare
    effOfflineRun
    effProcessVarIo
    effSetSpeakerArrangement
    effSetBlockSizeAndSampleRate # Deprecated.
    effSetBypass
    effGetEffectName
    effGetErrorText # Deprecated.
    effGetVendorString
    effGetProductString
    effGetVendorVersion
    effVendorSpecific
    effCanDo
    effGetTailSize
    effIdle # Deprecated.
    effGetIcon # Deprecated.
    effSetViewPosition # Deprecated.
    effGetParameterProperties
    effKeysRequired # Deprecated.
    effGetVstVersion
    effEditKeyDown
    effEditKeyUp
    effSetEditKnobMode
    effGetMidiProgramName
    effGetCurrentMidiProgram
    effGetMidiProgramCategory
    effHasMidiProgramsChanged
    effGetMidiKeyName
    effBeginSetProgram
    effEndSetProgram
    effGetSpeakerArrangement
    effShellGetNextPlugin
    effStartProcess
    effStopProcess
    effSetTotalSampleToProcess
    effSetPanLaw
    effBeginLoadBank
    effBeginLoadProgram
    effSetProcessPrecision
    effGetNumMidiInputChannels
    effGetNumMidiOutputChannels

  VstPlugCategory* = enum
    kPlugCategUnknown
    kPlugCategEffect
    kPlugCategSynth
    kPlugCategAnalysis
    kPlugCategMastering
    kPlugCategSpacializer
    kPlugCategRoomFx
    kPlugSurroundFx
    kPlugCategRestoration
    kPlugCategOfflineProcess
    kPlugCategShell
    kPlugCategGenerator
    kPlugCategMaxCount

  audioMasterCallback* = proc(effect: ptr AEffect, opcode, index: int32, value: int, `ptr`: pointer, opt: cfloat): int {.cdecl.}
  AEffectDispatcherProc* = proc(effect: ptr AEffect, opcode, index: int32, value: int, `ptr`: pointer, opt: cfloat): int {.cdecl}
  AEffectProcessProc* = proc(effect: ptr AEffect, inputs, outputs: ptr ptr cfloat, sampleFrames: int32) {.cdecl.}
  AEffectProcessDoubleProc* = proc(effect: ptr AEffect, inputs, outputs: ptr ptr cdouble, sampleFrames: int32) {.cdecl.}
  AEffectSetParameterProc* = proc(effect: ptr AEffect, index: int32, parameter: cfloat) {.cdecl.}
  AEffectGetParameterProc* = proc(effect: ptr AEffect, index: int32): cfloat {.cdecl.}

  AEffect* {.importc, header: aeffectHeader.} = object
    magic*: int32
    dispatcher*: AEffectDispatcherProc
    setParameter*: AEffectSetParameterProc
    getParameter*: AEffectGetParameterProc
    numPrograms*: int32
    numParams*: int32
    numInputs*: int32
    numOutputs*: int32
    flags*: int32
    initialDelay*: int32
    `object`*: pointer
    uniqueID*: int32
    version*: int32
    processReplacing*: AEffectProcessProc
    processDoubleReplacing*: AEffectProcessDoubleProc

proc CCONST*[T](a, b, c, d: T): int32 {.importc, header: aeffectHeader.}
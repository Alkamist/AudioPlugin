import std/macros

macro defineLoadApi(procs: untyped): untyped =
  let getApiIdent = ident "getAPI"
  var
    varSection = nnkVarSection.newTree()
    codeSection = nnkStmtList.newTree()

  for p in procs:
    var
      pPragma = nnkPragma.newTree()
      cName = p.name.toStrLit

    for prag in p[4]:
      if prag.kind == nnkExprColonExpr and
         prag[0] == ident "importc":
        cName = prag[1]
        continue
      pPragma.add prag

    var pTyp = nnkProcTy.newTree(
      p[3],
      pPragma,
    )
    varSection.add newIdentDefs(
      p[0],
      pTyp,
    )
    codeSection.add nnkAsgn.newTree(
      p.name,
      nnkCast.newTree(
        pTyp,
        nnkCall.newTree(
          getApiIdent,
          cName,
        ),
      ),
    )
    codeSection.add nnkIfStmt.newTree(
      nnkElifBranch.newTree(
        nnkInfix.newTree(ident "==", p.name, newNilLit()),
        nnkReturnStmt.newTree(newIntLitNode(1)),
      ),
    )

  quote do:
    `varSection`
    proc REAPERAPI_LoadAPI*(`getApiIdent`: proc(name: cstring): pointer {.cdecl.}): cint =
      `codeSection`

expandMacros:
  defineLoadApi:
    proc Audio_Init*() {.cdecl.}
    proc Audio_IsPreBuffer*(): cint {.cdecl.}
    proc Audio_IsRunning*(): cint {.cdecl.}
    proc Audio_Quit*() {.cdecl.}


var
  Audio_Init: proc () {.cdecl.}
  Audio_IsPreBuffer: proc (): cint {.cdecl.}
  Audio_IsRunning: proc (): cint {.cdecl.}
  Audio_Quit: proc () {.cdecl.}

proc REAPERAPI_LoadAPI(getAPI: proc (name`gensym0: cstring): pointer {.cdecl.}): cint =
  Audio_Init = cast[proc () {.cdecl.}](getAPI("Audio_Init"))
  if Audio_Init == nil:
    return 1
  Audio_IsPreBuffer = cast[proc (): cint {.cdecl.}](getAPI("Audio_IsPreBuffer"))
  if Audio_IsPreBuffer == nil:
    return 1
  Audio_IsRunning = cast[proc (): cint {.cdecl.}](getAPI("Audio_IsRunning"))
  if Audio_IsRunning == nil:
    return 1
  Audio_Quit = cast[proc () {.cdecl.}](getAPI("Audio_Quit"))
  if Audio_Quit == nil:
    return 1
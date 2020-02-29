import httpcore, asyncdispatch, asyncfile, mimetypes, md5, uri
import strtabs, macros, tables, strformat, os, times, options, parseutils

import response, pages, constants
import ./cookies
from types import BaseType, Session, SameSite, initSession

import regex


when not defined(production):
  import ../naive/request


type
  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  # may change to flat
  Router* = ref object
    callable*: Table[Path, PathHandler]

  RePath* = object
    route*: Regex
    httpMethod*: HttpMethod

  ReRouter* = ref object
    callable*: seq[(RePath, PathHandler)]

  ReversedRouter* = TableRef[HandlerAsync, string]

  Context* = ref object
    request*: Request
    response*: Response
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    size*: int
    first*: bool
    middlewares*: seq[HandlerAsync]
    session*: Session
    attributes*: StringTableRef # for extension

  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}

  Event* = object
    case async*: bool
    of true:
      asyncHandler*: AsyncEvent
    of false:
      syncHandler*: SyncEvent

  HandlerAsync* = proc(ctx: Context): Future[void] {.closure, gcsafe.}

  ErrorHandler* = proc(ctx: Context): Future[void] {.nimcall, gcsafe.}

  ErrorHandlerTable* = TableRef[HttpCode, ErrorHandler]


proc default404Handler*(ctx: Context) {.async.}
proc default500Handler*(ctx: Context) {.async.}


proc newErrorHandlerTable*(initialSize = defaultInitialSize): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](initialSize)

proc newErrorHandlerTable*(pairs: openArray[(HttpCode,
    ErrorHandler)]): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](pairs)

proc newReversedRouter*(): ReversedRouter =
  newTable[HandlerAsync, string]()

proc initEvent*(handler: AsyncEvent): Event =
  Event(async: true, asyncHandler: handler)

proc initEvent*(handler: SyncEvent): Event =
  Event(async: false, syncHandler: handler)

proc newContext*(request: Request, response: Response,
    router: Router, reversedRouter: ReversedRouter,
        reRouter: ReRouter): Context {.inline.} =
  Context(request: request, response: response, router: router,
          reversedRouter: reversedRouter, reRouter: reRouter, size: 0,
          first: true,
          session: initSession(data = newStringTable()),
          attributes: newStringTable()
    )

proc handle*(ctx: Context): Future[void] {.inline.} =
  result = ctx.request.respond(ctx.response)

proc setHeader*(ctx: Context; key, value: string) {.inline.} =
  ctx.response.httpHeaders[key] = value

proc setHeader*(ctx: Context; key: string, value: seq[string]) {.inline.} =
  ctx.response.httpHeaders[key] = value

proc addHeader*(ctx: Context; key, value: string) {.inline.} =
  ctx.response.httpHeaders.add(key, value)

proc getCookie*(ctx: Context; key: string, default: string = ""): string {.inline.} =
  getCookie(ctx.request, key, default)

proc setCookie*(ctx: Context; key, value: string, expires = "", maxAge: Option[
    int] = none(int),
  domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, expires, maxAge, domain, path, secure,
      httpOnly, sameSite)

proc setCookie*(ctx: Context; key, value: string, expires: DateTime|Time,
    maxAge: Option[int] = none(int),
    domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, domain, expires, maxAge, path, secure,
      httpOnly, sameSite)

proc deleteCookie*(ctx: Context, key: string, path = "", domain = "") {.inline.} =
  ctx.deleteCookie(key = key, path = path, domain = domain)

proc defaultHandler*(ctx: Context) {.async.} =
  ctx.response.status = Http404

proc default404Handler*(ctx: Context) {.async.} =
  ctx.response.body = errorPage("404 Not Found!", PrologueVersion)
  ctx.setHeader("content-type", "text/html; charset=UTF-8")

proc default500Handler*(ctx: Context) {.async.} =
  ctx.response.body = internalServerErrorPage()
  ctx.setHeader("content-type", "text/html; charset=UTF-8")

macro getPostParams*(key: string, default = ""): string =
  var ctx = ident"ctx"

  result = quote do:
    case `ctx`.request.reqMethod
    of HttpPost:
      `ctx`.request.postParams.getOrDefault(`key`, `default`)
    else:
      ""

macro getQueryParams*(key: string, default = ""): string =
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.request.queryParams.getOrDefault(`key`, `default`)

macro getPathParams*(key: string): string =
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.request.pathParams.getOrDefault(`key`)

macro getPathParams*[T: BaseType](key: sink string, default: T): T =
  var ctx = ident"ctx"

  result = quote do:
    let pathParams = `ctx`.request.pathParams.getOrDefault(`key`)
    parseValue(pathParams, `default`)

proc setResponse*(ctx: Context, status: HttpCode, httpHeaders =
  {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
      body = "", version = HttpVer11) {.inline.} =
  ## handy to make ctx's response
  let response = initResponse(httpVersion = version, status = status,
    httpHeaders = {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
        body = body)
  ctx.response = response

proc setResponse*(ctx: Context, response: Response) {.inline.} =
  ## handy to make ctx's response
  ctx.response = response

proc multiMatch*(s: string, replacements: StringTableRef): string =
  result = newStringOfCap(s.len)
  var
    pos = 0
    tok = ""
  let
    startChar = '{'
    endChar = '}'
    sep = '/'

  while pos < s.len:
    pos += parseUntil(s, tok, startChar, pos)
    result.add tok
    if pos < s.len:
      assert s[pos-1] == sep, "The char before '{' must be '/'"
    else:
      break
    inc(pos)
    pos += parseUntil(s, tok, endChar, pos)
    inc pos
    if tok.len != 0:
      if tok in replacements:
        result.add replacements[tok]
      else:
        raise newException(ValueError, "Unexpected key")

proc multiMatch*(s: string, replacements: varargs[(string, string)]): string {.inline.} =
  multiMatch(s, replacements.newStringTable)

macro urlFor*(handler: HandlerAsync, parameters: seq[(string,
    string)] = @[], queryParams: seq[(string, string)] = @[],
        usePlus = true, omitEq = true): string =
  ## { } can't appear in url
  var ctx = ident"ctx"

  result = quote do:
    var res: string
    if `handler` in `ctx`.reversedRouter:
      res = `ctx`.reversedRouter[`handler`]

    res = multiMatch(res, `parameters`)
    let queryString = encodeQuery(`queryParams`, `usePlus`, `omitEq`)
    if queryString.len != 0:
      res = multiMatch(res, `parameters`) & "?" & queryString
    res

proc attachment(ctx: Context, downloadName = "", charset = "utf-8") {.inline.} =
  if downloadName.len == 0:
    return

  var ext = downloadName.splitFile.ext
  if ext.len > 0:
    ext = ext[1 .. ^1]
    let mimes = ctx.request.settings.mimeDB.getMimetype(ext)
    if mimes.len != 0:
      ctx.setHeader("Content-Type", fmt"{mimes}; charset={charset}")

  ctx.setHeader("Content-Disposition", fmt"""attachment; filename="{downloadName}"""")

proc staticFileResponse*(ctx: Context, fileName, root: string, mimetype = "",
    downloadName = "", charset = "utf-8", headers = newHttpHeaders()) {.async.} =
  let
    filePath = root / fileName

  # exists -> have access -> can open
  if not existsFile(filePath):
    await ctx.request.respond(error404(headers = headers))
    return

  var filePermission = getFilePermissions(filePath)
  if fpOthersRead notin filePermission:
    await ctx.request.respond(abort(status = Http403,
        body = "You do not have permission to access this file.",
        headers = headers))
    return

  var
    mimetype = mimetype
    download = false

  if mimetype.len == 0:
    var ext = fileName.splitFile.ext
    if ext.len > 0:
      ext = ext[1 .. ^ 1]
    mimetype = ctx.request.settings.mimeDB.getMimetype(ext)

  let
    info = getFileInfo(filePath)
    contentLength = info.size
    lastModified = info.lastWriteTime
    etagBase = fmt"{fileName}-{lastModified}-{contentLength}"
    etag = getMD5(etagBase)

  ctx.response.httpHeaders = headers

  if mimetype.len != 0:
    ctx.setHeader("Content-Type", fmt"{mimetype}; {charset}")

  ctx.setHeader("Content-Length", $contentLength)
  ctx.setHeader("Last-Modified", $lastModified)
  ctx.setHeader("Etag", etag)

  if downloadName.len != 0:
    ctx.attachment(downloadName)
    download = true


  if contentLength < 20_000_000:
    # if ctx.request.headers.hasKey("If-None-Match") and ctx.request.headers[
    #     "If-None-Match"] == etag and download == true:
      # await ctx.request.respond(Http304, "")
    # else:
    let body = readFile(filePath)
    await ctx.request.respond(Http200, body, headers)
  else:
    await ctx.request.respond(Http200, "", headers)
    var
      fileStream = newFutureStream[string]("staticFileResponse")
      file = openAsync(filePath, fmRead)
    defer: file.close()

    await file.readToStream(fileStream)

    while true:
      let (hasValue, value) = await fileStream.read()
      if hasValue:
        await ctx.request.send(value)
      else:
        break
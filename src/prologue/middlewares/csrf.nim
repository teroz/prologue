import httpcore, strtabs
from htmlgen import input

import karax / [karaxdsl, vdom]
import cookiejar

import ../core/dispatch
from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie, deleteCookie
import ../core/request
import ../core/types


const
  DefaultTokenName* = "CSRFToken"
  DefaultSecretSize* = 32
  DefaultTokenSize* = 64

proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  ctx.getCookie(tokenName)

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.setCookie(tokenName, value)

proc reject(ctx: Context) {.inline.} =
  ctx.response.code = Http403

proc makeToken(secret: openArray[byte]): string {.inline.} =
  var
    mask = randomBytesSeq(DefaultSecretSize)
    token = newSeq[byte](DefaultTokenSize)

  for idx in DefaultSecretSize ..< DefaultTokenSize:
    token[idx-DefaultSecretSize] = mask[idx - DefaultSecretSize] + secret[idx-DefaultSecretSize]

  token[0 ..< DefaultSecretSize] = move mask

  result = token.urlsafeBase64Encode

proc recoverToken(token: string): seq[byte] {.inline.} =
  let
    token = token.urlsafeBase64Decode

  result = newSeq[byte](DefaultSecretSize)
  for idx in 0 ..< DefaultSecretSize:
    result[idx] = byte(token[idx]) - byte(token[DefaultSecretSize + idx])


proc generateToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  let tok = ctx.getToken(tokenName)
  if tok.len == 0:
    let secret = randomBytesSeq(DefaultSecretSize)
    result = makeToken(secret)
    ctx.setToken(result, tokenName)
  else:
    let secret = recoverToken(tok)
    result = makeToken(secret)
    
proc checkToken(checked, secret: string): bool {.inline.} =
  try:
    let
      checked = checked.recoverToken
      secret = secret.recoverToken

    result = checked == secret
  except:
    discard


proc csrfToken*(ctx: Context, tokenName = DefaultTokenName): VNode {.inline.} =
  result = flatHtml(input(`type` = "hidden", name = tokenName, value = generateToken(ctx, tokenName)))

# logging potential csrf attack
proc csrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return
    
    # don't submit forms multi-times
    if ctx.request.cookies.hasKey("csrf_used"):
      ctx.deleteCookie("csrf_used")
      reject(ctx)
      return

    # forms don't send hidden values
    if not ctx.request.postParams.hasKey(tokenName):
      reject(ctx)
      return

    # forms don't use csrfToken
    if ctx.getToken(tokenName).len == 0:
      reject(ctx)
      return

    # not equal
    if not checkToken(ctx.request.postParams[tokenName], ctx.getToken(tokenName)):
      reject(ctx)
      return

    # pass
    ctx.setCookie("csrf_used", "")

    await switch(ctx)

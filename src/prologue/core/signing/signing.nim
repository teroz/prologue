import strutils, tables, strformat, times

import signingbase

import nimcrypto

import ../../security/aes

from ../types import SecretKey
from ../encode import urlsafeBase64Encode

export signingbase


type
  BaseDigestType* = sha1 | sha2 | keccak | ripemd | blake2

  BaseDigestMethodType* = enum
    Sha1Type,
    Sha224Type, Sha384Type, Sha512Type, Sha512_224Type, Sha512_256Type
    Keccak224Type, Keccak256Type, Keccak384Type, Keccak512Type, Sha3_224Type,
        Sha3_256Type, Sha3_384Type, Sha3_512Type
    Ripemd128Type, Ripemd160Type, Ripemd256Type, Ripemd320Type
    Blake2_224Type, Blake2_256Type, Blake2_384Type, Blake2_512Type

  KeyDerivation* = enum
    Concat, MoreConcat, KeyHmac, None

  Signer* = object
    secretKey: SecretKey
    salt: string
    sep: char
    keyDerivation: KeyDerivation
    digestMethod: BaseDigestMethodType

  TimedSigner* = object
    secretKey: SecretKey
    salt: string
    sep: char
    keyDerivation: KeyDerivation
    digestMethod: BaseDigestMethodType


const
  DefaultSalt = "Starlight.Prologue"
  DefaultSep* = '.'
  Base64Alphabet = IdentChars + {'-', '='}
  DefaultKeyDerivation* = MoreConcat
  DefaultDigestMethodType* = Sha1Type


proc initSigner*(secretKey: SecretKey, salt = DefaultSalt, sep = DefaultSep,
                 keyDerivation = DefaultKeyDerivation,
                 digestMethod = DefaultDigestMethodType): Signer =

  if sep in Base64Alphabet:
    raise newException(ValueError, "The given separator cannot be used because it may be " &
                       "contained in the signature itself. Alphanumeric " &
                       "characters and `-_=` must not be used.")

  Signer(secretKey: secretKey, salt: salt, sep: sep,
         keyDerivation: keyDerivation, digestMethod: digestMethod)

proc initTimedSigner*(secretKey: SecretKey, salt = DefaultSalt,
                      sep = DefaultSep, keyDerivation = DefaultKeyDerivation,
                      digestMethod = DefaultDigestMethodType): TimedSigner =

  if sep in Base64Alphabet:
    raise newException(ValueError, "The given separator cannot be used because it may be " &
                       "contained in the signature itself. Alphanumeric " &
                       "characters and `-_=` must not be used. ")

  TimedSigner(secretKey: secretKey, salt: salt, sep: sep,
              keyDerivation: keyDerivation, digestMethod: digestMethod)

proc getKeyDerivationEncode[T: BaseDigestType](s: Signer | TimedSigner, 
                            digestMethodType: typedesc[T], value: openArray[byte]): string =
  let secretKey = string(s.secretKey)
  case s.keyDerivation
  of Concat:
    let key = digestMethodType.digest(s.salt & secretKey)
    result = digestMethodType.hmac(key.data, value)
                             .data
                             .urlsafeBase64Encode
                             .strip(leading = false, chars = {'='})
  of MoreConcat:
    let key = digestMethodType.digest(s.salt & "signer" & secretKey)
    result = digestMethodType.hmac(key.data,value)
                             .data.urlsafeBase64Encode
                             .strip(leading = false, chars = {'='})
  of KeyHmac:
    var hctx: Hmac[digestMethodType]
    hctx.init(secretKey)
    hctx.update(s.salt)
    let key = finish(hctx)
    result = digestMethodType.hmac(key.data, value)
                             .data
                             .urlsafeBase64Encode
                             .strip(leading = false, chars = {'='})
  of None:
    result = digestMethodType.hmac(secretKey, value)
                             .data
                             .urlsafeBase64Encode
                             .strip(leading = false, chars = {'='})

proc getKeyDerivationDecode[T: BaseDigestType](s: Signer | TimedSigner,
    digestMethodType: typedesc[T]): string =
  let secretKey = string(s.secretKey)
  case s.keyDerivation
  of Concat:
    result = $digestMethodType.digest(s.salt & secretKey)
  of MoreConcat:
    result = $digestMethodType.digest(s.salt & "signer" & secretKey)
  of KeyHmac:
    var hctx: Hmac[digestMethodType]
    hctx.init(secretKey)
    hctx.update(s.salt)
    result = $finish(hctx)
  of None:
    result = secretKey

proc getSignatureEncode*(s: Signer | TimedSigner, value: openArray[
    byte]): string =
  case s.digestMethod
  of Sha1Type:
    result = getKeyDerivationEncode(s, sha1, value)
  of Sha224Type:
    result = getKeyDerivationEncode(s, sha224, value)
  of Sha384Type:
    result = getKeyDerivationEncode(s, sha384, value)
  of Sha512Type:
    result = getKeyDerivationEncode(s, sha512, value)
  of Sha512_224Type:
    result = getKeyDerivationEncode(s, sha512_224, value)
  of Sha512_256Type:
    result = getKeyDerivationEncode(s, sha512_256, value)
  of Keccak224Type:
    result = getKeyDerivationEncode(s, keccak224, value)
  of Keccak256Type:
    result = getKeyDerivationEncode(s, keccak256, value)
  of Keccak384Type:
    result = getKeyDerivationEncode(s, keccak384, value)
  of Keccak512Type:
    result = getKeyDerivationEncode(s, keccak512, value)
  of Sha3_224Type:
    result = getKeyDerivationEncode(s, sha3_224, value)
  of Sha3_256Type:
    result = getKeyDerivationEncode(s, sha3_256, value)
  of Sha3_384Type:
    result = getKeyDerivationEncode(s, sha3_384, value)
  of Sha3_512Type:
    result = getKeyDerivationEncode(s, sha3_512, value)
  of Ripemd128Type:
    result = getKeyDerivationEncode(s, ripemd128, value)
  of Ripemd160Type:
    result = getKeyDerivationEncode(s, ripemd160, value)
  of Ripemd256Type:
    result = getKeyDerivationEncode(s, ripemd256, value)
  of Ripemd320Type:
    result = getKeyDerivationEncode(s, ripemd320, value)
  of Blake2_224Type:
    result = getKeyDerivationEncode(s, blake2_224, value)
  of Blake2_256Type:
    result = getKeyDerivationEncode(s, blake2_256, value)
  of Blake2_384Type:
    result = getKeyDerivationEncode(s, blake2_384, value)
  of Blake2_512Type:
    result = getKeyDerivationEncode(s, blake2_512, value)

proc getSignatureDecode*(s: Signer | TimedSigner): string =
  case s.digestMethod
  of Sha1Type:
    result = getKeyDerivationDecode(s, sha1)
  of Sha224Type:
    result = getKeyDerivationDecode(s, sha224)
  of Sha384Type:
    result = getKeyDerivationDecode(s, sha384)
  of Sha512Type:
    result = getKeyDerivationDecode(s, sha512)
  of Sha512_224Type:
    result = getKeyDerivationDecode(s, sha512_224)
  of Sha512_256Type:
    result = getKeyDerivationDecode(s, sha512_256)
  of Keccak224Type:
    result = getKeyDerivationDecode(s, keccak224)
  of Keccak256Type:
    result = getKeyDerivationDecode(s, keccak256)
  of Keccak384Type:
    result = getKeyDerivationDecode(s, keccak384)
  of Keccak512Type:
    result = getKeyDerivationDecode(s, keccak512)
  of Sha3_224Type:
    result = getKeyDerivationDecode(s, sha3_224)
  of Sha3_256Type:
    result = getKeyDerivationDecode(s, sha3_256)
  of Sha3_384Type:
    result = getKeyDerivationDecode(s, sha3_384)
  of Sha3_512Type:
    result = getKeyDerivationDecode(s, sha3_512)
  of Ripemd128Type:
    result = getKeyDerivationDecode(s, ripemd128)
  of Ripemd160Type:
    result = getKeyDerivationDecode(s, ripemd160)
  of Ripemd256Type:
    result = getKeyDerivationDecode(s, ripemd256)
  of Ripemd320Type:
    result = getKeyDerivationDecode(s, ripemd320)
  of Blake2_224Type:
    result = getKeyDerivationDecode(s, blake2_224)
  of Blake2_256Type:
    result = getKeyDerivationDecode(s, blake2_256)
  of Blake2_384Type:
    result = getKeyDerivationDecode(s, blake2_384)
  of Blake2_512Type:
    result = getKeyDerivationDecode(s, blake2_512)

# TODO May support compress
proc sign*(s: Signer, value: string): string =
  var enc = encrypt(s.secretKey.string,value).toHex() 
  enc & s.sep & s.getSignatureEncode(value.toOpenArrayByte(0, value.len - 1))
  #value & s.sep & s.getSignatureEncode(value.toOpenArrayByte(0, value.len - 1))

proc sign*(s: TimedSigner, value: string): string =
  let
    sep = s.sep
    timestamp = $int(cpuTime())
    value = value & sep & timestamp
    enc = encrypt(s.secretKey.string,value).toHex()
  enc & sep & s.getSignatureEncode(value.toOpenArrayByte(0, value.len - 1))
  #value & sep & s.getSignatureEncode(value.toOpenArrayByte(0, value.len - 1))

proc verifySignature(s: Signer | TimedSigner, value, sig: string): bool =
  return sig == s.getSignatureEncode(value.toOpenArrayByte(0, value.len - 1))

proc unsign*(s: Signer | TimedSigner, signedValue: string): string =
  let sep = s.sep
  if sep notin signedValue:
    raise newException(BadSignatureError, fmt"No {$sep} found in value")
  let
    temp = signedValue.rsplit({sep}, maxsplit = 1)
    value = decrypt(s.secretKey.string,parseHexStr(temp[0]))
    sig = temp[1]
  if verifySignature(s, value, sig):
    return value
  raise newException(BadSignatureError, fmt"Signature {sig} does not match")

proc unsign*(s: TimedSigner, signedValue: string, max_age: Natural): string =
  var
    res: string
  
  res = unsign(s, signedValue)

  let sep = s.sep

  if sep notin signedValue:
    raise newException(BadTimeSignatureError, "timestamp missing")

  let
    temp = res.rsplit({sep}, maxsplit = 1)
    value = temp[0]

  var timestamp = temp[1]

  if timestamp.len == 0:
    raise newException(BadTimeSignatureError, "Malformed timestamp")

  if max_age > 0:
    let age = int(cputime()) - parseInt(timestamp) + 1
    if age > max_age:
      raise newException(SignatureExpiredError,
          fmt"Signature age {age} > {max_age} seconds")

  return value

proc validate*(s: Signer, signedValue: string): bool =
  result = true
  try:
    discard s.unsign(signedValue)
  except BadSignatureError:
    result = false


when isMainModule:
  import os, json

  block:
    let
      key = SecretKey("1234123412ABCDEF")
      s = initSigner(key, salt = "itsdangerous.Signer")
      sig = s.sign("my string")
    assert sig == "9682DB888F8992959C.PCGWYl-k02AneM2cErEX6ajBLE4"
    assert s.unsign(sig) == "my string"
    assert validate(s, sig)

  # block:
  #   let
  #     key = SecretKey("1234123412ABCDEF")
  #     s = initTimedSigner(key, salt = "08090A0B0C0D0E0F",
  #         digestMethod = Sha1Type)
  #     sig = s.sign("my string")
  #   sleep(6000)
  #   doAssertRaises(SignatureExpiredError):
  #     discard s.unsign(sig, 5) == "my string"

  block:
    let
      key = SecretKey("1234123412ABCDEF")
      s = initSigner(key, salt = "08090A0B0C0D0E0F",
          digestMethod = Sha1Type)
      sig {.used.} = s.sign( $ %*[1, 2, 3])
    doAssertRaises(BadSignatureError):
      discard s.unsign("89F749CD0D66E29525586E11E62CB4A8.sdhfghjkjhdfghjigf")

import nimAES,unittest

#var aes = initAES()
# let input = "0123456789ABCDEF"
#let key = "FEDCBA9876543210"
#let message ="""Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do" #eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
#                             Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaeca 
#                             # t cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""#.strip(true,true,{'\r','\n', '\r','\n', '\f', '\v'})

# if aes.setEncodeKey(key):
#   let encrypted = aes.encryptECB(message)
#   if aes.setDecodeKey(key):
#     let decrypted = aes.decryptECB(message)
#     assert decrypted == input


# var ctx: AESContext
# zeroMem(addr(ctx), sizeof(ctx))
# #var key = "0123456789ABCDEF"
# var text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
# check ctx.setEncodeKey(key) == true
# var offset = 0
# var counter: array[0..15, uint8]
# var nonce = cast[cstring](addr(counter[0]))
# zeroMem(addr(counter), sizeof(counter))
# var out1 = ctx.cryptCTR(offset, nonce, message)
# offset = 0
# zeroMem(addr(counter), sizeof(counter))
# var out2 = ctx.cryptCTR(offset, nonce, out1)
# check out2 == message

proc encrypt*(secret:string,message:string):string{.gcsafe.}=
    var ctx: AESContext
    var offset = 0
    var counter: array[0..15, uint8]
    var nonce = cast[cstring](addr(counter[0]))
    
    zeroMem(addr(ctx), sizeof(ctx))
    check ctx.setEncodeKey(secret) == true
    zeroMem(addr(counter), sizeof(counter))
    result = ctx.cryptCTR(offset, nonce, message)
    
proc decrypt*(secret:string,encrypted:string):string=
    var ctx: AESContext
    var offset = 0
    var counter: array[0..15, uint8]
    var nonce = cast[cstring](addr(counter[0]))
    
    zeroMem(addr(ctx), sizeof(ctx))
    check ctx.setEncodeKey(secret) == true
    zeroMem(addr(counter), sizeof(counter))
    result  = ctx.cryptCTR(offset, nonce, encrypted)
    

when isMainModule:
    let key = "FEDCBA9876543210"
    let message ="""Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do" #eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
                            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaeca 
                            # t cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""#.strip(true,true,{'\r','\n', '\r','\n', '\f', '\v'})


    var enc = encrypt(key,message)
    var dec = decrypt(key,enc)

    assert dec == message

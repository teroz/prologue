![Build Status](https://github.com/planety/prologue/workflows/Test%20Prologue/badge.svg)
[![Build Status](https://dev.azure.com/xzsflywind/xlsx/_apis/build/status/planety.prologue?branchName=master)](https://dev.azure.com/xzsflywind/xlsx/_build/latest?definitionId=4&branchName=master)
![Build Status](https://travis-ci.org/planety/prologue.svg?branch=master)

[![License: BSD-3-Clause](https://img.shields.io/github/license/planety/prologue)](https://opensource.org/licenses/BSD-3-Clause)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)


# Prologue[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)
What's past is prologue.

### Purpose
It tends to be Medium scale Web Framework(May be Full-Stack without models or Orm)

You can see our task assignment as below or join us.

https://github.com/planety/BluePrint/blob/master/task.md


### Docs [Not yet]

Docs in https://starlight-prologue.readthedocs.io/en/latest/


### Feature

- Server
  - [ ] High Performance Http 1.1/2.0 Server
  - [ ] High Performance Websocket Server
  - [ ] Http 2.0 Client
  - [ ] SSL/HttpS Support
  - [ ] Reloader
- Core
  - [x] Configure and Settings
  - [x] Context
  - [x] Params and Query Data
  - [x] Form Data
  - [x] Static Files
  - [x] Middlewares
  - [x] Simple Route
  - [x] Regex Route
  - [x] CORS Response
  - [x] Signing
  - [x] Cookie
  - [x] Session
  - [x] Cache
  - [ ] Startup and Shutdown Events
  - [ ] Cross-Site Request Forgery
  - [ ] Cross-Site Scripting (XSS) Protection
  - [ ] Clickjacking Protection
  - [ ] Host header validation
  - [ ] Referrer policy
  - [ ] Live Monitor
  - [ ] Flashing Messages
  - [ ] Authentication
- Plugin
  - [x] Template(Using Karax Native or Using Nim Filter)
  - [x] Test Client(Using httpclient)
  - [ ] Openapi

### Installation

```bash
nimble install prologue
```

### Usage

More examples
- [HelloWorld](https://github.com/planety/prologue/tree/master/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/master/examples/todolist)

#### Hello World

```nim
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings(appName = "StarLight", debug = true)
var app = initApp(settings = settings, middlewares = @[stripPathMiddleware()])
app.addRoute("/", hello, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.run()
```

The server is running at localhost:8080.

#### Another example

```nim
# Async Function
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.request.pathParams.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")


let settings = newSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
```

#### Urls Files
**views.nim**

```nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"

proc index*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static")

proc helloName*(ctx: Context) {.async.} =
  echo getPathParams("name")
  resp "<h1>Hello, " & getPathParams("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  echo "-----------------------------------------------------"
  echo ctx.request.postParams
  echo getPostParams("username", "")
  echo getPostParams("password", "")
  resp redirect("/hello/Nim")

proc multiPart*(ctx: Context) {.async.} =
  resp multiPartPage()

proc do_multiPart*(ctx: Context) {.async.} =
  resp redirect("/login")
```

**urls.nim**

```nim

import prologue


import views


let urlPatterns* = @[
  pattern("/", home, @[HttpGet, HttpPost]),
  pattern("/home", home),
  pattern("/login", login),
  pattern("/login", do_login, HttpPost),
  pattern("/redirect", testRedirect),
  pattern("/multipart", multipart)
]
```

**app.nim**

```nim
import prologue


import views, urls

# read environment variables from file
# Make sure ".env" in your ".gitignore" file.
let 
  env = loadPrologueEnv(".env")

let
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                debug = env.getOrDefault("debug", true), 
                port = Port(env.getOrDefault("port", 8080)),
                staticDirs = env.get("staticDir"),
                secretKey = SecretKey(env.getOrDefault("secretKey", ""))
                )

var app = initApp(settings = settings, middlewares = @[])
app.addRoute(urls.urlPatterns, "/todolist")
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/index.html", index, HttpGet)
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost)
# will match /hello/Nim and /hello/
app.addRoute("/hello/{name}", helloName, HttpGet)
app.addRoute("/multipart", multiPart, HttpGet)
app.addRoute("/multipart", do_multiPart, HttpPost)
app.run()
```
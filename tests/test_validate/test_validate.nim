import strtabs

from ../../src/prologue/validate/validate import required, accepted, isInt,
    isNumeric, isBool, equals, minValue, maxValue, rangeValue, matchRegex,
        matchUrl, newFormValidation, validate, minLength, maxLength, rangeLength

from ../../src/prologue/core/basicregex import re


import unittest


suite "Test Validate":
  test "isInt can work":
    let
      msg = "Int required"
      decide = isInt(msg)
      decideDefaultMsg = isInt()
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("912.6") == (false, msg)
      decide("a912") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("a912") == (false, "a912 is not an integer!")
      decideDefaultMsg("") == (false, " is not an integer!")

  test "isNumeric can work":
    let
      msg = "Numeric required"
      decide = isNumeric(msg)
      decideDefaultMsg = isNumeric()
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("0.5") == (true, "")
      decide("-912.6") == (true, "")
      decide("a912") == (false, msg)
      decide("0.91.2") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("0.91.2") == (false, "0.91.2 is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")

  test "isBool can work":
    let
      msg = "Bool required"
      decide = isBool(msg)
      decideDefaultMsg = isBool()
    check:
      decide("true") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("n") == (true, "")
      decide("False") == (true, "")
      decide("Off") == (true, "")
      decide("wrong") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("wrong") == (false, "wrong is not a boolean!")
      decideDefaultMsg("") == (false, " is not a boolean!")

  test "equals can work":
    let
      msg = "not equal"
      decide = equals("prologue", msg)
      decideDefaultMsg = equals("starlight")
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)
      decideDefaultMsg("prologue") == (false, "prologue is not equal to starlight!")

  test "minValue can work":
    let
      msg = "lower than"
      decide = minValue(12, msg)
      decideDefaultMsg = minValue(-5.5)
    check:
      decide("27") == (true, "")
      decide("8.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("-12") == (false, "-12 is not greater than or equal to -5.5!")

  test "maxValue can work":
    let
      msg = "greater than"
      decide = maxValue(12, msg)
      decideDefaultMsg = maxValue(-5.5)
    check:
      decide("2.7") == (true, "")
      decide("18.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("2") == (false, "2 is not less than or equal to -5.5!")

  test "rangeValue can work":
    let
      msg = "not in Range"
      decide = rangeValue(-9, 13, msg)
      decideDefaultMsg = rangeValue(-5.5, 77)
    check:
      decide("2.7") == (true, "")
      decide("18.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("-29") == (false, "-29 is not in range from -5.5 to 77.0!")

  test "minLength can work":
    let
      msg = "lower than"
      decide = minLength(12, msg)
      decideDefaultMsg = minLength(7)
    check:
      decide("Welcome to use Prologue!") == (true, "")
      decide("Not True") == (false, msg)
      decideDefaultMsg("Prologue") == (true, "")
      decideDefaultMsg("Not") == (false, "Length 3 is not greater than or equal to 7!")

  test "maxLength can work":
    let
      msg = "greater than"
      decide = maxLength(12, msg)
      decideDefaultMsg = maxLength(5)
    check:
      decide("True") == (true, "")
      decide("Welcome to use Prologue!") == (false, msg)
      decideDefaultMsg("True") == (true, "")
      decideDefaultMsg("Prologue") == (false, "Length 8 is not less than or equal to 5!")

  test "rangeLength can work":
    let
      msg = "not in Range"
      decide = rangeLength(9, 13, msg)
      decideDefaultMsg = rangeLength(5, 17)
    check:
      decide("use Prologue") == (true, "")
      decide("Prologue") == (false, msg)
      decideDefaultMsg("prologue") == (true, "")
      decideDefaultMsg("use") == (false, "Length 3 is not in range from 5 to 17!")

  test "required can work":
    let
      msg = "Keywords required"
      decide = required(msg)
      decideDefaultMsg = required()
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)
      decideDefaultMsg("") == (false, "Field is required!")

  test "accepted can work":
    let
      msg = "Not accepted"
      decide = accepted(msg)
      decideDefaultMsg = accepted()
    check:
      decide("on") == (true, "")
      decide("y") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("true") == (true, "")
      decide("") == (false, msg)
      decide("off") == (false, msg)
      decide("12") == (false, msg)
      decideDefaultMsg("") == (false, """ is not in "yes", "y", "on", "1", "true"!""")
      decideDefaultMsg("off") == (false, """off is not in "yes", "y", "on", "1", "true"!""")
      decideDefaultMsg("12") == (false, """12 is not in "yes", "y", "on", "1", "true"!""")

  test "matchRegex can work":
    let
      msg = "Regex doesn't match!"
      decide = matchRegex(re"(?P<greet>hello) (?:(?P<who>[^\s]+)\s?)+", msg)
      decideDefaultMsg = matchRegex(re"abc")
    check:
      decide("hello beautiful world") == (true, "")
      decide("time") == (false, msg)
      decideDefaultMsg("abc") == (true, "")
      decideDefaultMsg("abcd") == (false, "abcd doesn't match Regex")

  test "matchUrl can work":
    let
      msg = "Regex doesn't match!"
      decide = matchUrl(msg)
      decideDefaultMsg = matchUrl()
    check:
      decide("https://www.google.com") == (true, "")
      decide("https://127.0.0.1") == (true, "")
      decide("127.0.0.1") == (false, msg)
      decideDefaultMsg("file:///prologue/starlight.nim") == (true, "")
      decideDefaultMsg("https:/www.prologue.com") == (false,
                "https:/www.prologue.com doesn't match url")

  test "validate can work":
    var validater = newFormValidation({
        "accepted": @[required(), accepted()],
        "required": @[required()],
        "requiredInt": @[required(), isInt()],
        "minValue": @[required(), isInt(), minValue(12), maxValue(19)]
      })
    let
      chk1 = validater.validate({"required": "on", "accepted": "true",
          "requiredInt": "12", "minValue": "15"}.newStringTable)
      chk2 = validater.validate({"requird": "on", "time": "555",
          "minValue": "10"}.newStringTable)
      chk3 = validater.validate({"requird": "on", "time": "555",
          "minValue": "10"}.newStringTable, allMsgs = false)
      chk4 = validater.validate({"required": "on", "accepted": "true",
      "requiredInt": "12.5", "minValue": "13"}.newStringTable, allMsgs = false)

    check:
      chk1 == (true, "")
      not chk2.hasValue
      chk2.msg == "Can\'t find key: accepted\nCan\'t find key: " &
            "required\nCan\'t find key: requiredInt\n10 is not greater than or equal to 12.0!\n"
      not chk3.hasValue
      chk3.msg == "Can\'t find key: accepted\n"
      not chk4.hasValue
      chk4.msg == "12.5 is not an integer!\n"

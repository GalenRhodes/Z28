/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Z28
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/29/21
 *
 * Copyright © 2021 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation
import Rubicon
import SourceKittenFramework
import SourceKit

func writePList(data: [String: Any], toFile path: String? = nil) throws {
    let j = try JSONSerialization.data(withJSONObject: data, options: [ .prettyPrinted, .sortedKeys ])
    guard let s = String(data: j, encoding: .utf8) else { throw StreamError.UnknownError(description: "Unable to encode data as UTF-8.") }

    if let path = path {
        try printTo(filename: path, s, terminator: "")
    }
    else {
        printToStdout(s)
    }
}

func printToStdout(_ str: String, terminator: String = "\n") {
    do { try printTo(filename: "/dev/stdout", str, terminator: terminator) }
    catch let e { fatalError("ERROR: \(e)") }
}

func printToStderr(_ str: String, terminator: String = "\n") {
    do { try printTo(filename: "/dev/stderr", str, terminator: terminator) }
    catch let e { fatalError("ERROR: \(e)") }
}

func printTo(filename: String, _ str: String, terminator: String = "\n") throws {
//    #if DEBUG
//        let f = !value(filename, isOneOf: "/dev/stdout", "/dev/stderr")
//        if f { print("Writing to file: \"\(filename)\"...", terminator: "") }
//        defer { if f { print(" done.") } }
//    #endif
    try "\(str)\(terminator)".write(toFile: filename, atomically: false, encoding: .utf8)
}

func fromJSON(_ data: String) throws -> [String: Any] {
    guard let d = "{ \"data\" : \(data) }".data(using: .utf8) else { throw PGErrors.UnexpectedError(description: "Unable to encode string in UTF-8") }
    guard let o = try JSONSerialization.jsonObject(with: d) as? [String: Any] else { throw PGErrors.UnexpectedError(description: "Incorrect format returned.") }
    return o
}

func toArray(_ arr: [SourceKitRepresentable]) -> [Any] {
    var out = Array<Any>()

    for object in arr {
        switch object {
            case let object as [SourceKitRepresentable]:           out += toArray(object)
            case let object as [[String: SourceKitRepresentable]]: out <+ object.map { toDictionary($0) }
            case let object as [String: SourceKitRepresentable]:   out <+ toDictionary(object)
            default:                                               out <+ object
        }
    }

    return out
}

func toDictionary(_ dict: [String: SourceKitRepresentable]) -> [String: Any] {
    var out = Dictionary<String, Any>()

    for (key, object) in dict {
        switch object {
            case let object as [SourceKitRepresentable]:           out[key] = toArray(object)
            case let object as [[String: SourceKitRepresentable]]: out[key] = object.map { toDictionary($0) }
            case let object as [String: SourceKitRepresentable]:   out[key] = toDictionary(object)
            default:                                               out[key] = object
        }
    }

    return out
}

@inlinable func mapIntToInt64(_ o: Any) -> Any { (isType(o, Int.self) ? Int64(o as! Int) : o) }

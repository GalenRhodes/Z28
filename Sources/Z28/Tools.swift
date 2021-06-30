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

@inlinable func writePList(data: [String: Any]) throws {
    let j = try JSONSerialization.data(withJSONObject: data, options: [ .prettyPrinted, .sortedKeys ])
    guard let s = String(data: j, encoding: .utf8) else { throw StreamError.UnknownError(description: "Unable to encode data as UTF-8.") }
    try printToStdout(s)
}

@inlinable func printToStdout(_ str: String, terminator: String = "\n") throws {
    try printTo(filename: "/dev/stdout", str, terminator: terminator)
}

@inlinable func printToStderr(_ str: String, terminator: String = "\n") throws {
    try printTo(filename: "/dev/stderr", str, terminator: terminator)
}

@inlinable func printTo(filename: String, _ str: String, terminator: String = "\n") throws {
    try "\(str)\(terminator)".write(toFile: filename, atomically: false, encoding: .utf8)
}

@inlinable func fromJSON(_ data: String) throws -> [String: Any] {
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


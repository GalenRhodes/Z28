/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Z28
 *    FILENAME: LinesColumnsAndOffsets.swift
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

typealias LineMap = [(offset: Int64, index: String.Index)]
typealias LineColumn = (line: Int64, column: Int64)

func addLinesAndColumns(source src: LineMap, dictionary dict: [String: Any]) -> [String: Any] {
    func __foo04(source src: LineMap, array arr: [Any]) -> [Any] {
        var outArr: [Any] = []

        for object in arr {
            switch object {
                case let object as [[String: Any]]: outArr += object.map { addLinesAndColumns(source: src, dictionary: $0) }
                case let object as [String: Any]:   outArr <+ addLinesAndColumns(source: src, dictionary: object)
                case let object as [Any]:           outArr += __foo04(source: src, array: object)
                default: outArr <+ object
            }
        }

        return outArr
    }

    func __lineColumn(forOffset offset: Int64, inSource src: LineMap) -> LineColumn {
        var left  = src.startIndex
        var right = src.endIndex

        while left < right {
            let center = (((right - left) / 2) + left)
            let o      = src[center].offset
            if o == offset { return (Int64(center + 1), Int64(1)) }
            else if o < offset { left = (center + 1) }
            else { right = center }
        }

        return (Int64(left), (offset - src[left - 1].offset + 1))
    }

    func __insert(line: Int64, column: Int64, key: String, dictionary outDict: inout [String: Any]) {
        if key == "key.offset" {
            outDict["key.line"] = line
            outDict["key.column"] = column
        }
        else {
            let prefix = key.dropLast(6)
            outDict["\(prefix)line"] = line
            outDict["\(prefix)column"] = column
        }
    }

    var outDict: [String: Any] = [:]

    for (key, object) in dict {
        if key == "key.offset" || (key.hasPrefix("key.") && key.hasSuffix("offset")), let offset = (object as? Int64) {
            outDict[key] = offset

            if offset > 0 {
                let (line, column) = __lineColumn(forOffset: offset, inSource: src)
                __insert(line: line, column: column, key: key, dictionary: &outDict)
            }
            else {
                let ks = ((key == "key.offset") ? "" : String(key.dropLast(6)))
                if let l = dict["key.\(ks)length"], let length = (l as? Int64), length > 0 { __insert(line: 1, column: 1, key: key, dictionary: &outDict) }
            }
        }
        else {
            switch object {
                case let object as [[String: Any]]: outDict[key] = object.map { addLinesAndColumns(source: src, dictionary: $0) }
                case let object as [String: Any]:   outDict[key] = addLinesAndColumns(source: src, dictionary: object)
                case let object as [Any]:           outDict[key] = __foo04(source: src, array: object)
                default:                            outDict[key] = object
            }
        }
    }

    return outDict
}

func linesAndOffsets(filename: String) throws -> (source: String, lineMap: LineMap) {
    let source: String       = try String(contentsOfFile: filename, encoding: .utf8)
    var index:  String.Index = source.startIndex
    var offset: Int64        = 0
    var lines:  LineMap      = []

    guard let rx = RegularExpression(pattern: "\\R") else { fatalError("Invalid REGEX pattern: \"\\R\"") }
    rx.forEachMatch(in: source) { m, _, _ in
        if let r = m?.range.upperBound {
            lines <+ (offset, index)
            offset += Int64(source[index ..< r].utf8.count)
            index = r
        }
    }

    if index < source.endIndex {
        lines <+ (offset, index)
        offset += Int64(source[index ..< source.endIndex].utf8.count)
    }

    lines <+ (offset, source.endIndex)
    return (source, lines)
}


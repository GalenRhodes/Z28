/*===============================================================================================================================================================================*
 *     PROJECT: Z28
 *    FILENAME: SimpleIConvCharInputStream.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/7/21
 *
 * Copyright © 2021. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *===============================================================================================================================================================================*/

import Foundation
import CoreFoundation
import Rubicon

open class StopWatch: CustomStringConvertible {
    public enum NameLength { case Long, Medium, Short }

    public enum Fields {
        case Days, Hours, Mins, Secs, Millis, Micros, Nanos

        public var div: Int {
            switch self {
                case .Days:   return 1
                case .Hours:  return 24
                case .Mins:   return 60
                case .Secs:   return 60
                case .Millis: return 1000
                case .Micros: return 1000
                case .Nanos:  return 1000
            }
        }
    }

    //@f:0
    private let names: [NameLength: [Fields: String]] = [
        .Long:   [ .Days: "days", .Hours: "hours", .Mins: "minutes", .Secs: "seconds", .Millis: "milliseconds", .Micros: "microseconds", .Nanos: "nanoseconds", ],
        .Medium: [ .Days: "days", .Hours: "hrs",   .Mins: "mins",    .Secs: "secs",    .Millis: "millis",       .Micros: "micros",       .Nanos: "nanos",       ],
        .Short:  [ .Days: "d",    .Hours: "h",     .Mins: "m",       .Secs: "s",       .Millis: "ms",           .Micros: "µs",           .Nanos: "ns",          ],
    ]
    private let offset: Int
    //@f:1

    public private(set) var startTime: Int  = 0
    public private(set) var stopTime:  Int  = 0
    public private(set) var isRunning: Bool = false

    public let nameLength: NameLength
    public let lastField:  Fields

    open var elapsedTime: Int = 0
    open var days:        Int = 0
    open var hours:       Int = 0
    open var minutes:     Int = 0
    open var seconds:     Int = 0
    open var millis:      Int = 0
    open var micros:      Int = 0
    open var nanos:       Int = 0

    public init(nameLength: NameLength = .Long, lastField: Fields = .Millis) {
        self.nameLength = nameLength
        self.lastField = lastField

        var cum:  Int = 0
        var time: Int = getSysTime()

        for _ in (0 ..< 1000) {
            let t = getSysTime()
            cum += (t - time)
            time = t
        }

        self.offset = (cum / 1000)
        #if DEBUG
            print("\n\(self.offset) nanoseconds average\n")
        #endif
    }

    open func start() {
        guard !isRunning else { return }
        isRunning = true
        stopTime = 0
        elapsedTime = 0
        days = 0
        hours = 0
        minutes = 0
        seconds = 0
        millis = 0
        micros = 0
        nanos = 0
        startTime = getSysTime()
    }

    open func stop() {
        guard isRunning else { return }
        //@f:0
        stopTime    = getSysTime()
        isRunning   = false
        elapsedTime = ((stopTime == 0) ? 0 : (stopTime - startTime - offset))
        days        = (elapsedTime / 1_000_000_000 / Fields.Secs.div / Fields.Mins.div / Fields.Days.div)
        hours       = ((elapsedTime / 1_000_000_000 / Fields.Secs.div / Fields.Mins.div) % Fields.Days.div)
        minutes     = ((elapsedTime / 1_000_000_000 / Fields.Secs.div) % Fields.Mins.div)
        seconds     = ((elapsedTime / 1_000_000_000) % Fields.Secs.div)
        millis      = ((elapsedTime / 1_000_000) % Fields.Millis.div)
        micros      = ((elapsedTime / 1_000) % Fields.Micros.div)
        nanos       = (elapsedTime % Fields.Nanos.div)
        //@f:1
    }

    open var description: String {
        guard !isRunning else { return "-- Stopwatch still running." }

        guard lastField != .Days else { return fieldDesc(name: .Days, value: roundUp(value: days, next: hours, divisor: .Hours)).trimmed }
        var out = subDesc(name: .Days, values: days)

        guard lastField != .Hours else { return (out + fieldDesc(name: .Hours, value: roundUp(value: hours, next: minutes, divisor: .Mins))).trimmed }
        out += subDesc(name: .Hours, values: days, hours)

        guard lastField != .Mins else { return (out + fieldDesc(name: .Mins, value: roundUp(value: minutes, next: seconds, divisor: .Secs))).trimmed }
        out += subDesc(name: .Mins, values: days, hours, minutes)

        guard lastField != .Secs else { return (out + fieldDesc(name: .Secs, value: roundUp(value: seconds, next: millis, divisor: .Millis))).trimmed }
        out += subDesc(name: .Secs, values: days, hours, minutes, seconds)

        guard lastField != .Millis else { return (out + fieldDesc(name: .Millis, value: roundUp(value: millis, next: micros, divisor: .Micros))).trimmed }
        out += subDesc(name: .Millis, values: days, hours, minutes, seconds, millis)

        guard lastField != .Micros else { return (out + fieldDesc(name: .Micros, value: roundUp(value: micros, next: nanos, divisor: .Nanos))).trimmed }
        out += subDesc(name: .Micros, values: days, hours, minutes, seconds, millis, micros)

        guard lastField != .Nanos else { return (out + fieldDesc(name: .Nanos, value: nanos)).trimmed }
        out += subDesc(name: .Nanos, values: days, hours, minutes, seconds, millis, micros, nanos)

        return out.trimmed
    }

    private func roundUp(value: Int, next: Int, divisor: Fields) -> Int { (value + ((next + (divisor.div / 2)) / divisor.div)) }

    private func fieldDesc(name: Fields, value: Int) -> String { "\(value) \(names[nameLength]![name]!) " }

    private func subDesc(name: Fields, values: Int...) -> String {
        var mask = true
        let cc   = values.count
        let lIdx = (values.endIndex - 1)

        if cc == 0 { return "" }
        if cc == 1 { let fVal = values[0]; return ((fVal > 0) ? fieldDesc(name: name, value: fVal) : "") }
        for x in (values.startIndex ..< lIdx) { if values[x] > 0 { mask = false; break } }

        let lVal = values[lIdx]
        return ((mask && (lVal <= 0)) ? "" : fieldDesc(name: name, value: lVal))
    }
}

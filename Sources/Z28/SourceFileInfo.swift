/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Z28
 *    FILENAME: SourceFileInfo.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/2/21
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

public typealias CountHelper = () -> (Int, Int)

open class SourceFileInfo {

    public let module:   Module
    public let filename: String
    public let tempDir:  String
    public var error:    Error?

    public private(set) var source:    String        = ""
    public private(set) var fileIndex: [String: Any] = [:]
    public private(set) var structure: [String: Any] = [:]
    public private(set) var swiftDocs: [String: Any] = [:]
    public private(set) var syntaxMap: [String: Any] = [:]
    public private(set) var lineMap:   LineMap       = []

    private lazy var messageCounter: String = { let c = counter(); return "\(c.0)/\(c.1)" }()
    private lazy var messagePrefix: String = "\(messageCounter): \(filename) ..."

    private let counter: CountHelper

    public init(filename: String, temporaryDirectory tempDir: String, module: Module, counter: @escaping CountHelper = { (1, 1) }) throws {
        self.counter = counter
        self.module = module
        self.filename = filename
        self.tempDir = tempDir.appendingPathComponent(filename.lastPathComponent)
    }

    public func loadAndWrite(printLock: Locking? = nil) {
        var err: Error? = nil
        loadAndWrite(printLock: printLock, error: &err)
    }

    public func loadAndWrite(printLock: Locking? = nil, error err: inout Error?) {
        error = nil
        if load(printLock: printLock, suppressMessage: true) { writeDebugFiles(printLock: printLock) }
        err = error
    }

    public func load(printLock: Locking? = nil, suppressMessage: Bool = false) -> Bool {
        do {
            guard let file: File = File(path: filename) else { throw StreamError.FileNotFound(description: filename) }
            source = try String(contentsOfFile: filename, encoding: .utf8)
            lineMap = getLinesAndOffsets(source: source)
            fileIndex = try getFileIndex()
            structure = try getStructure(file)
            swiftDocs = try getSwiftDocs(file)
            syntaxMap = try getSyntaxMap(file)
            if !suppressMessage { printSuccess(printLock: printLock) }
            return true
        }
        catch let e {
            printFailure(printLock: printLock, error: e)
            error = e
            return false
        }
    }

    @discardableResult private func writeDebugFiles(printLock: Locking?) -> Bool {
        var areas: [String] = []

        //@f:0
        do { try writePList(data: fileIndex, toFile: "\(tempDir).index.json")     } catch let e { areas <+ "file index"; error = e }
        do { try writePList(data: structure, toFile: "\(tempDir).structure.json") } catch let e { areas <+ "structure";  error = e }
        do { try writePList(data: swiftDocs, toFile: "\(tempDir).docs.json")      } catch let e { areas <+ "SwiftDocs";  error = e }
        do { try writePList(data: syntaxMap, toFile: "\(tempDir).syntax.json")    } catch let e { areas <+ "syntax map"; error = e }
        //@f:1

        if areas.isEmpty {
            printSuccess(printLock: printLock)
            return true
        }
        else {
            let lidx = (areas.count - 1)
            let msg  = "Failed to write \(areas[0])\((lidx == 0) ? "" : ((lidx == 1) ? "and \(areas[1])" : "\(areas[1 ..< lidx].joined(separator: ", ")), and \(areas[lidx])"))"
            printFailure(printLock: printLock, message: msg, error: error!)
            return false
        }
    }

    private func printFailure(printLock: Locking?, message msg: String? = nil, error e: Error) {
        printLock?.lock()
        defer { printLock?.unlock() }
        let pfx = "\(messagePrefix) ❌"
        if let msg = msg { printToStderr("\(pfx) \(msg): \(e)") }
        else { printToStderr("\(pfx): \(e)") }
    }

    private func printSuccess(printLock: Locking?) {
        printLock?.lock()
        defer { printLock?.unlock() }
        printToStdout("\(messagePrefix) ✅")
    }

    private func getFileIndex() throws -> [String: Any] {
        toDictionary(try Request.index(file: filename, arguments: module.compilerArguments).send())
    }

    private func getStructure(_ file: File) throws -> [String: Any] {
        addLinesAndColumns(source: lineMap, dictionary: toDictionary(try Structure(file: file).dictionary))
    }

    private func getSwiftDocs(_ file: File) throws -> [String: Any] {
        guard let sd = SwiftDocs(file: file, arguments: module.compilerArguments) else { throw PGErrors.UnexpectedError(description: "Unable to get SwiftDocs for file: \(filename)") }
        return addLinesAndColumns(source: lineMap, dictionary: toDictionary(sd.docsDictionary))
    }

    private func getSyntaxMap(_ file: File) throws -> [String: Any] {
        let x: [[String: Any]] = try SyntaxMap(file: file).tokens.map { $0.dictionaryValue }
        let y: [[String: Any]] = x.map { $0.remapValues { ("key.\($0)", mapIntToInt64($1)) } }
        return addLinesAndColumns(source: lineMap, dictionary: [ "key.syntaxmap": y ])
    }
}

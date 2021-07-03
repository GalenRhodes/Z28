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

open class SourceFileInfo {

    let module:     Module
    let filename:   String
    let tempDir:    String
    let fileNumber: Int
    let fileCount:  Int

    private(set) var source:    String        = ""
    private(set) var fileIndex: [String: Any] = [:]
    private(set) var structure: [String: Any] = [:]
    private(set) var swiftDocs: [String: Any] = [:]
    private(set) var syntaxMap: [String: Any] = [:]
    private(set) var lineMap:   LineMap       = []

    public init(filename: String, temporaryDirectory tempDir: String, module: Module, fileNumber: Int = 1, outOf fileCount: Int = 1) throws {
        self.fileNumber = fileNumber
        self.fileCount = fileCount
        self.module = module
        self.filename = filename
        self.tempDir = tempDir.appendingPathComponent(filename.lastPathComponent)
    }

    func load() -> Bool {
        do {
            guard let file: File = File(path: filename) else { throw StreamError.FileNotFound(description: filename) }
            source = try String(contentsOfFile: filename, encoding: .utf8)
            lineMap = getLinesAndOffsets(source: source)
            fileIndex = try getFileIndex()
            structure = try getStructure(file)
            swiftDocs = try getSwiftDocs(file)
            syntaxMap = try getSyntaxMap(file)

            printToStdout("\(fileNumber)/\(fileCount): \(filename) ... ✅")
            return true
        }
        catch let e {
            printToStderr("\(fileNumber)/\(fileCount): \(filename) ... ❌ : \(e)")
            return false
        }
    }

    func writeDebugFiles() {
        //@f:0
        do { try writePList(data: fileIndex, toFile: "\(tempDir).index.json")     } catch let e { printToStderr("❌ Failed to write file index for \"\(filename.lastPathComponent)\": \(e)") }
        do { try writePList(data: structure, toFile: "\(tempDir).structure.json") } catch let e { printToStderr("❌ Failed to write structure for \"\(filename.lastPathComponent)\": \(e)") }
        do { try writePList(data: swiftDocs, toFile: "\(tempDir).docs.json")      } catch let e { printToStderr("❌ Failed to write SwiftDocs for \"\(filename.lastPathComponent)\": \(e)") }
        do { try writePList(data: syntaxMap, toFile: "\(tempDir).syntax.json")    } catch let e { printToStderr("❌ Failed to write syntax map for \"\(filename.lastPathComponent)\": \(e)") }
        //@f:1
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

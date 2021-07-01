/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Z28
 *    FILENAME: Z28.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/30/21
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
import SourceKit
import SourceKittenFramework

//@main
open class Z28 {

    let cmdArguments: [String]

    public lazy var cwd:      String  = FileManager.default.currentDirectoryPath
    public lazy var filename: String  = "\(cwd)/\(cmdArguments[1])"
    public lazy var source:   String  = ((try? String(contentsOfFile: filename, encoding: .utf8)) ?? "")
    public lazy var lineMap:  LineMap = linesAndOffsets(source: source)

    public init(args: [String]) throws { self.cmdArguments = args }

    open func run() throws -> Int32 {
        guard let module: Module = Module(xcodeBuildArguments: [ "-scheme", "Z28" ], inPath: cwd) else { throw PGErrors.GeneralError(description: "Unable to build module.") }
        guard let file: File = File(path: filename) else { throw StreamError.FileNotFound(description: filename) }

        let (_, lineMap): (String, LineMap) = try linesAndOffsets(filename: file.path!)
        let dict1:        [String: Any]     = try fileIndex(file: file, module: module)
        let dict2:        [String: Any]     = try fileStructure(file: file, lineMap: lineMap)
        let dict3:        [String: Any]     = try fileDocs(file: file, module: module, lineMap: lineMap)
        let dict4:        [String: Any]     = try fileSyntax(file: file, module: module, lineMap: lineMap)

        try writePList(data: dict1, toFile: "\(cwd)/Resources/\(filename.lastPathComponent).index.json")
        try writePList(data: dict2, toFile: "\(cwd)/Resources/\(filename.lastPathComponent).structure.json")
        try writePList(data: dict3, toFile: "\(cwd)/Resources/\(filename.lastPathComponent).docs.json")
        try writePList(data: dict4, toFile: "\(cwd)/Resources/\(filename.lastPathComponent).syntax.json")
        return 0
    }

    public static func main() {
        do {
            exit(try Z28(args: CommandLine.arguments).run())
        }
        catch let e {
            try? "ERROR: \(e)".write(toFile: "/dev/stderr", atomically: false, encoding: .utf8)
            exit(1)
        }
    }

    /*=========================================================================================================================*/
    /// Index a source file.
    ///
    /// - Parameters:
    ///   - file: The filename.
    ///   - module: The module information.
    /// - Returns: The index of the file.
    /// - Throws: If an error occurs.
    ///
    open func fileIndex(file: File, module: Module) throws -> [String: Any] {
        guard let filename = file.path else { return [:] }
        return toDictionary(try Request.index(file: filename, arguments: module.compilerArguments).send())
    }

    open func fileStructure(file: File, lineMap: LineMap) throws -> [String: Any] {
        addLinesAndColumns(source: lineMap, dictionary: toDictionary(try Structure(file: file).dictionary))
    }

    open func fileDocs(file: File, module: Module, lineMap: LineMap) throws -> [String: Any] {
        guard let docs = SwiftDocs(file: file, arguments: module.compilerArguments) else { return [:] }
        return addLinesAndColumns(source: lineMap, dictionary: toDictionary(docs.docsDictionary))
    }

    open func fileSyntax(file: File, module: Module, lineMap: LineMap) throws -> [String: Any] {
        let b = try SyntaxMap(file: file).tokens.map { $0.dictionaryValue }.map { $0.remapValues { return ("key.\($0)", (isType($1, Int.self) ? Int64($1 as! Int) : $1)) } }
        let e = [ "key.syntaxmap": b ]
        return addLinesAndColumns(source: lineMap, dictionary: e)
    }
}

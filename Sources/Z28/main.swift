//
//  main.swift
//  Z28
//
//  Created by Galen Rhodes on 6/24/21.
//

import Foundation
import CoreFoundation
import SourceKittenFramework
import Rubicon

let xcodePath    = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
let compilerArgs = [ "-sdk", xcodePath, "-I", "\(xcodePath)/usr/include", "-F", "\(xcodePath)/System/Library/PrivateFrameworks", ]

func DoTest() throws {
    let cwd      = FileManager.default.currentDirectoryPath
    let pwd      = "\(cwd)/\(CommandLine.arguments[1])"
    let filename = "\(pwd)/\(CommandLine.arguments[2])"
    print("Filename: \(filename)")

//    let sourceFiles: [String] = try FileManager.default.directoryFiles(atPath: pwd) { _, f, a in ((a.fileType == .typeRegular) && f.hasSuffix(".swift")) }

    let (_, lineMap): (String, LineMap) = try linesAndOffsets(filename: filename)
    guard let module: Module = Module(xcodeBuildArguments: [ "-scheme", "Z28" ], inPath: cwd) else { throw PGErrors.GeneralError(description: "Unable to build module.") }
    module.compilerArguments.forEach { try? printToStdout($0) }

    let docs: [SwiftDocs] = module.docs
    try docs.forEach { d in
        try printToStdout("\n=======================================================================================================================================================================\n")
        try writePList(data: addLinesAndColumns(source: lineMap, dictionary: toDictionary(d.docsDictionary)))
    }

//    guard let file = File(path: filename) else { throw StreamError.FileNotFound(description: filename) }
//    if let path = file.path {
//        try printToStdout("File path: \(path)")
//        let dict4: [String: Any] = toDictionary(try Request.cursorInfo(file: path, offset: 0, arguments: module.compilerArguments).send())
//        try writePList(data: dict4)
//    }

//    let dict1: [String: Any] = try IndexFile(filename: filename, compilerArguments: module.compilerArguments)
//    let dict2: [String: Any] = addLinesAndColumns(source: lineMap, dictionary: try FileStructure(filename: filename))
//    let dict3: [String: Any] = try fromJSON(module.docs.description)

//    try writePList(data: dict1)
//    try writePList(data: dict2)
//    try writePList(data: dict3)

//    let file:      File          = File(path: filename)!
//    let something: [String: Any] = toDictionary(try Request.editorOpen(file: file).send())
//    try writePList(data: addLinesAndColumns(source: lineMap, dictionary: something))
}

/// Index a source file.
///
/// - Parameters:
///   - filename: The filename.
///   - args: The command line arguments for xcodebuild.
/// - Returns: The index of the file.
/// - Throws: If an error occurs.
///
func IndexFile(filename: String, compilerArguments args: [String]) throws -> [String: Any] {
    toDictionary(try Request.index(file: filename, arguments: args).send())
}

func FileStructure(filename: String) throws -> [String: Any] {
    guard let file = File(path: filename) else { throw StreamError.FileNotFound(description: filename) }
    return toDictionary(try Structure(file: file).dictionary)
}

DispatchQueue.main.async {
    do {
        try DoTest()
        exit(0)
    }
    catch let e {
        print("ERROR: \(e)")
        exit(1)
    }
}

dispatchMain()

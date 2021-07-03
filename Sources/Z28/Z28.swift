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
import ArgumentParser

let lock = Conditional()

//@main
open class Z28: ParsableCommand {

    public enum BuildMethod: EnumerableFlag {
        case xcode
        case spm
    }

    //@f:0
    @Option(name: .shortAndLong,   help: "The name of the file to clean up.")              public var filename:       String?
    @Option(name: .shortAndLong,   help: "The directory to write the temporary files to.") public var tempDir:        String      = "Resources"
    @Flag(exclusivity: .exclusive, help: "Which build method to use.")                     public var buildMethod:    BuildMethod = .xcode
    @Argument(parsing: .remaining, help: "Build arguments.")                               public var buildArguments: [String]
    @Option(name: .long,           help: "Path of the project root.")                      public var projectPath:    String?
    @Flag(help: "Use multiple threads.")                                                   public var threads:        Bool        = false
    //@f:1

    public required init() {}

    public func run() throws {
        let projectPath: String = (projectPath ?? FileManager.default.currentDirectoryPath)
        let td                  = tempDir.makeAbsolute(relativeTo: projectPath)

        printToStdout("BUILD METHOD: \(buildMethod)")
        printToStdout("  BUILD ARGS: [ \"\(buildArguments.joined(separator: "\", \""))\" ]")
        printToStdout("PROJECT PATH: \(projectPath)")
        printToStdout("    TEMP DIR: \(td)")

        guard let module: Module = Module(xcodeBuildArguments: buildArguments, inPath: projectPath) else { throw PGErrors.GeneralError(description: "Unable to build module.") }

        if let filename = filename?.makeAbsolute(relativeTo: projectPath) {
            let sourceFile = try SourceFileInfo(filename: filename, temporaryDirectory: td, module: module)
            if sourceFile.load() { sourceFile.writeDebugFiles() }
        }
        else {
            NSLog("Start...")
            var sources: [SourceFileInfo] = []
            let cc:      Int              = module.sourceFiles.count

            for x in (0 ..< cc) {
                let sourceFile = try SourceFileInfo(filename: module.sourceFiles[x], temporaryDirectory: td, module: module, fileNumber: x + 1, outOf: cc)
                sources <+ sourceFile
            }

            if threads {
                let lock: Conditional = Conditional()
                var thds: [Thread]    = []
                var idx:  Int         = 0
                var tcc:  Int         = 0

                for _ in (0 ..< 8) {
                    let t = Thread {
                        while let sf = lock.withLock({ idx < cc ? sources[idx++] : nil }) {
                            if sf.load() {
                                sf.writeDebugFiles()
                            }
                        }
                        lock.withLock { tcc -= 1 }
                    }
                    thds <+ t
                    t.start()
                }

                lock.withLock { while tcc > 0 { lock.broadcastWait() } }
            }
            else {
                for sf: SourceFileInfo in sources {
                    if sf.load() {
                        sf.writeDebugFiles()
                    }
                }
            }
            NSLog("End...")
        }
    }
}

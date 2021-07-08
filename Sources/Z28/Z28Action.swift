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
import ArgumentParser
import SourceKittenFramework
import Rubicon

public struct Z28Action {

    public enum BuildMethod: EnumerableFlag {
        case xcode
        case spm
    }

    public let projectPath:    String
    public let filename:       String?
    public let tempDir:        String
    public let jobs:           Int
    public let buildMethod:    BuildMethod
    public var buildArguments: [String]

    public init(projectPath: String, filename: String?, tempDir: String, jobs: Int, buildMethod: BuildMethod, buildArguments: [String]) {
        self.projectPath = projectPath
        self.filename = filename
        self.tempDir = tempDir
        self.jobs = jobs
        self.buildMethod = buildMethod
        self.buildArguments = buildArguments
    }

    public func run() throws {
        let sw = StopWatch(labelLength: .Short, lastField: .Nanos, start: true)

        guard let module: Module = Module(xcodeBuildArguments: buildArguments, inPath: projectPath) else {
            throw PGErrors.GeneralError(description: "Unable to build module.")
        }

        if let filename = filename?.makeAbsolute(relativeTo: projectPath) {
            var err: Error? = nil
            try SourceFileInfo(filename: filename, temporaryDirectory: tempDir, module: module).loadAndWrite(error: &err)
            if let e = err { throw e }
        }
        else {
            let cc: Int = module.sourceFiles.count

            if jobs > 1 {
                let t: ThreadWorker = ThreadWorker(threadCount: jobs)
                for x in (0 ..< cc) {
                    try t.addSourceFile(filename: module.sourceFiles[x], temporaryDirectory: tempDir, module: module)
                }
                t.launchAndWait()
            }
            else {
                for x in (0 ..< cc) {
                    let sf = try SourceFileInfo(filename: module.sourceFiles[x], temporaryDirectory: tempDir, module: module) { ((x + 1), cc) }
                    sf.loadAndWrite()
                }
            }
        }

        sw.stop()
        printToStdout("\nElapsed Nanoseconds: \(sw.elapsedTime)")
        printToStdout("\(sw)")
    }
}

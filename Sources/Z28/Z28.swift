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

//@main
open class Z28: ParsableCommand {

    //@f:0
    @Option(name: .long,           help: "Path of the project root.")                      public var projectPath:    String?
    @Option(name: .shortAndLong,   help: "The name of the file to clean up.")              public var filename:       String?
    @Option(name: .shortAndLong,   help: "The directory to write the temporary files to.") public var tempDir:        String                = "Resources"
    @Option(name: .shortAndLong,   help: "The number of jobs to spawn in parallel.")       public var jobs:           Int                   = 1
    @Flag(exclusivity: .exclusive, help: "Which build method to use.")                     public var buildMethod:    Z28Action.BuildMethod = .xcode
    @Argument(parsing: .remaining, help: "Build arguments.")                               public var buildArguments: [String]
    //@f:1

    public required init() {}

    public func validate() throws {
        guard jobs >= 1 else { throw ValidationError("Jobs parameter must be greater than zero.") }
        guard buildArguments.isNotEmpty else { throw ValidationError("Build arguments are required.") }
    }

    public func run() throws {
        let projectPath: String = (projectPath ?? FileManager.default.currentDirectoryPath)
        let absTempDir:  String = tempDir.makeAbsolute(relativeTo: projectPath)

        switch buildMethod {
            case .xcode:
                buildArguments += [ "-jobs", "\(jobs)", "-configuration", "Debug", ]
            case .spm:
                buildArguments += [ "--jobs", "\(jobs)", "--configuration", "debug", ]
        }

        printToStdout("BUILD METHOD: \(buildMethod)")
        printToStdout("  BUILD ARGS: [ \"\(buildArguments.joined(separator: "\", \""))\" ]")
        printToStdout("PROJECT PATH: \(projectPath)")
        printToStdout("    TEMP DIR: \(absTempDir)")

        try Z28Action(projectPath: projectPath, filename: filename, tempDir: absTempDir, jobs: jobs, buildMethod: buildMethod, buildArguments: buildArguments).run()
    }
}

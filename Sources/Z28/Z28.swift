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
    @Option(name: .shortAndLong,   help: "The Swift Package Manager module.")              public var moduleName:     String?
    @Option(name: .shortAndLong,   help: "The directory to write the temporary files to.") public var tempDir:        String                = "Resources"
    @Option(name: .shortAndLong,   help: "The number of jobs to spawn in parallel.")       public var jobs:           Int                   = 1
    @Flag(exclusivity: .exclusive, help: "Which build method to use.")                     public var buildMethod:    Z28Action.BuildMethod = .xcode
    @Argument(parsing: .remaining, help: "Build arguments.")                               public var buildArguments: [String]              = []
    //@f:1

    public required init() {}

    public func validate() throws {
        if jobs < 1 { throw ValidationError("Jobs parameter must be greater than zero.") }
        if buildMethod == .xcode && buildArguments.isEmpty { throw ValidationError("Build arguments are required when using XCODE build method.") }
        if buildMethod == .spm && moduleName == nil { printToStderr("WARNING: It is a good idea to provide a module name when using the SPM build method.") }
    }

    public func run() throws {
        let projectPath: String = (projectPath ?? FileManager.default.currentDirectoryPath).makeAbsolute()
        let tempDir:     String = tempDir.makeAbsolute(relativeTo: projectPath)
        if let f = filename { filename = f.makeAbsolute(relativeTo: projectPath) }

        switch buildMethod {
            case .xcode: buildArguments += [ "-jobs", "\(jobs)", "-configuration", "Debug", ]
            case .spm:   buildArguments += [ "-j", "\(jobs)", "-c", "debug", ]
        }

        printToStdout("BUILD METHOD: \(buildMethod)")
        printToStdout("        JOBS: \(jobs)")
        printToStdout("    FILENAME: \(filename ?? "")")
        printToStdout(" MODULE NAME: \(moduleName ?? "")")
        printToStdout("  BUILD ARGS: [ \"\(buildArguments.joined(separator: "\", \""))\" ]")
        printToStdout("PROJECT PATH: \(projectPath)")
        printToStdout("    TEMP DIR: \(tempDir)")

        try Z28Action(projectPath: projectPath, filename: filename, moduleName: moduleName, tempDir: tempDir, jobs: jobs, buildMethod: buildMethod, buildArguments: buildArguments).run()
    }
}

//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 6/24/21.
//

import Foundation
import PGDocFixer
import ArgumentParser

struct DocFixer: ParsableCommand {
    enum DocFormat: String, EnumerableFlag {
        case html
        case markdown
    }

    enum CommentType: String, EnumerableFlag {
        case slashes
        case stars
    }

    //@f:0
    static let configuration: CommandConfiguration = CommandConfiguration(commandName: "DocFixer",
                                                                          abstract:    "Clean up documentation comments.",
                                                                          discussion:  "DocFixer cleans up the documentation comments in Swift source code files.")

    @Option(name: .shortAndLong,   help: "The max line length.")                                 var lineLength:       Int         = 180
    @Option(name: .shortAndLong,   help: "The name of the project.")                             var project:          String
    @Option(name: .shortAndLong,   help: "The output directory.")                                var outputPath:       String
    @Option(name: .long,           help: "The remote host name to upload the documentation to.") var remoteHost:       String
    @Option(name: .long,           help: "The username for the remote host.")                    var remoteUser:       String
    @Option(name: .long,           help: "The path on the remote host to write the files to.")   var remotePath:       String
    @Option(name: .shortAndLong,   help: "The archive filename.")                                var archive:          String      = "archive.tar"
    @Option(name: .shortAndLong,   help: "The file to use as a date reference.")                 var referenceFile:    String      = "index.pdf"
    @Option(name: .shortAndLong,   help: "The version of Jazzy to use.")                         var jazzyVersion:     String?
    @Flag(exclusivity: .exclusive, help: "The format for the documentation.")                    var swiftDocFormat:   DocFormat?
    @Flag(exclusivity: .exclusive, help: "Source comment style.")                                var commentType:      CommentType = .slashes
    @Argument(parsing: .remaining, help: "The source file directories.")                         var projectSourceDir: [String]

    init() {}

    func run() throws {
        var y: [String] = [ CommandLine.arguments[0] ]

        if let s = jazzyVersion { y += [ "--jazzy-version", s ] }
        else if let s = swiftDocFormat { y += [ "--swift-doc-format", s.rawValue ] }
        else { y += [ "--jazzy-version", "0.13.7" ] }

        y += [ "--line-length",    "\(lineLength)",
               "--project",        project,
               "--output-path",    outputPath,
               "--remote-host",    remoteHost,
               "--remote-user",    remoteUser,
               "--remote-path",    remotePath,
               "--archive-file",   archive,
               "--log-file",       referenceFile,
               "--comment-type",   commentType.rawValue,
               "--" ]

        y += projectSourceDir

        _ = doDocFixer(args: y, replacements: [])
    }

    mutating func validate() throws {
        if jazzyVersion == nil && swiftDocFormat == nil {
            jazzyVersion = "0.13.7"
        }
        if lineLength > 200 {
            lineLength = 200
        }
        else if lineLength < 80 {
            lineLength = 80
        }
    }
}

DispatchQueue.main.async { DocFixer.main(); exit(0) }
dispatchMain()

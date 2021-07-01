//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 6/24/21.
//

import Foundation
import PGDocFixer

DispatchQueue.main.async {
    exit(Int32(truncatingIfNeeded: doDocFixer(args: CommandLine.arguments, replacements: [])))
}
dispatchMain()

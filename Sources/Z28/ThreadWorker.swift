/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Z28
 *    FILENAME: ThreadWorker.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 7/6/21
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

open class ThreadWorker {
    //@f:0
    public var isDone:      Bool             { (done && (activeThreads <= 0)) }
    public var sourceFiles: [SourceFileInfo] { sources.map { $0 } /* Copy */  }
    //@f:1

    private let lock:          Conditional      = Conditional()
    private var threads:       [Thread]         = []
    private var sources:       [SourceFileInfo] = []
    private var done:          Bool             = false
    private var idx:           Int              = 0
    private var ccc:           Int              = 0
    private var activeThreads: Int              = 0

    public init(threadCount: Int) {
        for _ in (0 ..< threadCount) { threads <+ Thread { self.threadAction() } }
    }

    open func launchAndWait() {
        lock.withLock {
            guard !done else { fatalError("ThreadWorker was already launched.") }
            done = true

            for t in threads {
                t.qualityOfService = .userInteractive
                t.start()
                activeThreads += 1
            }

            while activeThreads > 0 {
                lock.broadcastWait()
            }
        }
    }

    open func addSourceFile(_ sourceFile: SourceFileInfo) {
        lock.withLock {
            guard !done else { return }
            sources <+ sourceFile
        }
    }

    func counterHelper() -> (Int, Int) { (++ccc, sources.count) }

    private func threadAction() {
        while let sf = nextSource() {
            sf.loadAndWrite(printLock: lock)
        }
        lock.withLock {
            activeThreads -= 1
        }
    }

    private func nextSource() -> SourceFileInfo? {
        lock.withLock {
            guard idx < sources.count else { return nil }
            return sources[idx++]
        }
    }
}

//
// Created by Roman Serga on 4/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

@objc(MWSynchronizationProcessDelegate)
public protocol SynchronizationProcessDelegate: class {
    func senderSynchronizationProcessDidFinishSynchronization(_ synchronizationProcess: AbstractSynchronizationProcess)
    func senderSynchronizationProcess(_ synchronizationProcess: AbstractSynchronizationProcess,
                                      didFailedSynchronizationWithError error: Error?)
}

@objc(MWSynchronizationProcessState)
public class SynchronizationProcessState: NSObject {
    @objc public static let none = SynchronizationProcessState(name: "none")
    @objc public static let error = SynchronizationProcessState(name: "error")
    @objc public static let finished = SynchronizationProcessState(name: "finished")

    @objc public private(set) var name: String

    @objc init(name: String) {
        self.name = name
    }

    public static func == (lhs: SynchronizationProcessState, rhs: SynchronizationProcessState) -> Bool {
        return lhs.name == rhs.name
    }
}

@objc (MWAbstractSynchronizationProcess)
public class AbstractSynchronizationProcess: NSObject {
    @objc public weak var delegate: SynchronizationProcessDelegate?
    @objc public var state: SynchronizationProcessState = .none

    private var error: Error?

    @objc public func startSynchronization() {
        self.iterate()
    }

    @objc public func startSynchronizationFrom(state: SynchronizationProcessState) {
        self.state = state
        self.startSynchronization()
    }

    private func iterate() {
        guard self.state != .finished else {
            self.delegate?.senderSynchronizationProcessDidFinishSynchronization(self)
            return
        }

        guard self.state != .error else {
            self.delegate?.senderSynchronizationProcess(self, didFailedSynchronizationWithError: error)
            return
        }

        self.performActionFor(state: self.state) { error in
            if error != nil {
                self.state = .error
                self.error = error
            } else {
                do {
                    try self.state = self.nextStateAfter(state: self.state)
                } catch let error as NSError {
                    self.error = error
                    self.state = .error
                } catch {
                    let error = NSError(domain: "Cannot get next state for state: \(self.state.name)", code: 1)
                    self.error = error
                    self.state = .error
                }
            }
            self.iterate()
        }
    }

    @objc open func nextStateAfter(state: SynchronizationProcessState) throws -> SynchronizationProcessState {
        fatalError("Method must be overridden by subclass")
    }

    @objc open func performActionFor(state: SynchronizationProcessState, completion: @escaping ((Error?) -> Void)) {
        fatalError("Method must be overridden by subclass")
    }
}

//
// Created by Roman Serga on 19/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

protocol ContainerViewProtocol: class {
    associatedtype ChildViewType

    var childViews: [ChildViewType] { get set }

    func setChildViews(_ childViewsToSet: [ChildViewType], animated: Bool, completion: (() -> Void)?)
    func presentChildView(_ view: ChildViewType, animated: Bool, completion: (() -> Void)?)
    func dismissChildView(_ view: ChildViewType, animated: Bool, completion: (() -> Void)?)
}
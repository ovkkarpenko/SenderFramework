//
// Created by Roman Serga on 24/4/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation
import UIKit

class MainScreenView: PageContainerViewController,
                      MainScreenViewProtocol {

    var presenter: MainScreenPresenterProtocol?

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.viewWasLoaded()
        self.presenter?.showChatList()
        SenderCore.shared().stylePalette.customize(self.navigationItem)
        self.view.backgroundColor = SenderCore.shared().stylePalette.mainAccentColor
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        //Workaround for quick swipe-to-back to other controller and back
        DispatchQueue.main.async { self.navigationController?.setNavigationBarHidden(true, animated: animated) }
    }
}

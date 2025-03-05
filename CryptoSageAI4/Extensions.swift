//
//  Extensions.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}

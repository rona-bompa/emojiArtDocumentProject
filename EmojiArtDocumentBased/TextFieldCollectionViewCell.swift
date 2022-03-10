//
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Rona Bompa on 07.03.2022.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }

    var resignationHandler: (() -> Void)? // because we dont have a pointer to it

    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // when we press enter on the keyboard, the keyboard goes away
        return true
    }
}

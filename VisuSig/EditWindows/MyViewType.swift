//
//  MyViewType.swift
//  MyViewType
//
//  Created by Sinan Karasu on 10/12/21.
//

import Foundation

enum MyViewType: Equatable {
    case formContainer // main container
    case fieldContainer // contains a text label + text field
    case field(Int) // text field (with an associated value that indicates the character count in the field)
    case title // form title
    case miniMapArea // view placed behind the minimap elements
}

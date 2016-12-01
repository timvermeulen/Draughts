//
//  [Array]+==.swift
//  Draughts
//
//  Created by Tim Vermeulen on 01/12/2016.
//
//

internal func == <T: Equatable> (left: [[T]], right: [[T]]) -> Bool {
    return left.count == right.count && !zip(left, right).contains(where: !=)
}

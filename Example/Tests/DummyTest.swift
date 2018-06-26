//
//  DummyTest.swift
//  Tests
//
//  Created by Oliver Letterer on 25.06.18.
//  Copyright © 2018 Oliver Letterer. All rights reserved.
//

import Foundation
import XCTest

protocol FormValue: CustomStringConvertible {

}

extension Date: FormValue {

}

enum GenericFormField<Object, Value> where Value: FormValue {
    case date(object: Object, keyPath: ReferenceWritableKeyPath<Object, Value>)
}

class DummyTest: CBRTestCase {
    @objc class DummyJSON: CBRJSONObject {
        @objc var date: Date = Date()
    }

    func testNothing() {
//        let keypath: ReferenceWritableKeyPath<DummyTest.DummyJSON, Date> = \DummyJSON.date
        let _ = GenericFormField<DummyJSON, Date>.date(object: DummyJSON(), keyPath: \DummyJSON.date)

//        let keypath: ReferenceWritableKeyPath<DummyTest.DummyJSON, DateConvertible> = \DummyJSON.date
//        let bla = DummyJSON()[keyPath: keypath]
//        DummyJSON()[keyPath: keypath] = bla
    }
}

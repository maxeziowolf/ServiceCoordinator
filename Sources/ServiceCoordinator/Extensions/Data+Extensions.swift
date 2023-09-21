//
//  File.swift
//  
//
//  Created by Maximiliano Ovando Ramírez on 20/09/23.
//

import UIKit

extension Data {
    func toString() -> String {
        if let dataInfo = String(data: self, encoding: .utf8) {
            return dataInfo
        }

        return "Sin informacion"
    }
}


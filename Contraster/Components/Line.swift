//
//  Line.swift
//  Contraster
//
//  Created by George Gillams on 05/09/2022.
//

import SwiftUI

struct Line: View {
    var body: some View {
        Rectangle().fill(.gray).frame(height: 1)
    }
}

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        Line()
    }
}

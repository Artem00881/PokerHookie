
import SwiftUI

public struct MoneyField: View {
    let title: String
    @Binding var value: Int

    public init(title: String, value: Binding<Int>) {
        self.title = title
        self._value = value
    }

    public var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 80)
        }
    }
}

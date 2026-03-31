import SwiftUI

struct HeaderBar: View {
    var isSignedIn: Bool
    var signInAction: () -> Void
    var signOutAction: () -> Void

    var body: some View {
        HStack {
            logoContent
                .accessibilityElement(children: .combine)
                .accessibilityLabel("RoamEasy")

            Spacer()

            Button(action: isSignedIn ? signOutAction : signInAction) {
                Image(systemName: isSignedIn ? "rectangle.portrait.and.arrow.right" : "person.crop.circle")
                    .font(.title2)
                    .foregroundStyle(Color(.label))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(isSignedIn ? "Sign out" : "Sign in")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var logoContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe.americas")
                .font(.title3)
            Text("RoamEasy")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color(.label))
    }
}

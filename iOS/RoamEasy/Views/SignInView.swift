import SwiftUI

struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    var onSignedIn: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bookmark.circle")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Sign in to save places")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create a free account to bookmark your favorite attractions and access them anytime.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                isSigningIn = true
                Task {
                    let success = await authManager.signIn()
                    isSigningIn = false
                    if success {
                        onSignedIn()
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                    }
                    Text("Sign in with Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isSigningIn)
            .padding(.horizontal, 40)

            Button("Not now") {
                dismiss()
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

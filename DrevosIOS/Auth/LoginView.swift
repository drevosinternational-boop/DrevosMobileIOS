import SwiftUI

struct LoginView: View {
    @ObservedObject var auth: AuthSession
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            DrevosTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    Spacer(minLength: 90)

                    Text("D")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(DrevosTheme.orange)
                        .frame(width: 56, height: 56)
                        .background(Color(hex: 0x171717))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(DrevosTheme.orange, lineWidth: 1))

                    Text("Welcome back")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(DrevosTheme.text)
                        .padding(.top, 8)

                    Text("Sign in to control your smoker")
                        .font(.system(size: 14))
                        .foregroundStyle(DrevosTheme.muted)
                        .padding(.bottom, 14)

                    DrevosTextField(title: "Email", text: $email, keyboard: .emailAddress)
                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .foregroundStyle(DrevosTheme.text)
                        .background(DrevosTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DrevosTheme.border))

                    Button("Forgot password?") { auth.resetPassword(email: email) }
                        .font(.system(size: 13))
                        .foregroundStyle(DrevosTheme.orange)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if let error = auth.errorMessage {
                        Text(error).foregroundStyle(.red).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let info = auth.infoMessage {
                        Text(info).foregroundStyle(.green).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        auth.signIn(email: email, password: password)
                    } label: {
                        Text("Sign in")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(DrevosTheme.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(auth.isLoading)

                    HStack {
                        Rectangle().fill(DrevosTheme.border).frame(height: 1)
                        Text("OR").font(.caption2).foregroundStyle(DrevosTheme.muted)
                        Rectangle().fill(DrevosTheme.border).frame(height: 1)
                    }
                    .padding(.vertical, 4)

                    Button {
                        auth.signInWithGoogle()
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                            Text("Continue with Google").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(DrevosTheme.panel)
                        .foregroundStyle(DrevosTheme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DrevosTheme.border))
                    }
                    .disabled(auth.isLoading)

                    if auth.isLoading {
                        ProgressView().tint(DrevosTheme.orange).padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DrevosTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboard)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .foregroundStyle(DrevosTheme.text)
            .background(DrevosTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DrevosTheme.border))
    }
}

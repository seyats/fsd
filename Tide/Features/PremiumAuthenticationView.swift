import AuthenticationServices
import SwiftUI
import UIKit

struct PremiumAuthenticationView: View {
    @Environment(AppDependencies.self) private var dependencies
    @FocusState private var focusedField: Field?
    @State private var stage: AuthStage = .landing
    @State private var identifier = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var showProviderSheet = false

    private enum AuthStage { case landing, username, email }
    private enum Field { case identifier, email }

    var body: some View {
        ZStack {
            AuthBlackBackdrop()

            Group {
                switch stage {
                case .landing:
                    landingScreen
                case .username:
                    usernameScreen
                case .email:
                    emailScreen
                }
            }
            .padding(.horizontal, 28)
            .animation(.smooth(duration: 0.42), value: stage)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .alert("Вход", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("ОК", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showProviderSheet) {
            providerSheet
                .presentationDetents([.height(430)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(42)
                .preferredColorScheme(.dark)
        }
    }

    private var landingScreen: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 230)

            AuthChromeLogo(size: 86)
                .padding(.bottom, 24)

            Text("Начать беседу")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.78)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 28) {
                AuthSocialGlassButton(kind: .google, svgName: "google", shape: .circle) {
                    showProviderSheet = true
                }
                AppleAuthGlassButton(svgName: "apple", shape: .circle, completion: handleAppleSignIn)
                AuthCircleIconButton(systemImage: "envelope") {
                    showEmail()
                }
            }

            AuthDivider(title: "или")
                .padding(.top, 32)

            Button {
                setPlaceholder("Вход по телефону пока работает как заглушка.")
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "phone")
                        .font(.system(size: 24, weight: .heavy))
                    Text("Продолжить с телефоном")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(.white, in: Capsule())
            }
            .padding(.top, 26)

            Text("Продолжая, ты соглашаешься с нашими\nУсловиями, Политикой конфиденциальности и\nПолитикой использования файлов cookie.")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.42))
                .lineSpacing(3)
                .padding(.top, 30)

            Button {
                showUsername()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "at")
                    Text("Войти с именем пользователя")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity)
                .frame(height: 86)
                .background(Color.white.opacity(0.04))
            }
            .padding(.horizontal, -28)
            .padding(.top, 36)
        }
    }

    private var usernameScreen: some View {
        VStack(spacing: 0) {
            authTopBar(trailing: "Утеряно имя пользователя")
                .padding(.top, 64)

            VStack(alignment: .leading, spacing: 42) {
                Text("Введи имя\nпользователя")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(10)

                HStack(spacing: 18) {
                    Text("@")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    TextField("никнейм", text: $identifier)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .identifier)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 72)

            Spacer()

            Button(action: submitUsername) {
                Text("Продолжить")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(canContinueUsername ? .black : .white.opacity(0.36))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(canContinueUsername ? .white : .white.opacity(0.14), in: Capsule())
            }
            .disabled(!canContinueUsername || isLoading)
            .padding(.bottom, 42)
        }
    }

    private var emailScreen: some View {
        VStack(spacing: 0) {
            authTopBar(trailing: "Указать номер телефона")
                .padding(.top, 64)

            VStack(alignment: .leading, spacing: 24) {
                Text("Укажите свой\nадрес эл. почты")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(10)

                Text("Мы отправим тебе код подтверждения")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))

                TextField("почта@пример.ру", text: $email)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 72)

            Spacer()

            Button(action: submitEmail) {
                Text("Продолжить")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(canContinueEmail ? .black : .white.opacity(0.36))
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(canContinueEmail ? .white : .white.opacity(0.14), in: Capsule())
            }
            .disabled(!canContinueEmail || isLoading)

            Text("Продолжая, ты соглашаешься получать\nслужебные уведомления об аккаунте.")
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.bottom, 42)
        }
    }

    private var providerSheet: some View {
        VStack(spacing: 20) {
            Text("Войди в свою учётную запись")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 28)

            AuthProviderPill(imageName: "GoogleLogo", title: "Продолжить с Google") {
                setPlaceholder("Вход через Google пока работает как заглушка.")
            }
            AuthProviderPill(imageName: "AppleLogo", title: "Продолжить с Apple") {
                setPlaceholder("Вход через Apple доступен через кнопку Apple на главном экране.")
            }
            AuthProviderPill(systemImage: "envelope", title: "Продолжить с электронной почтой") {
                showProviderSheet = false
                showEmail()
            }
            AuthProviderPill(systemImage: "phone", title: "Продолжить с телефоном") {
                setPlaceholder("Вход по телефону пока работает как заглушка.")
            }

            Spacer()
        }
        .padding(.horizontal, 34)
        .background(Color.black.ignoresSafeArea())
    }

    private func authTopBar(trailing: String) -> some View {
        HStack {
            Button {
                withAnimation(.smooth(duration: 0.38)) { stage = .landing }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button(trailing) {
                setPlaceholder("Восстановление аккаунта появится позже.")
            }
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundStyle(.white)
        }
    }

    private var canContinueUsername: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canContinueEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    private func showUsername() {
        withAnimation(.smooth(duration: 0.38)) {
            stage = .username
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            focusedField = .identifier
        }
    }

    private func showEmail() {
        withAnimation(.smooth(duration: 0.38)) {
            stage = .email
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            focusedField = .email
        }
    }

    private func submitUsername() {
        guard canContinueUsername else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            await dependencies.session.signInIdentifier(identifier, password: "Sy3uki90.")
        }
    }

    private func submitEmail() {
        guard canContinueEmail else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            await dependencies.session.signInEmail(email: email, password: "TidePreview2026", createsAccount: true)
        }
    }

    private func setPlaceholder(_ message: String) {
        alertMessage = message
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    alertMessage = "Apple не вернул данные аккаунта."
                    return
                }
                let fallbackEmail = credential.email ?? credential.user + "@apple.local"
                let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                await dependencies.session.signInApple(
                    userIdentifier: credential.user,
                    fallbackEmail: fallbackEmail,
                    displayName: name.isEmpty ? nil : name
                )
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
    }
}

struct AuthProfileSetupView: View {
    @Environment(AppDependencies.self) private var dependencies
    @FocusState private var focusedField: Field?
    @State private var step: Step = .name
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""

    private enum Step { case name, username }
    private enum Field { case firstName, lastName, username }

    var body: some View {
        ZStack {
            AuthBlackBackdrop()

            VStack(spacing: 0) {
                Spacer()

                AuthChromeLogo(size: 112)
                    .padding(.bottom, 30)

                VStack(spacing: 8) {
                    Text(step == .name ? "Заполни имя" : "Выбери имя пользователя")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(step == .name ? "Так тебя увидят в приложении." : "По нему тебя будут находить.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.48))
                }
                .padding(.bottom, 30)

                Group {
                    if step == .name {
                        VStack(spacing: 14) {
                            AuthInputField(placeholder: "Имя", text: $firstName, icon: "person", isSecure: false, isVisible: .constant(true))
                                .focused($focusedField, equals: .firstName)
                            AuthInputField(placeholder: "Фамилия", text: $lastName, icon: "person.text.rectangle", isSecure: false, isVisible: .constant(true))
                                .focused($focusedField, equals: .lastName)
                        }
                    } else {
                        AuthInputField(placeholder: "Имя пользователя", text: $username, icon: "at", isSecure: false, isVisible: .constant(true))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .username)
                    }
                }
                .frame(maxWidth: 330)
                .animation(.smooth(duration: 0.32), value: step)

                Button(action: continueSetup) {
                    Text(step == .name ? "Продолжить" : "Войти в приложение")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 154, height: 48)
                        .background(.white, in: Capsule())
                        .shadow(color: .white.opacity(0.18), radius: 18, y: 8)
                }
                .padding(.top, 28)

                Spacer()

                if dependencies.session.currentUser?.isVerified == true {
                    HStack(spacing: 8) {
                        TideBrandLogoView(size: 18, style: .circle)
                        Text("аккаунт верифицирован")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.bottom, 34)
                }
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .onAppear {
            let user = dependencies.session.currentUser
            let parts = (user?.name ?? "").split(separator: " ", maxSplits: 1).map(String.init)
            firstName = parts.first ?? ""
            lastName = parts.dropFirst().first ?? ""
            username = user?.username ?? ""
            focusedField = .firstName
        }
    }

    private func continueSetup() {
        switch step {
        case .name:
            withAnimation(.smooth(duration: 0.36)) {
                step = .username
                focusedField = .username
            }
        case .username:
            let fullName = [firstName, lastName]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            dependencies.session.completeProfileSetup(name: fullName, username: username)
            dependencies.router.selectedTab = .chats
        }
    }
}

struct AuthBlackBackdrop: View {
    var body: some View {
        ZStack {
            Color.black
            LinearGradient(
                colors: [
                    .black,
                    .white.opacity(0.06),
                    .black,
                    .white.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 30)
            .opacity(0.8)
        }
    }
}

struct AuthChromeLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .black, .white.opacity(0.32), .black.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: .white.opacity(0.14), radius: 28, y: -10)
                .shadow(color: .black.opacity(0.75), radius: 30, y: 18)

            Image("TideBubbleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.92, height: size * 0.92)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.18), radius: 18, y: -4)

            Circle()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.65), .white.opacity(0.05), .white.opacity(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
                .frame(width: size, height: size)
        }
    }
}

struct AuthDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.white.opacity(0.13)).frame(height: 0.7)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.38))
            Rectangle().fill(.white.opacity(0.13)).frame(height: 0.7)
        }
    }
}

struct AuthCompactButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(AuthGlassBackground(cornerRadius: 16, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let isSecure: Bool
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .tint(.white)

            Button {
                if isSecure {
                    isVisible.toggle()
                }
            } label: {
                Image(systemName: isSecure ? (isVisible ? "eye.slash" : icon) : icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.44))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(!isSecure)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AuthGlassBackground(cornerRadius: 18, interactive: true))
    }
}

struct AuthSocialGlassButton: View {
    enum Kind { case github, google }
    enum ShapeMode { case roundedSquare, circle }

    let kind: Kind
    let svgName: String
    var shape: ShapeMode = .roundedSquare
    let action: () -> Void

    private var size: CGFloat { shape == .circle ? 48 : 54 }
    private var cornerRadius: CGFloat { shape == .circle ? 24 : 17 }

    var body: some View {
        Button(action: action) {
            ZStack {
                AuthGlassBackground(cornerRadius: cornerRadius, interactive: true)
                BrandSVG(name: svgName)
                    .frame(width: size * 0.46, height: size * 0.46)
                    .padding(kind == .google ? 0 : 1)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

struct AppleAuthGlassButton: View {
    enum ShapeMode { case roundedSquare, circle }

    let svgName: String
    var shape: ShapeMode = .roundedSquare
    let completion: (Result<ASAuthorization, Error>) -> Void

    private var size: CGFloat { shape == .circle ? 48 : 54 }
    private var cornerRadius: CGFloat { shape == .circle ? 24 : 17 }

    var body: some View {
        ZStack {
            AuthGlassBackground(cornerRadius: cornerRadius, interactive: true)
            BrandSVG(name: svgName)
                .frame(width: size * 0.42, height: size * 0.42)
        }
        .frame(width: size, height: size)
        .overlay {
            if shape == .circle {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    completion(result)
                }
                .signInWithAppleButtonStyle(.black)
                .clipShape(Circle())
                .opacity(0.02)
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    completion(result)
                }
                .signInWithAppleButtonStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .opacity(0.02)
            }
        }
    }
}

struct BrandSVG: View {
    let name: String

    var body: some View {
        if let imageName = assetName {
            Image(imageName)
                .resizable()
                .scaledToFit()
        } else if let url = Bundle.main.url(forResource: name, withExtension: "svg") {
            SVGRemoteView(url: url)
                .allowsHitTesting(false)
        } else {
            Image(systemName: "circle.fill")
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var assetName: String? {
        switch name {
        case "google": return "GoogleLogo"
        case "apple": return "AppleLogo"
        case "github": return "GitHubLogo"
        default: return nil
        }
    }
}

struct AuthProviderPill: View {
    let imageName: String?
    let systemImage: String?
    let title: String
    let action: () -> Void

    init(imageName: String, title: String, action: @escaping () -> Void) {
        self.imageName = imageName
        self.systemImage = nil
        self.title = title
        self.action = action
    }

    init(systemImage: String, title: String, action: @escaping () -> Void) {
        self.imageName = nil
        self.systemImage = systemImage
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(AuthGlassBackground(cornerRadius: 20, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

struct AuthCircleIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: 54, height: 54)
                .background(AuthGlassBackground(cornerRadius: 27, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

struct AuthGlassBackground: View {
    let cornerRadius: CGFloat
    var interactive: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(interactive ? 0.08 : 0.06))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(interactive ? 0.18 : 0.12), lineWidth: 0.8)
            }
            .background(.black.opacity(0.18))
    }
}

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel

    init(client: LastFMClient, authStore: AuthStore) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(client: client, authStore: authStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                AppIconView()
                    .padding(.bottom, 24)

                Text("memor")
                    .font(MemorTheme.serifItalic(size: 32))
                    .foregroundStyle(MemorTheme.ink)
                    .padding(.bottom, 8)

                Text("A native scrobbler for Apple Music.\nEvery track, remembered.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(MemorTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 14) {
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(MemorTheme.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                Button {
                    viewModel.signIn()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSigningIn {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(MemorTheme.cream)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 16))
                        }
                        Text(viewModel.isSigningIn ? "signing in…" : "sign in with last.fm")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MemorTheme.ink)
                    .foregroundStyle(MemorTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isSigningIn)
                .buttonStyle(.plain)

                Text("your session key is stored in keychain.\nmemor never stores your password.")
                    .font(.system(size: 11))
                    .foregroundStyle(MemorTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MemorTheme.cream)
    }
}

private struct AppIconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 1.0, green: 0.952, blue: 0.944))

            Canvas { ctx, size in
                let scale = size.width / 1024

                let large = Path { p in
                    p.move(to:    CGPoint(x: 647.281, y: 583.154))
                    p.addCurve(to: CGPoint(x: 543.775, y: 450.036),
                               control1: CGPoint(x: 659.216, y: 497.845),
                               control2: CGPoint(x: 608.742, y: 459.962))
                    p.addCurve(to: CGPoint(x: 546.341, y: 677.889),
                               control1: CGPoint(x: 545.011, y: 530.54),
                               control2: CGPoint(x: 547.65, y: 625.074))
                    p.addCurve(to: CGPoint(x: 457.812, y: 753.412),
                               control1: CGPoint(x: 545.306, y: 719.588),
                               control2: CGPoint(x: 506.705, y: 753.412))
                    p.addCurve(to: CGPoint(x: 369.284, y: 677.889),
                               control1: CGPoint(x: 408.92,  y: 753.412),
                               control2: CGPoint(x: 369.284, y: 719.6))
                    p.addCurve(to: CGPoint(x: 457.812, y: 602.367),
                               control1: CGPoint(x: 369.284, y: 636.179),
                               control2: CGPoint(x: 408.92,  y: 602.367))
                    p.addCurve(to: CGPoint(x: 512.053, y: 624.536),
                               control1: CGPoint(x: 484.608, y: 602.367),
                               control2: CGPoint(x: 503.481, y: 614.486))
                    p.addCurve(to: CGPoint(x: 508.505, y: 350.823),
                               control1: CGPoint(x: 510.87,  y: 520.785),
                               control2: CGPoint(x: 509.295, y: 408.371))
                    p.addCurve(to: CGPoint(x: 523.58,  y: 323.925),
                               control1: CGPoint(x: 508.21,  y: 329.245),
                               control2: CGPoint(x: 514.881, y: 323.925))
                    p.addCurve(to: CGPoint(x: 541.906, y: 346.685),
                               control1: CGPoint(x: 537.177, y: 323.925),
                               control2: CGPoint(x: 537.626, y: 339.455))
                    p.addCurve(to: CGPoint(x: 598.597, y: 377.952),
                               control1: CGPoint(x: 553.094, y: 367.187),
                               control2: CGPoint(x: 575.388, y: 368.94))
                    p.addCurve(to: CGPoint(x: 674.134, y: 471.286),
                               control1: CGPoint(x: 636.113, y: 392.528),
                               control2: CGPoint(x: 665.674, y: 429.05))
                    p.addCurve(to: CGPoint(x: 647.281, y: 583.154),
                               control1: CGPoint(x: 681.965, y: 510.354),
                               control2: CGPoint(x: 671.495, y: 553.101))
                    p.closeSubpath()
                }

                let small1 = Path { p in
                    p.move(to:    CGPoint(x: 727.38,  y: 266.437))
                    p.addCurve(to: CGPoint(x: 688.874, y: 216.915),
                               control1: CGPoint(x: 731.82,  y: 234.701),
                               control2: CGPoint(x: 713.043, y: 220.608))
                    p.addCurve(to: CGPoint(x: 689.829, y: 301.679),
                               control1: CGPoint(x: 689.334, y: 246.863),
                               control2: CGPoint(x: 690.316, y: 282.031))
                    p.addCurve(to: CGPoint(x: 656.895, y: 329.774),
                               control1: CGPoint(x: 689.444, y: 317.191),
                               control2: CGPoint(x: 675.084, y: 329.774))
                    p.addCurve(to: CGPoint(x: 623.962, y: 301.679),
                               control1: CGPoint(x: 638.706, y: 329.774),
                               control2: CGPoint(x: 623.962, y: 317.196))
                    p.addCurve(to: CGPoint(x: 656.895, y: 273.584),
                               control1: CGPoint(x: 623.962, y: 286.162),
                               control2: CGPoint(x: 638.706, y: 273.584))
                    p.addCurve(to: CGPoint(x: 677.073, y: 281.831),
                               control1: CGPoint(x: 666.863, y: 273.584),
                               control2: CGPoint(x: 673.884, y: 278.092))
                    p.addCurve(to: CGPoint(x: 675.753, y: 180.006),
                               control1: CGPoint(x: 676.633, y: 243.234),
                               control2: CGPoint(x: 676.047, y: 201.415))
                    p.addCurve(to: CGPoint(x: 681.361, y: 170),
                               control1: CGPoint(x: 675.643, y: 171.979),
                               control2: CGPoint(x: 678.125, y: 170))
                    p.addCurve(to: CGPoint(x: 688.179, y: 178.467),
                               control1: CGPoint(x: 686.419, y: 170),
                               control2: CGPoint(x: 686.587, y: 175.777))
                    p.addCurve(to: CGPoint(x: 709.268, y: 190.099),
                               control1: CGPoint(x: 692.34,  y: 186.094),
                               control2: CGPoint(x: 700.634, y: 186.746))
                    p.addCurve(to: CGPoint(x: 737.369, y: 224.821),
                               control1: CGPoint(x: 723.225, y: 195.521),
                               control2: CGPoint(x: 734.222, y: 209.108))
                    p.addCurve(to: CGPoint(x: 727.38,  y: 266.437),
                               control1: CGPoint(x: 740.283, y: 239.354),
                               control2: CGPoint(x: 736.388, y: 255.257))
                    p.closeSubpath()
                }

                let small2 = Path { p in
                    p.move(to:    CGPoint(x: 417.398, y: 449.785))
                    p.addCurve(to: CGPoint(x: 372.984, y: 392.664),
                               control1: CGPoint(x: 422.52,  y: 413.178),
                               control2: CGPoint(x: 400.861, y: 396.923))
                    p.addCurve(to: CGPoint(x: 374.085, y: 490.436),
                               control1: CGPoint(x: 373.514, y: 427.208),
                               control2: CGPoint(x: 374.646, y: 467.773))
                    p.addCurve(to: CGPoint(x: 336.097, y: 522.843),
                               control1: CGPoint(x: 373.641, y: 508.329),
                               control2: CGPoint(x: 357.077, y: 522.843))
                    p.addCurve(to: CGPoint(x: 298.11,  y: 490.436),
                               control1: CGPoint(x: 315.117, y: 522.843),
                               control2: CGPoint(x: 298.11,  y: 508.334))
                    p.addCurve(to: CGPoint(x: 336.097, y: 458.029),
                               control1: CGPoint(x: 298.11,  y: 472.538),
                               control2: CGPoint(x: 315.117, y: 458.029))
                    p.addCurve(to: CGPoint(x: 359.372, y: 467.542),
                               control1: CGPoint(x: 347.595, y: 458.029),
                               control2: CGPoint(x: 355.694, y: 463.229))
                    p.addCurve(to: CGPoint(x: 357.85,  y: 350.092),
                               control1: CGPoint(x: 358.864, y: 423.023),
                               control2: CGPoint(x: 358.188, y: 374.785))
                    p.addCurve(to: CGPoint(x: 364.319, y: 338.55),
                               control1: CGPoint(x: 357.723, y: 340.833),
                               control2: CGPoint(x: 360.585, y: 338.55))
                    p.addCurve(to: CGPoint(x: 372.183, y: 348.316),
                               control1: CGPoint(x: 370.153, y: 338.55),
                               control2: CGPoint(x: 370.346, y: 345.213))
                    p.addCurve(to: CGPoint(x: 396.509, y: 361.733),
                               control1: CGPoint(x: 376.983, y: 357.114),
                               control2: CGPoint(x: 386.549, y: 357.866))
                    p.addCurve(to: CGPoint(x: 428.922, y: 401.783),
                               control1: CGPoint(x: 412.607, y: 367.987),
                               control2: CGPoint(x: 425.292, y: 383.659))
                    p.addCurve(to: CGPoint(x: 417.398, y: 449.785),
                               control1: CGPoint(x: 432.281, y: 418.546),
                               control2: CGPoint(x: 427.788, y: 436.89))
                    p.closeSubpath()
                }

                let t = CGAffineTransform(scaleX: scale, y: scale)
                ctx.fill(large.applying(t),  with: .color(Color(red: 0.851, green: 0.294, blue: 0.169)))
                ctx.fill(small1.applying(t), with: .color(Color(red: 0.659, green: 0.196, blue: 0.125)))
                ctx.fill(small2.applying(t), with: .color(Color(red: 0.906, green: 0.439, blue: 0.353)))
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color(red: 0.85, green: 0.29, blue: 0.17).opacity(0.25), radius: 12, y: 6)
    }
}

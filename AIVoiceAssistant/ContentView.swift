import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = VoiceAssistantBootstrap.makeViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.14), Color(red: 0.12, green: 0.15, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                headerBar
                statusRow
                transcriptCard
                responseCard

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .font(.custom("AvenirNext-Medium", size: 14))
                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.2, green: 0.05, blue: 0.05).opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer(minLength: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .onAppear {
            viewModel.start()
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Local Voice Assistant")
                    .font(.custom("AvenirNext-DemiBold", size: 20))
                    .foregroundColor(.white)
                Text("Gemini with Groq fallback")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(Color.white.opacity(0.6))
            }

            Spacer()

            Button(action: toggleListening) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.state == .idle ? "mic.fill" : "stop.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text(viewModel.state == .idle ? "Start" : "Stop")
                        .font(.custom("AvenirNext-DemiBold", size: 12))
                }
                .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.12))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.95, green: 0.84, blue: 0.43))
                .clipShape(Capsule())
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Text("Status")
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .foregroundColor(Color.white.opacity(0.7))

            Text(viewModel.state.rawValue.uppercased())
                .font(.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.9))
                .clipShape(Capsule())

            Spacer()
        }
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("User")
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(Color.white.opacity(0.7))
            Text(viewModel.transcript.isEmpty ? "(listening...)" : viewModel.transcript)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Assistant")
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(Color.white.opacity(0.7))
            Text(viewModel.response.isEmpty ? "(waiting...)" : viewModel.response)
                .font(.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle:
            return Color.white.opacity(0.2)
        case .listening:
            return Color(red: 0.25, green: 0.78, blue: 0.52)
        case .processing:
            return Color(red: 0.95, green: 0.68, blue: 0.2)
        case .speaking:
            return Color(red: 0.48, green: 0.62, blue: 1.0)
        case .interrupted:
            return Color(red: 1.0, green: 0.45, blue: 0.4)
        }
    }

    private func toggleListening() {
        if viewModel.state == .idle {
            viewModel.start()
        } else {
            viewModel.stop()
        }
    }
}

#Preview {
    ContentView()
}

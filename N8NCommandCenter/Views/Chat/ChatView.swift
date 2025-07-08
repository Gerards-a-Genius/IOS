//
//  ChatView.swift
//  N8NCommandCenter
//
//  Individual chat conversation view
//

import SwiftUI
import Combine

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var isShowingVoiceRecorder = false
    @FocusState private var isInputFocused: Bool
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                onRetry: {
                                    Task {
                                        await viewModel.retrySendMessage(message: message)
                                    }
                                }
                            )
                            .id(message.id)
                        }
                        
                        if viewModel.isAgentTyping {
                            HStack {
                                TypingIndicatorView()
                                Spacer()
                            }
                            .id("typing-indicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isAgentTyping) { isTyping in
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Network Status Bar
            if !networkMonitor.isConnected {
                NetworkStatusBar()
            }
            
            // Input Area
            MessageInputView(
                text: $messageText,
                isShowingVoiceRecorder: $isShowingVoiceRecorder,
                onSend: sendMessage,
                onVoice: { isShowingVoiceRecorder = true }
            )
        }
        .navigationTitle(conversation.agent.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { viewModel.refreshMessages() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: { /* Archive conversation */ }) {
                        Label("Archive", systemImage: "archivebox")
                    }
                    
                    Button(action: { /* Clear messages */ }) {
                        Label("Clear Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingVoiceRecorder) {
            VoiceRecorderView { transcript in
                messageText = transcript
                isShowingVoiceRecorder = false
            }
        }
        .onAppear {
            viewModel.loadMessages()
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            await viewModel.sendMessage(trimmedText)
        }
        
        messageText = ""
        isInputFocused = false
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let onRetry: (() -> Void)?
    
    init(message: Message, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.onRetry = onRetry
    }

    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Message Content
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .clipShape(BubbleShape(isFromUser: message.isFromUser))
                
                // Timestamp and Status
                HStack(spacing: 4) {
                    if message.messageTypeEnum == .voice {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundColor(.accentOrange)
                    }
                    
                    Text(message.formattedTimestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if message.isFromUser,
                       let metadata = message.metadataDecoded,
                       metadata.errorMessage != nil {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text("Failed")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isFromUser ? .trailing : .leading)
            .onTapGesture {
                if let onRetry = onRetry, message.metadataDecoded?.errorMessage != nil {
                    onRetry()
                }
            }
            
            if !message.isFromUser { Spacer() }
        }
    }
    
    private var bubbleColor: Color {
        message.isFromUser ? .primaryBlue : Color(.systemGray5)
    }
    
    private var textColor: Color {
        message.isFromUser ? .white : .primary
    }
}

// MARK: - Bubble Shape
struct BubbleShape: Shape {
    let isFromUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6
        
        var path = Path()
        
        if isFromUser {
            // Right-aligned bubble with tail
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius - tailSize, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius - tailSize, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: -90),
                       endAngle: Angle(degrees: 0),
                       clockwise: false)
            
            // Tail
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius + tailSize),
                             control: CGPoint(x: rect.maxX - tailSize/2, y: rect.minY + radius))
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.minY + radius + tailSize))
            
            // Rest of bubble
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius - tailSize, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 0),
                       endAngle: Angle(degrees: 90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 90),
                       endAngle: Angle(degrees: 180),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: 180),
                       endAngle: Angle(degrees: 270),
                       clockwise: false)
        } else {
            // Left-aligned bubble with tail
            path.move(to: CGPoint(x: rect.minX + tailSize + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: -90),
                       endAngle: Angle(degrees: 0),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 0),
                       endAngle: Angle(degrees: 90),
                       clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + tailSize + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + tailSize + radius, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 90),
                       endAngle: Angle(degrees: 180),
                       clockwise: false)
            
            // Tail
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.minY + radius + tailSize))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + radius),
                             control: CGPoint(x: rect.minX + tailSize / 2, y: rect.minY + radius))
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.minY + radius))

            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + tailSize + radius, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: 180),
                       endAngle: Angle(degrees: 270),
                       clockwise: false)
        }
        
        return path
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @Binding var text: String
    @Binding var isShowingVoiceRecorder: Bool
    let onSend: () -> Void
    let onVoice: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Voice Button
            Button(action: onVoice) {
                Image(systemName: "mic.fill")
                    .foregroundColor(.accentOrange)
                    .frame(width: 36, height: 36)
            }
            
            // Text Field
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .onSubmit {
                    onSend()
                }
            
            // Send Button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty ? .gray : .primaryBlue)
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Network Status Bar
struct NetworkStatusBar: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        HStack {
            Image(systemName: networkMonitor.connectionType.systemImage)
                .foregroundColor(.white)
            
            Text("No Internet Connection")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(Color.red)
    }
}

// MARK: - Voice Recorder View
struct VoiceRecorderView: View {
    let onComplete: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioService = AudioService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Live Transcript
                Text(audioService.transcript.isEmpty ? "Recording..." : audioService.transcript)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(minHeight: 100)
                
                // Recording Button
                Button(action: {
                    if audioService.isRecording {
                        audioService.stopRecording()
                    } else {
                        audioService.startRecording()
                    }
                }) {
                    Image(systemName: audioService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(audioService.isRecording ? .red : .accentOrange)
                }
                
                if let error = audioService.error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Record Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if audioService.isRecording {
                            audioService.stopRecording()
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                audioService.requestPermissions()
            }
            .onReceive(audioService.transcriptionPublisher) { transcript in
                onComplete(transcript)
                dismiss()
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: scale
                    )
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .clipShape(BubbleShape(isFromUser: false))
        .onAppear {
            scale = 1.0
        }
    }
}

// MARK: - View Model
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isAgentTyping = false
    @Published var error: Error?
    
    private let conversation: Conversation
    private let databaseService = DatabaseService.shared
    private let webhookService = WebhookService.shared
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    func loadMessages() {
        messages = conversation.sortedMessages
    }
    
    func refreshMessages() {
        loadMessages()
    }
    
    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = databaseService.addMessage(
            to: conversation,
            content: text,
            isFromUser: true
        )
        loadMessages()
        
        // Send to webhook
        isLoading = true
        isAgentTyping = true
        error = nil
        
        do {
            let response = try await webhookService.sendMessage(text, to: conversation.agent)
            
            // Add AI response
            let aiMessage = databaseService.addMessage(
                to: conversation,
                content: response.response,
                isFromUser: false
            )
            
            // Update metadata if needed
            if let metadata = response.metadata {
                var messageMetadata = MessageMetadata()
                messageMetadata.customData = metadata
                aiMessage.metadataDecoded = messageMetadata
                databaseService.save()
            }
            
            loadMessages()
        } catch {
            self.error = error
            
            // Update the user message with error metadata
            var metadata = MessageMetadata()
            metadata.errorMessage = error.localizedDescription
            userMessage.metadataDecoded = metadata
            databaseService.save()
        }
        
        isLoading = false
        isAgentTyping = false
    }
    
    func retrySendMessage(message: Message) async {
        guard let content = message.content else { return }
        
        // Remove the old failed message
        databaseService.deleteMessage(message)
        loadMessages()
        
        // Send it again
        await sendMessage(content)
    }
}

// MARK: - Preview
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(conversation: Conversation(context: DatabaseService.shared.viewContext))
                .environmentObject(NetworkMonitor())
        }
    }
}
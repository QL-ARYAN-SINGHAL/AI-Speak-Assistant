# 🚀 AI Voice Assistant — Real‑Time, Hands‑Free Conversational iOS

A SwiftUI voice assistant that listens continuously, answers in speech, and supports barge‑in — with OpenAI as primary and Groq as fallback.

---

## 📱 Overview

This project delivers a **hands‑free, voice‑first assistant** that feels natural in conversation: speak, listen, interrupt, continue. It combines iOS audio and speech frameworks with a clean MVVM core and a flexible AI provider layer.

**What makes it unique**
- Continuous voice loop with **barge‑in** support
- **Dynamic AI engine switching** (OpenAI → Groq)
- **Remote config** driven keys/models via Firebase
- Clear modular architecture designed for extension
---

## 🧠 Architecture

**Pattern:** MVVM  
**Flow:** `View → ViewModel → Conversation Manager → LLM Service → AI Engine → Response → TTS`

Core runtime flow:
1. `ContentView` binds to `VoiceAssistantViewModel`
2. `VoiceConversationManager` controls audio + state transitions
3. `LLMService` manages conversation memory and calls AI engines
4. `FailoverAIEngine` chooses **OpenAI first, Groq second**
5. Response spoken with `AVSpeechSynthesizer`

OpenAI uses the **Chat Completions** endpoint via HTTPS with Bearer auth. ([platform.openai.com](https://platform.openai.com/docs/api-reference/chat/create-chat-completion?utm_source=openai))

---

## 🏗️ Project Structure

```
AIVoiceAssistant/
├── AIVoiceAssistant/
│   ├── App/
│   │   └── VoiceAssistantBootstrap.swift
│   ├── UI/
│   │   └── VoiceAssistantViewModel.swift
│   ├── Core/
│   │   ├── VoiceConversationManager.swift
│   │   ├── LLMService.swift
│   │   ├── ConversationState.swift
│   │   ├── ConversationStateMachine.swift
│   │   └── ChatMessage.swift
│   ├── Audio/
│   │   ├── AudioSessionManager.swift
│   │   ├── SpeechRecognizerManager.swift
│   │   └── SpeechPlaybackManager.swift
│   ├── AI/
│   │   ├── OpenAIRemoteAIEngine.swift
│   │   ├── GroqRemoteAIEngine.swift
│   │   ├── FailoverAIEngine.swift
│   │   ├── DynamicRemoteAIEngine.swift
│   │   ├── RemoteAIConfig.swift
│   │   ├── RemoteAIConfigStore.swift
│   │   ├── LocalAIEngine.swift
│   │   └── RemoteAIError.swift
│   ├── Network/
│   │   └── FirebaseRemoteConfigProvider.swift
│   ├── ContentView.swift
│   ├── AIVoiceAssistantApp.swift
│   └── GoogleService-Info.plist
├── AIVoiceAssistant.xcodeproj
├── Info.plist
└── README.md
```

---

## ⚙️ Tech Stack

**Languages**
- Swift

**Frameworks**
- SwiftUI
- Combine
- AVFoundation
- Speech
- Firebase Remote Config

**AI Providers**
- OpenAI (primary)
- Groq (fallback)

---

## 🔌 Core Features

- **Continuous microphone capture** (no press‑to‑talk)
- **Speech‑to‑text** with endpoint detection
- **LLM response generation** with memory
- **Barge‑in support** (interrupt TTS with speech)
- **Dynamic engine switching** (OpenAI → Groq)
- **Remote config** for keys/models via Firebase

---

## 🔄 How It Works

1. User speaks  
2. `SpeechRecognizerManager` streams partials + detects end‑of‑speech  
3. `VoiceConversationManager` calls `LLMService`  
4. `OpenAIRemoteAIEngine` sends request  
5. If OpenAI fails → `GroqRemoteAIEngine`  
6. Response returned → `SpeechPlaybackManager` speaks  
7. User interrupts → playback stops immediately  

OpenAI requests are made using `POST /v1/chat/completions` with a Bearer key. ([platform.openai.com](https://platform.openai.com/docs/api-reference/chat/create-chat-completion?utm_source=openai))

---

## 🧪 Setup Instructions

1. Clone the repo  
2. Open `AIVoiceAssistant.xcodeproj`  
3. Ensure Firebase is configured (see `GoogleService-Info.plist`)  
4. Add **OpenAI + Groq** keys to Firebase Remote Config  
5. Run on a real device (Speech + TTS are unreliable in simulator)  

---

## 🔐 Configuration

**Remote Config Keys**
- `openai_api_key`
- `openai_model` (use `gpt-4o-mini`)
- `openai_endpoint` (use `https://api.openai.com/v1/chat/completions`)
- `groq_api_key`
- `groq_model`
- `groq_endpoint`
- `system_prompt`

**Sensitive files**
- `GoogleService-Info.plist`
- OpenAI / Groq API keys

OpenAI API keys are created in the OpenAI dashboard; do **not** hard‑code them in client apps. ([help.openai.com](https://help.openai.com/en/articles/4936850-where-do-i-find-my-openai-api-key%23.woff2?utm_source=openai))

---

## 📈 Scalability & Design Decisions

- **Provider‑agnostic LLM layer**: adding a new AI provider is a new engine class.
- **Failover built‑in**: no single point of failure.
- **Conversation memory**: managed in `LLMService`, easy to extend with summarization.
- **Remote config**: swap models or endpoints without shipping a new build.

---

## 🤝 Contribution Guide

1. Fork the repo  
2. Create a feature branch  
3. Open a PR with clear summary and test notes  
4. Keep APIs provider‑agnostic and add logging for voice flows  

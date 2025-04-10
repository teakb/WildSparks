import SwiftUI
import CloudKit

struct MatchesView: View {
    @State private var matches: [Match] = []

    var body: some View {
        NavigationStack {
            if matches.isEmpty {
                Text("No Matches Yet! Head over to the Nearby or Broadcast tab to catch someone’s eye!").padding()
            } else {
                List(matches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        HStack {
                            Text(match.name)
                            Spacer()
                            Text("💬")
                        }
                    }
                }
            }

            Button("👻 Simulate Match") {
                simulateMatch()
            }
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .foregroundColor(.white)
            .onAppear {
                fetchMatches()
                
}
            .navigationTitle("Matches")
        }
    }

    func simulateMatch() {
        guard let myUserID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let fakeProfileID = CKRecord.ID(recordName: "fakeUser123_profile")
        let fakeProfile = CKRecord(recordType: "UserProfile", recordID: fakeProfileID)
        fakeProfile["name"] = "Alex (Test User)" as NSString
        fakeProfile["email"] = "alex@test.com" as NSString
        fakeProfile["age"] = 28 as NSNumber
        fakeProfile["gender"] = "Non-Binary" as NSString

        let likeFromFake = CKRecord(recordType: "Like")
        likeFromFake["fromUser"] = "fakeUser123" as NSString
        likeFromFake["toUser"] = myUserID as NSString

        let likeFromMe = CKRecord(recordType: "Like")
        likeFromMe["fromUser"] = myUserID as NSString
        likeFromMe["toUser"] = "fakeUser123" as NSString

        let db = CKContainer.default().publicCloudDatabase
        db.save(fakeProfile) { _, err1 in
            if let err1 = err1 { print("❌ Profile error: \(err1.localizedDescription)") }

            db.save(likeFromFake) { _, err2 in
                if let err2 = err2 {
                    print("❌ Like error: \(err2.localizedDescription)")
                } else {
                    db.save(likeFromMe) { _, err3 in
                        if let err3 = err3 {
                            print("❌ Like-back error: \(err3.localizedDescription)")
                        } else {
                            print("✅ Mutual match created with fakeUser123")
                            fetchMatches()

                            // ✅ Trigger fake message after 10 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                simulateIncomingMessage(from: "fakeUser123", to: myUserID)
                            }
                        }
                    }
                }
            }
        }
    }

    func simulateIncomingMessage(from senderID: String, to recipientID: String) {
        print("📤 Simulating message to: \(recipientID)")

        let messageText = "Hey! I saw you nearby and wanted to say hi 👋"
        let messageRecord = CKRecord(recordType: "Message")
        messageRecord["text"] = messageText as NSString
        messageRecord["fromUser"] = senderID as NSString
        messageRecord["toUser"] = recipientID as NSString
        messageRecord["isBot"] = true as NSNumber

        let chatID = [senderID, recipientID].sorted().joined(separator: "_")
        messageRecord["chatID"] = chatID as NSString

        let saveOp = CKModifyRecordsOperation(recordsToSave: [messageRecord], recordIDsToDelete: nil)
        saveOp.savePolicy = .allKeys
        saveOp.modifyRecordsCompletionBlock = { savedRecords, _, error in
            if let error = error {
                print("❌ Failed to simulate message: \(error.localizedDescription)")
            } else {
                print("✅ Simulated message saved to: \(recipientID)")
            }
        }

        CKContainer.default().publicCloudDatabase.add(saveOp)
    }



    func fetchMatches() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let query = CKQuery(recordType: "Like", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            guard let records = records else {
                print("❌ Failed to fetch Like records")
                return
            }

            var likesFromUser: Set<String> = []
            var likesToUser: Set<String> = []

            for record in records {
                guard let fromUser = record["fromUser"] as? String,
                      let toUser = record["toUser"] as? String else { continue }

                if fromUser == userID {
                    likesFromUser.insert(toUser)
                }
                if toUser == userID {
                    likesToUser.insert(fromUser)
                }
            }

            let mutualIDs = likesFromUser.intersection(likesToUser)
            print("🤝 Mutual Matches: \(mutualIDs)")

            let profileIDs = mutualIDs.map { CKRecord.ID(recordName: "\($0)_profile") }
            let fetchOp = CKFetchRecordsOperation(recordIDs: profileIDs)
            var matchedProfiles: [Match] = []

            fetchOp.perRecordResultBlock = { recordID, result in
                if case .success(let record) = result {
                    let matchID = recordID.recordName.replacingOccurrences(of: "_profile", with: "")
                    let name = record["name"] as? String ?? "Unknown"
                    matchedProfiles.append(Match(id: matchID, name: name))
                }
            }

            fetchOp.fetchRecordsCompletionBlock = { _, _ in
                DispatchQueue.main.async {
                    self.matches = matchedProfiles.sorted { $0.name < $1.name }
                    print("✅ Matches loaded: \(self.matches.map { $0.name })")
                }
            }

            CKContainer.default().publicCloudDatabase.add(fetchOp)
        }
    }
}

struct MatchDetailView: View {
    let match: Match

    var body: some View {
        TabView {
            ChatView(matchID: match.id)
                .tabItem { Label("Chat", systemImage: "message") }

            ProfileDetailView(matchID: match.id)
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .navigationTitle(match.name)
    }
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var scrollToBottom = false
    let matchID: String

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { msg in
                            VStack(alignment: msg.isMe ? .trailing : .leading, spacing: 4) {
                                HStack {
                                    if msg.isMe { Spacer() }

                                    Text(msg.text)
                                        .padding()
                                        .background(msg.isMe ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                        .foregroundColor(msg.isMe ? .blue : .black)
                                        .cornerRadius(12)

                                    if !msg.isMe { Spacer() }
                                }

                                Text(formatTimestamp(msg.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(msg.isMe ? .trailing : .leading, 8)
                            }
                            .id(msg.id)
                            .padding(.horizontal)
                        }
                    }
                }
                .onChange(of: scrollToBottom) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    sendMessage()
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .onAppear {
            loadMessages()
        }
        .onReceive(timer) { _ in
            loadMessages()
        }
    }

    func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // e.g. "5m ago"
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func getChatID(userID: String, otherUserID: String) -> String {
        return [userID, otherUserID].sorted().joined(separator: "_")
    }

    func loadMessages() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let chatID = getChatID(userID: userID, otherUserID: matchID)

        let predicate = NSPredicate(format: "chatID == %@", chatID)
        let query = CKQuery(recordType: "Message", predicate: predicate)

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Failed to load messages: \(error.localizedDescription)")
                return
            }

            guard let records = records else { return }

            let sorted = records.sorted { ($0.creationDate ?? Date()) < ($1.creationDate ?? Date()) }

            DispatchQueue.main.async {
                self.messages = sorted.map { record in
                    let text = record["text"] as? String ?? ""
                    let from = record["fromUser"] as? String ?? ""
                    let isMe = from == userID
                    let date = record.creationDate ?? Date()
                    
                    return Message(id: record.recordID.recordName, text: text, isMe: isMe, timestamp: date)
                }

                scrollToBottom.toggle()
            }
        }
    }

    func sendMessage() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let textToSend = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty else { return }

        let message = Message(id: UUID().uuidString, text: textToSend, isMe: true, timestamp: Date())
        messages.append(message)
        scrollToBottom.toggle()
        newMessage = ""

        let record = CKRecord(recordType: "Message")
        record["text"] = message.text as NSString
        record["fromUser"] = userID as NSString
        record["toUser"] = matchID as NSString
        record["isBot"] = false as NSNumber

        let chatID = getChatID(userID: userID, otherUserID: matchID)
        record["chatID"] = chatID as NSString

        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                print("❌ Failed to save message: \(error.localizedDescription)")
            } else {
                print("✅ Message saved")
            }
        }
    }
}



struct ProfileDetailView: View {
    let matchID: String
    @State private var profile: UserProfile = UserProfile()

    var body: some View {
        VStack {
            Text(profile.name)
            Text("Age: \(profile.age)")
            Text("Email: \(profile.email)")
            Text("Gender: \(profile.gender)")
        }
        .onAppear { loadProfile() }
    }

    func loadProfile() {
        let recordID = CKRecord.ID(recordName: "\(matchID)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, _ in
            if let record = record {
                DispatchQueue.main.async {
                    profile.name = record["name"] as? String ?? ""
                    profile.age = record["age"] as? Int ?? 0
                    profile.email = record["email"] as? String ?? ""
                    profile.gender = record["gender"] as? String ?? ""
                }
            }
        }
    }
}

struct Match: Identifiable {
    let id: String
    let name: String
}

struct Message: Identifiable {
    let id: String
    let text: String
    let isMe: Bool
    let timestamp: Date
}

#Preview {
    MatchesView()
}

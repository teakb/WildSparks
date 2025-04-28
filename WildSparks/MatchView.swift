import SwiftUI
import CloudKit
import PhotosUI   // ← add this

// MARK: Helper models
struct MessagePreview { let text: String; let date: Date; let fromUser: String }
struct Match: Identifiable { let id: String; var name: String; var image: UIImage? }

// MARK: MatchesView
struct MatchesView: View {
    @State private var matches: [Match] = []
    @State private var previews: [String: MessagePreview] = [:]
    @State private var unread: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack {
                if matches.isEmpty {
                    Spacer()
                    Text("No Matches Yet!\nHead over to Nearby or Broadcast to catch someone’s eye.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(matches) { match in
                        NavigationLink {
                            MatchDetailView(match: match)
                                .onAppear {
                                    markChatRead(with: match.id)
                                }
                        } label: {
                            HStack(spacing: 12) {
                                if let ui = match.image {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.25))
                                        .frame(width: 50, height: 50)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(match.name)
                                            .font(.body)
                                            .fontWeight(unread.contains(match.id) ? .bold : .regular)
                                        Spacer()
                                        if let p = previews[match.id] {
                                            Text(relativeTime(from: p.date))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if let p = previews[match.id] {
                                        Text(String(p.text.prefix(15)) + (p.text.count > 15 ? "…" : ""))
                                            .font(.subheadline)
                                            .foregroundColor(unread.contains(match.id) ? .primary : .gray)
                                    } else {
                                        Text("No messages yet")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                if unread.contains(match.id) {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 6)
                            .onAppear {
                                if previews[match.id] == nil {
                                    loadLastMessage(for: match.id)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                Button {
                    simulateMatch()
                } label: {
                    Label("Simulate Match", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Matches")
            .onAppear {
                fetchMatches()
            }
        }
    }

    // MARK: fetch mutual matches
    func fetchMatches() {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }

        let likeQuery = CKQuery(recordType: "Like", predicate: NSPredicate(value: true))
        CKContainer.default().publicCloudDatabase.perform(likeQuery, inZoneWith: nil) { recs, _ in
            guard let recs else { return }

            var sent = Set<String>()
            var received = Set<String>()

            for r in recs {
                if let f = r["fromUser"] as? String, let t = r["toUser"] as? String {
                    if f == myID { sent.insert(t) }
                    if t == myID { received.insert(f) }
                }
            }

            let mutual = sent.intersection(received)
            let ids = mutual.map { CKRecord.ID(recordName: "\($0)_profile") }
            let op = CKFetchRecordsOperation(recordIDs: ids)
            var loaded: [Match] = []

            op.perRecordResultBlock = { rid, result in
                if case .success(let rec) = result {
                    let uid = rid.recordName.replacingOccurrences(of: "_profile", with: "")
                    let name = rec["name"] as? String ?? "Unknown"
                    var img: UIImage?
                    if let asset = rec["photo1"] as? CKAsset,
                       let url = asset.fileURL,
                       let data = try? Data(contentsOf: url),
                       let ui = UIImage(data: data) {
                        img = ui
                    }
                    loaded.append(Match(id: uid, name: name, image: img))
                }
            }

            op.fetchRecordsCompletionBlock = { _, _ in
                DispatchQueue.main.async {
                    matches = loaded.sorted { $0.name < $1.name }
                    matches.forEach { loadLastMessage(for: $0.id) }
                }
            }
            CKContainer.default().publicCloudDatabase.add(op)
        }
    }

    // MARK: load most recent message
    func loadLastMessage(for otherID: String) {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let chatID = [myID, otherID].sorted().joined(separator: "_")
        let query = CKQuery(recordType: "Message",
                            predicate: NSPredicate(format: "chatID == %@", chatID))

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { recs, _ in
            guard let recs, !recs.isEmpty else { return }
            if let latest = recs.max(by: { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }) {
                let txt = latest["text"] as? String ?? ""
                let date = latest.creationDate ?? Date()
                let fromUser = latest["fromUser"] as? String ?? ""

                DispatchQueue.main.async {
                    previews[otherID] = .init(text: txt, date: date, fromUser: fromUser)
                    let lastSeen = lastRead(for: chatID)
                    if date > lastSeen && fromUser != myID {
                        unread.insert(otherID)
                    }
                }
            }
        }
    }

    // MARK: unread helpers
    private func lastRead(for chatID: String) -> Date {
        UserDefaults.standard.object(forKey: "lastRead_\(chatID)") as? Date ?? .distantPast
    }

    private func markChatRead(with otherID: String) {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let chatID = [myID, otherID].sorted().joined(separator: "_")
        UserDefaults.standard.set(Date(), forKey: "lastRead_\(chatID)")
        unread.remove(otherID)
    }

    // MARK: simulate a match
    func simulateMatch() {
        guard let myID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let profileID = CKRecord.ID(recordName: "fakeUser123_profile")
        let rec = CKRecord(recordType: "UserProfile", recordID: profileID)
        rec["name"] = "Alex (Test User)" as NSString
        rec["email"] = "alex@test.com" as NSString
        rec["age"] = 28 as NSNumber
        rec["gender"] = "Non-Binary" as NSString

        let likeA = CKRecord(recordType: "Like")
        likeA["fromUser"] = "fakeUser123" as NSString
        likeA["toUser"] = myID as NSString

        let likeB = CKRecord(recordType: "Like")
        likeB["fromUser"] = myID as NSString
        likeB["toUser"] = "fakeUser123" as NSString

        let db = CKContainer.default().publicCloudDatabase
        db.save(rec) { _, _ in
            db.save(likeA) { _, _ in
                db.save(likeB) { _, _ in
                    fetchMatches()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        simulateIncomingMessage(from: "fakeUser123", to: myID)
                    }
                }
            }
        }
    }

    func simulateIncomingMessage(from sender: String, to recipient: String) {
        let rec = CKRecord(recordType: "Message")
        rec["text"] = "Hey! I saw you nearby and wanted to say hi 👋" as NSString
        rec["fromUser"] = sender as NSString
        rec["toUser"] = recipient as NSString
        rec["isBot"] = true as NSNumber
        rec["chatID"] = [sender, recipient].sorted().joined(separator: "_") as NSString

        CKContainer.default().publicCloudDatabase.save(rec) { _, _ in }
    }

    // MARK: utilities
    func relativeTime(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: Date())
        if let d = c.day, d > 0 {
            return "\(d)d"
        }
        if let h = c.hour, h > 0 {
            return "\(h)h"
        }
        if let m = c.minute, m > 0 {
            return "\(m)m"
        }
        return "now"
    }
}


// MARK: 5: MatchDetailView with header segment control
struct MatchDetailView: View {
    let match: Match
    @State private var selectedTab: Tab = .chat

    enum Tab: String, CaseIterable, Identifiable {
        case chat = "Chat"
        case profile = "Profile"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            Divider()

            Group {
                switch selectedTab {
                case .chat:
                    ChatView(matchID: match.id)
                case .profile:
                    ProfileDetailView(matchID: match.id)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(match.name)
    }
}

// MARK: 6: Chat View
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
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") { sendMessage() }
                    .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .onAppear { loadMessages() }
        .onReceive(timer) { _ in loadMessages() }
    }

    func formatTimestamp(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    func getChatID(userID: String, otherUserID: String) -> String {
        [userID, otherUserID].sorted().joined(separator: "_")
    }

    func loadMessages() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else { return }
        let chatID = getChatID(userID: userID, otherUserID: matchID)
        let query = CKQuery(recordType: "Message", predicate: NSPredicate(format: "chatID == %@", chatID))

        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Failed to load messages: \(error.localizedDescription)")
                return
            }
            let sorted = (records ?? []).sorted {
                ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
            }
            DispatchQueue.main.async {
                messages = sorted.map { record in
                    let text = record["text"] as? String ?? ""
                    let from = record["fromUser"] as? String ?? ""
                    let isMe = from == UserDefaults.standard.string(forKey: "appleUserIdentifier")
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

        let msg = Message(id: UUID().uuidString, text: textToSend, isMe: true, timestamp: Date())
        messages.append(msg)
        scrollToBottom.toggle()
        newMessage = ""

        let record = CKRecord(recordType: "Message")
        record["text"] = msg.text as NSString
        record["fromUser"] = userID as NSString
        record["toUser"] = matchID as NSString
        record["isBot"] = false as NSNumber
        record["chatID"] = getChatID(userID: userID, otherUserID: matchID) as NSString

        CKContainer.default().publicCloudDatabase.save(record) { _, error in
            if let error = error {
                print("❌ Failed to save message: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: 7: ProfileDetailView
// MARK: Full profile detail view using SectionGrid
struct ImageWrapper: Identifiable {
    let id = UUID()
    let ui: UIImage
}

struct ProfileDetailView: View {
    let matchID: String

    @State private var fullProfile: [String: String] = [:]
    @State private var photos: [UIImage] = []
    @State private var fullScreenImage: ImageWrapper?

    private var profileItems: [(String, String)] {
        fullProfile
            .sorted(by: { $0.key < $1.key })
            .map { key, value in
                (iconName(for: key), "\(key.capitalized): \(value)")
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Photo carousel
                if !photos.isEmpty {
                    TabView {
                        ForEach(photos.indices, id: \.self) { idx in
                            Image(uiImage: photos[idx])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipped()
                                .onTapGesture {
                                    fullScreenImage = ImageWrapper(ui: photos[idx])
                                }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }

                // Profile fields
                if !profileItems.isEmpty {
                    SectionGrid(title: "Profile Details", items: profileItems)
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: loadProfile)
        .fullScreenCover(item: $fullScreenImage) { wrapper in
            ZStack(alignment: .topLeading) {
                Color.black.ignoresSafeArea()

                Image(uiImage: wrapper.ui)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea()

                Button(action: { fullScreenImage = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                .padding(.leading, 20)
            }
        }
    }

    private func loadProfile() {
        let recordID = CKRecord.ID(recordName: "\(matchID)_profile")
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { rec, _ in
            guard let rec = rec else { return }
            DispatchQueue.main.async {
                // parse fields
                fullProfile = rec.allKeys().reduce(into: [:]) { dict, key in
                    if let s = rec[key] as? String { dict[key] = s }
                    else if let n = rec[key] as? NSNumber { dict[key] = n.stringValue }
                }
                // load photos 1–6
                photos = (1...6).compactMap { i in
                    guard let asset = rec["photo\(i)"] as? CKAsset,
                          let url = asset.fileURL,
                          let d = try? Data(contentsOf: url),
                          let ui = UIImage(data: d) else { return nil }
                    return ui
                }
            }
        }
    }

    private func iconName(for field: String) -> String {
        switch field.lowercased() {
        case "name": return "person"
        case "age": return "number"
        case "email": return "envelope"
        case "gender": return "person.crop.circle"
        case "height": return "ruler"
        case "hometown": return "house"
        case "religion": return "hands.sparkles"
        case "ethnicity": return "globe"
        case "educationlevel": return "graduationcap"
        case "college": return "building.columns"
        case "jobtitle": return "briefcase"
        case "companyname": return "building.2"
        case "interestedin": return "heart"
        case "datingintentions": return "hands.sparkles"
        case "relationshiptype": return "book.closed"
        case "dietarypreferences": return "fork.knife"
        case "exercisehabits": return "figure.walk"
        case "interests": return "star.fill"
        case "drinks": return "wineglass"
        case "smokes": return "smoke"
        case "smokesweed": return "leaf"
        case "pets": return "pawprint"
        case "haschildren": return "person.2"
        case "wantschildren": return "figure.wave"
        default: return "info.circle"
        }
    }
}

// Supporting models
struct Message: Identifiable {
    let id: String
    let text: String
    let isMe: Bool
    let timestamp: Date
}



// Preview
#Preview {
    NavigationStack {
        MatchDetailView(match: Match(id: "123", name: "Alex", image: nil))
    }
}

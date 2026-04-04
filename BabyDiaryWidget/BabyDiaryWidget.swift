import WidgetKit
import SwiftUI

struct BabyDiaryEntry: TimelineEntry {
    let date: Date
    let babyName: String
    let dayCount: Int
    let monthAndDays: String
    let photoData: Data?
}

struct BabyDiaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> BabyDiaryEntry {
        BabyDiaryEntry(date: .now, babyName: "아기", dayCount: 1, monthAndDays: "", photoData: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BabyDiaryEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BabyDiaryEntry>) -> Void) {
        let entry = makeEntry()
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
        )
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry() -> BabyDiaryEntry {
        let stack = WidgetCoreDataStack.shared
        let baby = stack.fetchBaby()
        let latestPhoto = stack.fetchLatestEntryWithPhoto()

        return BabyDiaryEntry(
            date: .now,
            babyName: baby?.name ?? "",
            dayCount: baby?.dayCount ?? 1,
            monthAndDays: baby?.monthAndDays ?? "",
            photoData: latestPhoto?.photoData
        )
    }
}

struct BabyDiaryWidgetView: View {
    let entry: BabyDiaryEntry

    var hasPhoto: Bool { entry.photoData != nil }

    var body: some View {
        ZStack {
            if let data = entry.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                WDS.bgBase
            }

            VStack(spacing: 4) {
                Spacer()

                Text("D+\(entry.dayCount)")
                    .font(WDS.font(28))
                    .foregroundColor(hasPhoto ? .white : WDS.fgStrong)
                    .shadow(color: hasPhoto ? .black.opacity(0.5) : .clear, radius: 2)

                if !entry.monthAndDays.isEmpty {
                    Text(entry.monthAndDays)
                        .font(WDS.font(12))
                        .foregroundColor(hasPhoto ? .white.opacity(0.9) : WDS.fgNeutral)
                        .shadow(color: hasPhoto ? .black.opacity(0.5) : .clear, radius: 1)
                }

                if !entry.babyName.isEmpty {
                    Text(entry.babyName)
                        .font(WDS.font(11))
                        .foregroundColor(hasPhoto ? .white.opacity(0.8) : WDS.fgPale)
                        .shadow(color: hasPhoto ? .black.opacity(0.5) : .clear, radius: 1)
                }

                Spacer().frame(height: 12)
            }
        }
    }
}

@main
struct BabyDiaryWidgetBundle: Widget {
    let kind = "BabyDiaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BabyDiaryProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                BabyDiaryWidgetView(entry: entry)
                    .padding(-16)
                    .containerBackground(.clear, for: .widget)
            } else {
                BabyDiaryWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Trunky Diary")
        .description("아기의 D+ 일수를 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}

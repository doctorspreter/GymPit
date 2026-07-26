import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct GymPitLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLiveActivityView(state: context.state)
                .containerBackground(.clear, for: .widget)
                .activityBackgroundTint(Color.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(context.state.setDetailText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    RestText(state: context.state)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center, spacing: 8) {
                        LiveStatusText(state: context.state)
                        Spacer(minLength: 6)
                        if !context.state.exerciseIDString.isEmpty {
                            WorkoutLiveActivityButton(state: context.state, compact: true)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
            } compactTrailing: {
                CompactRestText(state: context.state)
            } minimal: {
                Image(systemName: "checkmark.circle.fill")
            }
            .widgetURL(URL(string: "gympit://training"))
        }
    }
}

private struct WorkoutLiveActivityView: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.blue)
                            .frame(width: 20, height: 20)
                            .background(.blue.opacity(0.16), in: RoundedRectangle(cornerRadius: 6))

                        Text(state.routineName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Text(state.exerciseName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                        HStack(spacing: 8) {
                            Text(state.progressText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 4)

                            LiveElapsedText(state: state, label: "Gesamtzeit", font: .caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                    }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)
                RestText(state: state)
            }

            HStack(alignment: .center, spacing: 10) {
                LiveStatusText(state: state)
                Spacer(minLength: 8)
                if !state.exerciseIDString.isEmpty {
                    WorkoutLiveActivityButton(state: state, compact: true)
                }
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
    }
}

private struct WorkoutLiveActivityButton: View {
    let state: WorkoutActivityAttributes.ContentState
    var compact: Bool = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if isResting(at: timeline.date) {
                Button(intent: SkipWorkoutRestIntent(exerciseIDString: state.exerciseIDString)) {
                    buttonLabel(compact ? "Skip" : "Pause überspringen", systemImage: "forward.fill", tint: .orange)
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: CompleteNextWorkoutSetIntent(exerciseIDString: state.exerciseIDString)) {
                    buttonLabel(compact ? "Satz" : "Satz erledigt", systemImage: "checkmark", tint: .blue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func isResting(at date: Date) -> Bool {
        guard let restEndDate = state.restEndDate else { return false }
        return restEndDate > date
    }

    private func buttonLabel(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: compact ? 5 : 8) {
            Image(systemName: systemImage)
                .font((compact ? Font.caption : Font.subheadline).weight(.bold))
                .frame(width: compact ? 13 : 18)
            Text(title)
                .font((compact ? Font.caption : Font.subheadline).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .frame(minWidth: compact ? 82 : 0)
        .frame(maxWidth: compact ? nil : .infinity)
        .frame(height: compact ? 28 : 38)
        .padding(.horizontal, compact ? 7 : 14)
        .background(tint, in: RoundedRectangle(cornerRadius: compact ? 14 : 19))
    }
}

private struct LiveElapsedText: View {
    let state: WorkoutActivityAttributes.ContentState
    let label: String
    let font: Font

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
            if let startedAt = state.workoutStartedAt {
                Text(startedAt, style: .timer)
                    .monospacedDigit()
            } else {
                Text(state.elapsedText)
                    .monospacedDigit()
            }
        }
        .font(font)
    }
}

private struct RestText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if let restEndDate = state.restEndDate, restEndDate > timeline.date {
                Text(timerInterval: timeline.date...restEndDate, countsDown: true)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.16), in: Capsule())
            } else {
                Text("Bereit")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.16), in: Capsule())
            }
        }
    }
}

private struct CompactRestText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            if let restEndDate = state.restEndDate, restEndDate > timeline.date {
                Text(timerInterval: timeline.date...restEndDate, countsDown: true)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.orange)
            } else {
                Text("Set")
                    .font(.caption2.weight(.bold))
            }
        }
    }
}

private struct LiveStatusText: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(alignment: .leading, spacing: 2) {
                if let restEndDate = state.restEndDate, restEndDate > timeline.date {
                    Text("Pause")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("Nächster \(state.setText)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(state.setDetailText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Bereit")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Text(state.setText)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(state.setDetailText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

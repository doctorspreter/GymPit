# Release artifacts

This directory stores local build output. Its contents are excluded by
`.gitignore`: archives (`*.xcarchive`), the App Store export and `GymPit.ipa`,
and embedded provisioning profiles remain on the machine that created them.

See `Docs/Release.md` for archive and App Store Connect instructions.

Release builds include only the 68 original exercise illustrations from
`Sources/GymPit/ExerciseDetailImages`.
